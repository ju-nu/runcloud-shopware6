#!/bin/bash
# TODO: ES INDEXING AND ES ADMIN INDEXING
# Exit immediately if a command exits with a non-zero status, and treat unset variables as an error.
set -euo pipefail

# Set umask to ensure files are created with appropriate permissions
umask 022

# Export LC_ALL to ensure consistent locale settings
export LC_ALL=C

# ===============================
# Global Variables and Constants
# ===============================

PHP_VERSION="8.3"
PHP_BIN="/usr/bin/php"  # Removed the PHP version as per your request
PHP_FPM_SERVICE="php${PHP_VERSION//./}rc-fpm"
PHP_CONF_DIR="/etc/php-extra"  # Updated as per your request
NGINX_CONF_DIR="/etc/nginx-rc/extra.d"
ELASTICSEARCH_VERSION="8.9.0"

# Log file for the script
LOG_FILE="/var/log/shopware_install.log"

# Initialize temporary files array for cleanup
TEMP_FILES=()

# Redirect output to log file with timestamps
exec > >(while IFS= read -r line; do echo "$(date '+%Y-%m-%d %H:%M:%S') - $line"; done | tee -a "$LOG_FILE") 2>&1

# ===============================
# Function Definitions
# ===============================

# Function to display usage information
usage() {
    cat <<EOF
Usage: $0 -u USERNAME -w WEBAPP -a APP_URL -m MYSQL_USER -p MYSQL_PASSWORD -d MYSQL_DATABASE -n SHOP_NAME -e SHOP_EMAIL -l SHOP_LOCALE -c SHOP_CURRENCY -U ADMIN_USERNAME -P ADMIN_PASSWORD -F ADMIN_FIRSTNAME -L ADMIN_LASTNAME -E ADMIN_EMAIL [-s SHOPWARE_VERSION]

Options:
  -u USERNAME           System username under which Shopware will be installed.
  -w WEBAPP             Web application name or directory.
  -a APP_URL            URL where your Shopware application will be accessible.
  -m MYSQL_USER         MySQL username for the Shopware database.
  -p MYSQL_PASSWORD     Password for the MySQL user.
  -d MYSQL_DATABASE     Name of the MySQL database for Shopware.
  -n SHOP_NAME          Name of the Shop.
  -e SHOP_EMAIL         Email address of the Shop.
  -l SHOP_LOCALE        Locale for the Shop (e.g., de-DE).
  -c SHOP_CURRENCY      Currency for the Shop (e.g., EUR).
  -U ADMIN_USERNAME     Admin username to create.
  -P ADMIN_PASSWORD     Admin password.
  -F ADMIN_FIRSTNAME    Admin first name.
  -L ADMIN_LASTNAME     Admin last name.
  -E ADMIN_EMAIL        Admin email address.
  -s SHOPWARE_VERSION   (Optional) Shopware version to install (default: 6.6.7.0).
  -h                    Display this help message.

Example:
  $0 -u runcloud_user -w shopware_app -a https://shop.example.com -m shopware_user -p 'strongpassword123' -d shopware_db -n "Ihr Shopname" -e "shop@ihredomain.de" -l "de-DE" -c "EUR" -U "username" -P "djcrack12" -F "Hans" -L "Wurst" -E "hans@wurst.de"

**Warning**: Passing the MySQL password via command-line arguments can be insecure. Ensure your system is secured or consider alternative methods.
EOF
    exit 1
}

# Function to parse command-line arguments
parse_args() {
    # Default Shopware version
    SHOPWARE_VERSION="6.6.9.0"

    # Parse options
    while getopts "u:w:a:m:p:d:n:e:l:c:U:P:F:L:E:s:h" opt; do
        case $opt in
            u) USERNAME="$OPTARG" ;;
            w) WEBAPP="$OPTARG" ;;
            a) APP_URL="$OPTARG" ;;
            m) MYSQL_USER="$OPTARG" ;;
            p) MYSQL_PASSWORD="$OPTARG" ;;
            d) MYSQL_DATABASE="$OPTARG" ;;
            n) SHOP_NAME="$OPTARG" ;;
            e) SHOP_EMAIL="$OPTARG" ;;
            l) SHOP_LOCALE="$OPTARG" ;;
            c) SHOP_CURRENCY="$OPTARG" ;;
            U) ADMIN_USERNAME="$OPTARG" ;;
            P) ADMIN_PASSWORD="$OPTARG" ;;
            F) ADMIN_FIRSTNAME="$OPTARG" ;;
            L) ADMIN_LASTNAME="$OPTARG" ;;
            E) ADMIN_EMAIL="$OPTARG" ;;
            s) SHOPWARE_VERSION="$OPTARG" ;;
            h) usage ;;
            *) usage ;;
        esac
    done

    # Validate required arguments
    if [ -z "${USERNAME:-}" ] || [ -z "${WEBAPP:-}" ] || [ -z "${APP_URL:-}" ] || \
       [ -z "${MYSQL_USER:-}" ] || [ -z "${MYSQL_PASSWORD:-}" ] || [ -z "${MYSQL_DATABASE:-}" ] || \
       [ -z "${SHOP_NAME:-}" ] || [ -z "${SHOP_EMAIL:-}" ] || [ -z "${SHOP_LOCALE:-}" ] || \
       [ -z "${SHOP_CURRENCY:-}" ] || [ -z "${ADMIN_USERNAME:-}" ] || [ -z "${ADMIN_PASSWORD:-}" ] || \
       [ -z "${ADMIN_FIRSTNAME:-}" ] || [ -z "${ADMIN_LASTNAME:-}" ] || [ -z "${ADMIN_EMAIL:-}" ]; then
        echo "Error: Missing required arguments."
        usage
    fi

    # Validate APP_URL format
    if ! [[ "$APP_URL" =~ ^https?://[a-zA-Z0-9./_-]+$ ]]; then
        echo "Error: Invalid APP_URL format."
        exit 1
    fi
}

# Function to check operating system and version
check_os() {
    echo "Checking Operating System..."

    if ! command -v lsb_release &>/dev/null; then
        echo "Error: lsb_release command not found. Please install it and rerun the script."
        exit 1
    fi

    OS=$(lsb_release -si)
    VERSION=$(lsb_release -sr)

    REQUIRED_OS="Ubuntu"
    MIN_REQUIRED_VERSION="22.04"

    if [ "$OS" != "$REQUIRED_OS" ]; then
        echo "Error: This script requires $REQUIRED_OS. Detected OS: $OS."
        exit 1
    fi

    if dpkg --compare-versions "$VERSION" lt "$MIN_REQUIRED_VERSION"; then
        echo "Error: This script requires Ubuntu version $MIN_REQUIRED_VERSION or newer. Detected version: $VERSION."
        exit 1
    fi

    echo "Operating System and version verified: $OS $VERSION"
}

# Function to check RunCloud management and PHP-FPM service
check_runcloud() {
    echo "Verifying RunCloud management..."

    if systemctl is-active --quiet runcloud-agent; then
        echo "RunCloud agent service is active."
    else
        echo "Error: RunCloud agent service is not active. RunCloud does not seem to be managing this server."
        exit 1
    fi

    # Check if PHP-FPM service is running
    if ! systemctl is-active --quiet "$PHP_FPM_SERVICE"; then
        echo "Error: PHP-FPM service $PHP_FPM_SERVICE is not running."
        exit 1
    fi

    echo "RunCloud management and PHP-FPM service verified."
}

# Function to verify that required commands are available
check_commands() {
    echo "Checking required commands..."

    REQUIRED_COMMANDS=("wget" "curl" "composer" "$PHP_BIN" "mysql" "tar" "unzip" "uuidgen")

    for cmd in "${REQUIRED_COMMANDS[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            echo "Error: Required command $cmd is not available."
            exit 1
        fi
    done

    echo "All required commands are available."
}

# Function to check user and webapp existence
check_user_and_webapp() {
    echo "Checking if user and webapp exist..."

    # Check if USERNAME exists
    if ! id -u "$USERNAME" &>/dev/null; then
        echo "Error: User $USERNAME does not exist."
        exit 1
    fi

    # Check if WEBAPP directory exists
    if [ ! -d "/home/$USERNAME/webapps/$WEBAPP" ]; then
        echo "Error: Web application directory /home/$USERNAME/webapps/$WEBAPP does not exist."
        exit 1
    fi

    echo "User and webapp verified."
}

# Function to install required dependencies
install_dependencies() {
    echo "Installing dependencies..."

    # List of required packages
    REQUIRED_PACKAGES=(
        curl
        wget
        git
        unzip
        software-properties-common
        apt-transport-https
        ca-certificates
        gnupg
        openssl
        uuid-runtime
    )

    # Update package list and install required packages
    sudo apt-get update
    sudo apt-get install -y "${REQUIRED_PACKAGES[@]}"

    # Check PHP installation
    if ! command -v "$PHP_BIN" &>/dev/null; then
        echo "Error: PHP is not installed."
        exit 1
    fi

    PHP_VERSION_INSTALLED="$("$PHP_BIN" -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')"
    REQUIRED_PHP_VERSION="$PHP_VERSION"

    if dpkg --compare-versions "$PHP_VERSION_INSTALLED" lt "$REQUIRED_PHP_VERSION"; then
        echo "Error: PHP $REQUIRED_PHP_VERSION or newer is required. Detected version: $PHP_VERSION_INSTALLED."
        exit 1
    fi

    echo "PHP $PHP_VERSION_INSTALLED is installed."

    # Check Composer installation
    if ! command -v composer &>/dev/null; then
        echo "Error: Composer is not installed."
        exit 1
    fi

    echo "Composer is installed."

    # Check if Elasticsearch is installed
    if ! dpkg -l | grep -qw elasticsearch; then
        echo "Elasticsearch not found. Installing..."
        install_elasticsearch
    else
        echo "Elasticsearch is already installed."
    fi

    echo "All dependencies are installed."
}

# Function to generate a 32-character hex secret
generate_hex_secret() {
    openssl rand -hex 16
}

# Function to generate a UUID
generate_uuid_secret() {
    uuidgen
}

# Function to install Elasticsearch
install_elasticsearch() {
    echo "Installing Elasticsearch..."

    DEB_FILE="elasticsearch-${ELASTICSEARCH_VERSION}-amd64.deb"
    DOWNLOAD_URL="https://artifacts.elastic.co/downloads/elasticsearch/${DEB_FILE}"
    TEMP_DEB="/tmp/${DEB_FILE}"

    # Download Elasticsearch package
    if ! wget -q -O "$TEMP_DEB" "$DOWNLOAD_URL"; then
        echo "Error: Failed to download Elasticsearch from $DOWNLOAD_URL. Please check your network connection and the URL."
        exit 1
    fi
    TEMP_FILES+=("$TEMP_DEB")

    # Install Elasticsearch package
    if ! sudo dpkg -i "$TEMP_DEB"; then
        echo "Elasticsearch installation encountered issues. Attempting to fix dependencies..."
        sudo apt-get install -f -y
        if ! sudo dpkg -i "$TEMP_DEB"; then
            echo "Error: Failed to install Elasticsearch after fixing dependencies."
            exit 1
        fi
    fi

    # Enable and start Elasticsearch service
    sudo systemctl enable elasticsearch
    sudo systemctl start elasticsearch

    echo "Elasticsearch installed and started."
}

# Function to overwrite Elasticsearch configuration
override_elasticsearch_config() {
    echo "Overwriting Elasticsearch configuration..."

    local url="https://raw.githubusercontent.com/ju-nu/runcloud-shopware6/main/root/etc/elasticsearch/elasticsearch.yml"
    local dest_file="/etc/elasticsearch/elasticsearch.yml"

    # Backup existing configuration
    if [ -f "$dest_file" ]; then
        sudo cp "$dest_file" "${dest_file}.bak_$(date +%s)"
        echo "Backup of existing Elasticsearch configuration created."
    fi

    # Overwrite configuration
    if ! sudo curl -fsSL "$url" -o "$dest_file"; then
        echo "Error: Failed to download Elasticsearch configuration from $url"
        exit 1
    fi

    echo "Elasticsearch configuration overwritten."
}

# Function to append configurations to system files
append_configurations() {
    echo "Appending configurations..."

    # Append MySQL configuration
    local mysql_conf_url="https://raw.githubusercontent.com/ju-nu/runcloud-shopware6/main/root/etc/mysql/conf.d/shopware.cnf"
    local mysql_conf_dest="/etc/mysql/conf.d/${USERNAME}.cnf"
    append_raw_content "$mysql_conf_url" "$mysql_conf_dest" "append"

    # Append PHP configuration
    local php_conf_url="https://raw.githubusercontent.com/ju-nu/runcloud-shopware6/main/root/etc/php-extra/shopware.conf"
    local php_conf_dest="${PHP_CONF_DIR}/${WEBAPP}.conf"
    append_raw_content "$php_conf_url" "$php_conf_dest" "append"

    # Restart PHP-FPM service
    sudo systemctl restart "$PHP_FPM_SERVICE"
    echo "PHP-FPM service restarted."

    # Overwrite Nginx configurations
    local nginx_backend_url="https://raw.githubusercontent.com/ju-nu/runcloud-shopware6/main/runcloud/etc/nginx-rc/extra.d/backend.location.main-before.shopware.conf"
    local nginx_backend_dest="${NGINX_CONF_DIR}/${WEBAPP}.location.main-before.shopware.conf"
    append_raw_content "$nginx_backend_url" "$nginx_backend_dest" "overwrite"

    local nginx_static_url="https://raw.githubusercontent.com/ju-nu/runcloud-shopware6/main/runcloud/etc/nginx-rc/extra.d/backend.location.static.shopware.conf"
    local nginx_static_dest="${NGINX_CONF_DIR}/${WEBAPP}.location.static.shopware.conf"
    append_raw_content "$nginx_static_url" "$nginx_static_dest" "overwrite"

    echo "Configurations appended."
}

# Function to append or overwrite content from a URL to a file
append_raw_content() {
    local url="$1"
    local dest_file="$2"
    local mode="$3"

    # Create directory if it doesn't exist
    sudo mkdir -p "$(dirname "$dest_file")"

    # Backup existing file
    if [ -f "$dest_file" ]; then
        sudo cp "$dest_file" "${dest_file}.bak_$(date +%s)"
        echo "Backup of $dest_file created."
    fi

    # Append or overwrite content
    if [ "$mode" == "append" ]; then
        if ! sudo curl -fsSL "$url" | sudo tee -a "$dest_file" >/dev/null; then
            echo "Error: Failed to append content from $url to $dest_file"
            exit 1
        fi
    else
        if ! sudo curl -fsSL "$url" -o "$dest_file"; then
            echo "Error: Failed to overwrite $dest_file with content from $url"
            exit 1
        fi
    fi
}

# Function to restart services
restart_services() {
    echo "Restarting services..."

    local services=("redis-server" "elasticsearch" "nginx-rc" "$PHP_FPM_SERVICE")

    for service in "${services[@]}"; do
        if systemctl is-enabled --quiet "$service"; then
            sudo systemctl restart "$service"
            echo "Service $service restarted."
        else
            echo "Service $service is not enabled; skipping."
        fi
    done
}

# Function to execute raw SQL script
execute_sql() {
    local sql_url="$1"
    local db_user="$2"
    local db_pass="$3"
    local db_name="$4"

    echo "Executing SQL script from $sql_url..."

    local tmp_sql
    tmp_sql=$(mktemp)
    TEMP_FILES+=("$tmp_sql")

    if ! wget -qO "$tmp_sql" "$sql_url"; then
        echo "Error: Failed to download SQL script from $sql_url"
        exit 1
    fi

    if ! mysql -u "$db_user" -p"$db_pass" "$db_name" < "$tmp_sql"; then
        echo "Error: Failed to execute SQL script on database $db_name"
        exit 1
    fi

    echo "SQL script executed successfully."
}

# Function to install Shopware
install_shopware() {
    echo "Installing Shopware..."

    sudo -u "$USERNAME" bash <<EOF
cd ~/webapps/$WEBAPP/
rm -rf .[!.]* *
composer create-project shopware/production:"$SHOPWARE_VERSION" . --no-interaction
composer require symfony/redis-messenger
EOF

    echo "Shopware installed."
}

# Function to overwrite Shopware configuration files
overwrite_shopware_configs() {
    echo "Overwriting Shopware configuration files..."

    local shopware_dir="/home/$USERNAME/webapps/$WEBAPP"

    declare -A configs=(
        ["https://raw.githubusercontent.com/ju-nu/runcloud-shopware6/main/shopware/config/packages/shopware.yaml"]="$shopware_dir/config/packages/shopware.yaml"
        ["https://raw.githubusercontent.com/ju-nu/runcloud-shopware6/main/shopware/config/packages/session.yaml"]="$shopware_dir/config/packages/session.yaml"
        ["https://raw.githubusercontent.com/ju-nu/runcloud-shopware6/main/shopware/config/packages/messenger.yaml"]="$shopware_dir/config/packages/messenger.yaml"
        ["https://raw.githubusercontent.com/ju-nu/runcloud-shopware6/main/shopware/config/packages/framework.yaml"]="$shopware_dir/config/packages/framework.yaml"
        ["https://raw.githubusercontent.com/ju-nu/runcloud-shopware6/main/shopware/config/packages/elasticsearch.yml"]="$shopware_dir/config/packages/elasticsearch.yaml"
        ["https://raw.githubusercontent.com/ju-nu/runcloud-shopware6/main/shopware/config/packages/prod/shopware.yaml"]="$shopware_dir/config/packages/prod/shopware.yaml"
        ["https://raw.githubusercontent.com/ju-nu/runcloud-shopware6/main/shopware/config/packages/prod/monolog.yaml"]="$shopware_dir/config/packages/prod/monolog.yaml"
        ["https://raw.githubusercontent.com/ju-nu/runcloud-shopware6/main/shopware/config/packages/prod/framework.yaml"]="$shopware_dir/config/packages/prod/framework.yaml"
    )

    for url in "${!configs[@]}"; do
        local dest_file="${configs[$url]}"
        local dest_dir
        dest_dir=$(dirname "$dest_file")

        # Create directory if it doesn't exist
        sudo -u "$USERNAME" mkdir -p "$dest_dir"

        # Backup existing file
        if [ -f "$dest_file" ]; then
            sudo -u "$USERNAME" cp "$dest_file" "${dest_file}.bak_$(date +%s)"
            echo "Backup of $dest_file created."
        fi

        # Overwrite file
        if ! sudo -u "$USERNAME" curl -fsSL "$url" -o "$dest_file"; then
            echo "Error: Failed to overwrite $dest_file with content from $url"
            exit 1
        fi

        echo "Overwritten $dest_file with content from $url"
    done
}

# Function to create .env.local file
create_env_local() {
    echo "Creating .env.local file..."

    local env_file="/home/$USERNAME/webapps/$WEBAPP/.env.local"

    # Generate secrets
    local APP_SECRET
    APP_SECRET=$(generate_hex_secret)
    local SHOPWARE_CACHE_ID
    SHOPWARE_CACHE_ID=$(generate_hex_secret)
    local INSTANCE_ID
    INSTANCE_ID=$(generate_uuid_secret)

    cat <<EOF | sudo -u "$USERNAME" tee "$env_file" >/dev/null
APP_SECRET=$APP_SECRET
APP_URL=$APP_URL
APP_ENV=prod
DATABASE_URL=mysql://$MYSQL_USER:$MYSQL_PASSWORD@localhost:3306/$MYSQL_DATABASE
COMPOSER_HOME=/home/$USERNAME/webapps/$WEBAPP/var/cache/composer
INSTANCE_ID=$INSTANCE_ID
BLUE_GREEN_DEPLOYMENT=1
ADMIN_OPENSEARCH_URL="http://127.0.0.1:9200"
REDIS_HOST=127.0.0.1
REDIS_PORT=6379
# Redis Database Assignments
REDIS_DB_APP_CACHE=0
REDIS_DB_HTTP_CACHE=1
REDIS_DB_STORAGE=2
REDIS_DB_SESSION=3
REDIS_DB_NUMBER_RANGE=4
REDIS_DB_MESSENGER=5
REDIS_DB_ASYNC=6
REDIS_DB_FAILED=7
REDIS_DB_LOW_PRIORITY=8
# Shopware Configuration
SQL_SET_DEFAULT_SESSION_VARIABLES=0
SHOPWARE_CACHE_ID=$SHOPWARE_CACHE_ID
OPENSEARCH_URL="http://127.0.0.1:9200"
SHOPWARE_ES_ENABLED="1"
SHOPWARE_ES_INDEXING_ENABLED="1"
SHOPWARE_ES_INDEX_PREFIX="sw"
SHOPWARE_ES_THROW_EXCEPTION=1
SHOPWARE_ES_INDEX_SETTINGS='{"number_of_shards": 1, "number_of_replicas": 0}'
EOF

    echo ".env.local file created."
}

# Function to install Shopware via CLI
install_shopware_cli() {
    echo "Installing Shopware via CLI..."

    sudo -u "$USERNAME" bash <<EOF
cd ~/webapps/$WEBAPP/
bin/console system:install \\
    --create-database \\
    --shop-name="$SHOP_NAME" \\
    --shop-email="$SHOP_EMAIL" \\
    --shop-locale="$SHOP_LOCALE" \\
    --shop-currency="$SHOP_CURRENCY" \\
    --no-interaction
EOF

    echo "Shopware CLI installation completed."
}

# Function to create admin user
create_admin_user() {
    echo "Creating admin user..."

    sudo -u "$USERNAME" bash <<EOF
cd ~/webapps/$WEBAPP/
bin/console user:create --admin \\
    --password "$ADMIN_PASSWORD" \\
    --firstName "$ADMIN_FIRSTNAME" \\
    --lastName "$ADMIN_LASTNAME" \\
    --email "$ADMIN_EMAIL" \\
    "$ADMIN_USERNAME"
EOF

    echo "Admin user created."
}

# Function to clear Shopware cache
clear_shopware_cache() {
    echo "Clearing Shopware cache..."

    sudo -u "$USERNAME" bash <<EOF
cd ~/webapps/$WEBAPP/
bin/console cache:clear
EOF

    echo "Shopware cache cleared."
}

# Function to perform final setup steps
final_setup() {
    echo "Starting final setup..."

    # Start Elasticsearch if not running
    if ! sudo systemctl is-active --quiet elasticsearch; then
        sudo systemctl start elasticsearch
    fi

    # Restart necessary services
    restart_services

    # Install Shopware and configurations
    install_shopware
    create_env_local
    overwrite_shopware_configs
    install_shopware_cli
    create_admin_user
    clear_shopware_cache

    echo "Shopware installation and configuration completed successfully."
}

# Function to clean up temporary files
cleanup() {
    echo "Performing cleanup..."

    for temp_file in "${TEMP_FILES[@]}"; do
        if [ -f "$temp_file" ]; then
            rm -f "$temp_file"
            echo "Removed temporary file $temp_file"
        fi
    done

    echo "Cleanup completed."
}

# Trap EXIT signal to perform cleanup
trap cleanup EXIT

# ===============================
# Main Execution Flow
# ===============================

main() {
    parse_args "$@"
    check_os
    check_runcloud
    check_commands
    check_user_and_webapp
    install_dependencies
    append_configurations
    override_elasticsearch_config
    execute_sql "https://raw.githubusercontent.com/ju-nu/runcloud-shopware6/main/shopware/elasticsearch.sql" "$MYSQL_USER" "$MYSQL_PASSWORD" "$MYSQL_DATABASE"
    final_setup
}

# Execute the main function
main "$@"
