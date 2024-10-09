# Shopware 6 Produktionsumgebung auf RunCloud

Dieses Repository bietet Konfigurationsdateien und eine detaillierte Anleitung, um Shopware 6 in einer produktiven Umgebung auf RunCloud einzurichten. Die Konfiguration umfasst die Integration von Redis, Elasticsearch, optimierte PHP- und SQL-Einstellungen sowie die Einrichtung von Supervisor für die Verwaltung der Shopware-Worker.

## Inhaltsverzeichnis

- [Shopware 6 Produktionsumgebung auf RunCloud](#shopware-6-produktionsumgebung-auf-runcloud)
  - [Inhaltsverzeichnis](#inhaltsverzeichnis)
  - [Voraussetzungen](#voraussetzungen)
  - [Installationsschritte](#installationsschritte)
    - [1. Neue Web-App mit Nginx Native erstellen](#1-neue-web-app-mit-nginx-native-erstellen)
    - [2. PHP CLI auf Version 8.3 ändern](#2-php-cli-auf-version-83-ändern)
    - [3. Arbeitsverzeichnis auf `/public` setzen](#3-arbeitsverzeichnis-auf-public-setzen)
    - [4. SSL-Zertifikat hinzufügen](#4-ssl-zertifikat-hinzufügen)
    - [5. MySQL- und PHP-Konfigurationen hinzufügen](#5-mysql--und-php-konfigurationen-hinzufügen)
    - [6. Redis-Passwort deaktivieren](#6-redis-passwort-deaktivieren)
    - [7. Dienste neu starten](#7-dienste-neu-starten)
    - [8. Elasticsearch installieren und konfigurieren](#8-elasticsearch-installieren-und-konfigurieren)
    - [9. Datenbank in RunCloud erstellen](#9-datenbank-in-runcloud-erstellen)
    - [10. Shopware über die CLI installieren](#10-shopware-über-die-cli-installieren)
    - [11. Redis Messenger für Shopware installieren](#11-redis-messenger-für-shopware-installieren)
    - [12. Shopware-Konfigurationsdateien hinzufügen](#12-shopware-konfigurationsdateien-hinzufügen)
    - [13. Dienste erneut neu starten](#13-dienste-erneut-neu-starten)
    - [14. Supervisor-Einträge in RunCloud erstellen](#14-supervisor-einträge-in-runcloud-erstellen)
  - [Optimierung der PHP- und SQL-Einstellungen](#optimierung-der-php--und-sql-einstellungen)
    - [PHP-FPM-Konfiguration](#php-fpm-konfiguration)
    - [PHP-Einstellungen](#php-einstellungen)
  - [Supervisor-Konfiguration](#supervisor-konfiguration)
  - [Zusätzliche Hinweise](#zusätzliche-hinweise)
  - [Credits](#credits)

## Voraussetzungen

- Ein Server, der von RunCloud verwaltet wird
- Zugriff auf das RunCloud-Dashboard
- SSH-Zugriff auf den Server
- Grundkenntnisse in der Verwaltung von Linux-Servern
- Composer auf dem Server installiert

## Installationsschritte

### 1. Neue Web-App mit Nginx Native erstellen

- **Anmeldung im RunCloud-Dashboard:**
  - Melden Sie sich unter [runcloud.io](https://runcloud.io/) in Ihrem Dashboard an.

- **Erstellen der Web-App:**
  - Navigieren Sie zu **Web Applications** im linken Menü.
  - Klicken Sie auf **Create Web Application**.
  - Wählen Sie unter **Web Application Stack** die Option **Nginx Native** aus.
  - Füllen Sie die folgenden Felder aus:
    - **Domain Name:** Geben Sie den Domainnamen ein (z. B. `example.com`).
    - **Web Application Name:** Geben Sie einen Namen für die Anwendung ein (z. B. `shopware`).
  - Klicken Sie auf **Add Web Application**, um die Web-App zu erstellen.

### 2. PHP CLI auf Version 8.3 ändern

**Hinweis:** Die Änderung der PHP CLI Version erfolgt auf **Server-Ebene**, nicht auf Anwendungsebene.

- **Im RunCloud-Dashboard:**
  - Gehen Sie zu **Server Settings** im linken Menü.
  - Klicken Sie auf **PHP-CLI Version**.
  - Wählen Sie **PHP 8.3** aus der Dropdown-Liste aus.
  - Klicken Sie auf **Update PHP-CLI Version**, um die Änderung zu speichern.

**Warum ist das wichtig?**

- Die PHP CLI Version bestimmt, welche PHP-Version verwendet wird, wenn Sie PHP-Befehle über die Kommandozeile ausführen.
- Shopware 6 benötigt mindestens PHP 8.1; wir verwenden hier PHP 8.3 für optimale Leistung und Kompatibilität.

### 3. Arbeitsverzeichnis auf `/public` setzen

- **Im RunCloud-Dashboard:**
  - Navigieren Sie zu **Web Applications** und wählen Sie Ihre neu erstellte Web-App aus.
  - Gehen Sie zu **Settings** > **Web Application Settings**.
  - Unter **Web Application Root** setzen Sie das Arbeitsverzeichnis auf `/public`.
  - Klicken Sie auf **Update Web Application**, um die Änderung zu speichern.

**Warum `/public`?**

- Shopware 6 verwendet das `/public`-Verzeichnis als öffentlich zugänglichen Ordner. Alle Anfragen sollten auf dieses Verzeichnis verweisen, um Sicherheitsrisiken zu minimieren.

### 4. SSL-Zertifikat hinzufügen

- **Im RunCloud-Dashboard:**
  - Wählen Sie Ihre Web-App aus und navigieren Sie zu **SSL/TLS** im oberen Menü.
  - Klicken Sie auf **Install Free SSL Certificate**, um ein Let's Encrypt SSL-Zertifikat zu installieren.
  - Folgen Sie den Anweisungen:
    - Stellen Sie sicher, dass Ihre Domain auf die Server-IP verweist.
    - Akzeptieren Sie die Let's Encrypt Nutzungsbedingungen.
    - Klicken Sie auf **Install Free SSL Certificate**.
  - Warten Sie, bis die Installation abgeschlossen ist.

**Warum SSL?**

- Ein SSL-Zertifikat ermöglicht die verschlüsselte Kommunikation zwischen dem Server und dem Client, was für die Sicherheit Ihrer Shopware-Installation unerlässlich ist.

### 5. MySQL- und PHP-Konfigurationen hinzufügen

- Verbinden Sie sich per SSH mit Ihrem Server.

**Für die MySQL-Konfiguration:**

- Kopieren Sie die bereitgestellte MySQL-Konfigurationsdatei [shopware.cnf](https://github.com/ju-nu/runcloud-shopware6/blob/main/root/etc/mysql/conf.d/shopware.cnf) in das Verzeichnis `/etc/mysql/conf.d/`.
- Benennen Sie die Datei um, sodass sie dem Benutzernamen Ihrer Web-Applikation entspricht (z. B. `username.cnf`).

```bash
sudo cp shopware.cnf /etc/mysql/conf.d/username.cnf
sudo chown root:root /etc/mysql/conf.d/username.cnf
sudo chmod 644 /etc/mysql/conf.d/username.cnf
```

**Für die PHP-Konfiguration:**

- Kopieren Sie die bereitgestellte PHP-Konfigurationsdatei [shopware.conf](https://github.com/ju-nu/runcloud-shopware6/blob/main/root/etc/php-extra/shopware.conf) in das Verzeichnis `/etc/php/8.3/fpm/pool.d/`.

```bash
sudo cp shopware.conf /etc/php/8.3/fpm/pool.d/username.conf
sudo chown root:root /etc/php/8.3/fpm/pool.d/username.conf
sudo chmod 644 /etc/php/8.3/fpm/pool.d/username.conf
```

- Ersetzen Sie `username` durch den tatsächlichen Benutzernamen Ihrer Web-Applikation.

**Hinweis:**

- Kopieren Sie die Werte aus dem Abschnitt [Optimierung der PHP- und SQL-Einstellungen](#optimierung-der-php--und-sql-einstellungen) in die PHP-Einstellungen Ihrer Web-Applikation in RunCloud.

### 6. Redis-Passwort deaktivieren

- **Im RunCloud-Dashboard:**
  - Gehen Sie zu **Services** im linken Menü.
  - Wählen Sie **Redis** aus der Liste der Dienste.
  - Klicken Sie auf **Settings**.
  - Deaktivieren Sie die Option **Require Password**, um lokale Verbindungen ohne Authentifizierung zu ermöglichen.
  - Klicken Sie auf **Update Redis**, um die Änderung zu speichern.

**Warum das Passwort deaktivieren?**

- Da Redis lokal auf dem Server läuft und nicht von außen erreichbar ist, ist es sicher, das Passwort zu deaktivieren. Dies erleichtert die Konfiguration mit Shopware.

### 7. Dienste neu starten

- **Im RunCloud-Dashboard:**
  - Gehen Sie zu **Services**.
  - Starten Sie die folgenden Dienste neu:
    - **MySQL**: Klicken Sie auf **Restart** neben MySQL.
    - **Redis**: Klicken Sie auf **Restart** neben Redis.

- **Per SSH:**
  - Starten Sie PHP-FPM neu:

    ```bash
    sudo systemctl restart php8.3-fpm
    ```

**Warum Dienste neu starten?**

- Damit die neuen Konfigurationen übernommen werden, müssen die entsprechenden Dienste neu gestartet werden.

### 8. Elasticsearch installieren und konfigurieren

**Per SSH:**

- **Elasticsearch herunterladen und installieren:**

  ```bash
  cd /tmp
  wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-8.15.1-amd64.deb
  sudo dpkg -i elasticsearch-8.15.1-amd64.deb
  sudo apt-get install -f
  ```

- **Elasticsearch beim Systemstart aktivieren und starten:**

  ```bash
  sudo systemctl enable elasticsearch
  sudo systemctl start elasticsearch
  sudo systemctl status elasticsearch
  ```

- **Elasticsearch konfigurieren:**

  - Ersetzen Sie die Datei `/etc/elasticsearch/elasticsearch.yml` mit der [elasticsearch.yml](https://github.com/ju-nu/runcloud-shopware6/blob/main/root/etc/elasticsearch/elasticsearch.yml).

    ```bash
    sudo nano /etc/elasticsearch/elasticsearch.yml
    ```

- **Elasticsearch neu starten:**

  ```bash
  sudo systemctl restart elasticsearch
  ```

**Warum Elasticsearch?**

- Elasticsearch wird von Shopware für die Produkt- und Kategoriesuche sowie für verschiedene Indexierungsprozesse verwendet.

### 9. Datenbank in RunCloud erstellen

- **Im RunCloud-Dashboard:**
  - Gehen Sie zu **Database** im linken Menü.
  - Klicken Sie auf **Create Database User**:
    - **Username:** Geben Sie einen Benutzernamen ein.
    - **Password:** Generieren Sie ein sicheres Passwort.
    - Klicken Sie auf **Add Database User**.
  - Klicken Sie auf **Create Database**:
    - **Database Name:** Geben Sie einen Datenbanknamen ein.
    - **Database User:** Wählen Sie den zuvor erstellten Benutzer aus.
    - **Collation:** Wählen Sie `utf8mb4_unicode_ci` aus der Dropdown-Liste.
    - Klicken Sie auf **Add Database**.

**Warum diese Kollation?**

- `utf8mb4_unicode_ci` unterstützt vollständige UTF-8-Zeichen, einschließlich Emojis, und ist für Shopware erforderlich.

### 10. Shopware über die CLI installieren

**Per SSH:**

- **Zum Web-App-Verzeichnis navigieren:**

  ```bash
  cd ~/webapps/shopware/
  ```

- **Vorhandene Dateien entfernen:**

  ```bash
  rm -rf * .*
  ```

- **Shopware mit Composer installieren:**

  ```bash
  php /usr/bin/composer create-project shopware/production .
  ```

  **Hinweis:**

  - Wenn Composer nicht unter `/usr/bin/composer` verfügbar ist, verwenden Sie den Befehl `which composer`, um den richtigen Pfad zu finden.

- **Installationsprozess folgen:**

  - Während der Installation werden Sie möglicherweise nach Datenbankdetails und anderen Konfigurationen gefragt. Verwenden Sie die zuvor erstellten Datenbankinformationen.

### 11. Redis Messenger für Shopware installieren

**Per SSH im Web-App-Verzeichnis:**

```bash
composer require symfony/redis-messenger
```

**Warum?**

- Der Redis Messenger ermöglicht es Shopware, Redis für das Messaging und die Verarbeitung von Hintergrundaufgaben zu nutzen.

### 12. Shopware-Konfigurationsdateien hinzufügen

- **Konfigurationsdateien kopieren:**

  - Kopieren Sie die bereitgestellten [Konfigurationsdateien](https://github.com/ju-nu/runcloud-shopware6/blob/main/shopware) aus diesem Repository in Ihre Shopware-Installation.
  - Stellen Sie sicher, dass die Datei `.env.local` korrekt konfiguriert ist.

- **Wichtige Einstellungen in `.env.local`:**

  - **APP_URL:** Setzen Sie dies auf die URL Ihrer Shopware-Installation (z. B. `https://example.com`).
  - **SHOPWARE_CACHE_ID:** Setzen Sie eine einmalige Cache ID mit: openssl rand -hex 16
  - **Redis- und Elasticsearch-Einstellungen:** Passen Sie diese entsprechend Ihrer Installation an.

### 13. Dienste erneut neu starten

- **Per SSH:**

  ```bash
  sudo systemctl restart redis
  sudo systemctl restart elasticsearch
  sudo systemctl restart php8.3-fpm
  ```

**Warum erneut neu starten?**

- Nach der Installation und Konfiguration von Shopware und seinen Komponenten ist es wichtig, die Dienste neu zu starten, um sicherzustellen, dass alle Änderungen übernommen werden.

### 14. Supervisor-Einträge in RunCloud erstellen

**Hinweis:** In RunCloud können Sie Supervisor direkt über das Dashboard konfigurieren.

- **Im RunCloud-Dashboard:**
  - Gehen Sie zu **Process Manager** im linken Menü.
  - Wählen Sie **Supervisor** aus.
  - Klicken Sie auf **Create New Supervisor Job**.

- **Supervisor-Jobs erstellen:**

  - **Job 1: Shopware Async Worker**

    - **Name:** `shopware_async`
    - **Command:**

      ```bash
      /RunCloud/Packages/php83rc/bin/php /home/runcloud/webapps/shopware/bin/console messenger:consume async low_priority scheduler_shopware --time-limit=600 --memory-limit=1024M --sleep=1
      ```

    - **Directory:** `/home/runcloud/webapps/shopware`
    - **Autostart:** Aktivieren
    - **Autorestart:** Aktivieren
    - **Startsecs:** 1
    - **Stopwaitsecs:** 10
    - **Zusätzliche Einstellungen:**
      - **startsecs:** 1
      - **stopwaitsecs:** 10

  - **Job 2: Shopware Default Worker**

    - **Name:** `shopware_default`
    - **Command:**

      ```bash
      /RunCloud/Packages/php83rc/bin/php /home/runcloud/webapps/shopware/bin/console messenger:consume default --time-limit=600 --memory-limit=1024M --sleep=1
      ```

    - **Directory:** `/home/runcloud/webapps/shopware`
    - **Weitere Einstellungen wie oben**

  - **Job 3: Shopware Failed Worker**

    - **Name:** `shopware_failed`
    - **Command:**

      ```bash
      /RunCloud/Packages/php83rc/bin/php /home/runcloud/webapps/shopware/bin/console messenger:consume failed --time-limit=600 --memory-limit=1024M --sleep=1
      ```

    - **Directory:** `/home/runcloud/webapps/shopware`
    - **Weitere Einstellungen wie oben**

  - **Job 4: Shopware Scheduled Task**

    - **Name:** `shopware_scheduled_task`
    - **Command:**

      ```bash
      /RunCloud/Packages/php83rc/bin/php /home/runcloud/webapps/shopware/bin/console scheduled-task:run --time-limit=600 --memory-limit=512M
      ```

    - **Directory:** `/home/runcloud/webapps/shopware`
    - **Weitere Einstellungen wie oben**

- **Supervisor neu starten:**

  - Nach dem Hinzufügen aller Jobs klicken Sie auf **Restart Supervisor**, um die Änderungen zu übernehmen.

**Warum Supervisor?**

- Supervisor stellt sicher, dass die Hintergrundprozesse von Shopware kontinuierlich laufen und bei Bedarf automatisch neu gestartet werden.

## Optimierung der PHP- und SQL-Einstellungen

### PHP-FPM-Konfiguration

- **Im RunCloud-Dashboard:**
  - Gehen Sie zu **Web Applications** und wählen Sie Ihre Shopware-Web-App aus.
  - Navigieren Sie zu **Settings** > **PHP-FPM Settings**.

- **Einstellungen anpassen:**

  - **Process Manager:** Setzen Sie auf **Dynamic**.
  - **Parameter:**

    ```ini
    pm.start_servers = 20
    pm.min_spare_servers = 10
    pm.max_spare_servers = 30
    pm.max_children = 80
    pm.max_requests = 500
    ```

### PHP-Einstellungen

- **Im RunCloud-Dashboard:**
  - Unter **PHP Settings** können Sie die folgenden Einstellungen anpassen.

- **Disable Functions:**

  - Fügen Sie die Liste der zu deaktivierenden Funktionen hinzu, um die Sicherheit zu erhöhen.

    ```ini
    getmyuid,passthru,leak,listen,diskfreespace,tmpfile,link,shell_exec,dl,exec,system,highlight_file,source,show_source,fpassthru,virtual,posix_ctermid,posix_getcwd,posix_getegid,posix_geteuid,posix_getgid,posix_getgrgid,posix_getgrnam,posix_getgroups,posix_getlogin,posix_getpgid,posix_getpgrp,posix_getpid,posix_getppid,posix_getpwuid,posix_getrlimit,posix_getsid,posix_getuid,posix_isatty,posix_kill,posix_mkfifo,posix_setegid,posix_seteuid,posix_setgid,posix_setpgid,posix_setsid,posix_setuid,posix_times,posix_ttyname,posix_uname,escapeshellcmd,ini_alter,popen,pcntl_exec,socket_accept,socket_bind,socket_clear_error,socket_close,socket_connect,symlink,ini_alter,socket_listen,socket_create_listen,socket_read,socket_create_pair,stream_socket_server
    ```

- **Weitere Einstellungen:**

  ```ini
  max_execution_time = 300
  max_input_time = 300
  max_input_vars = 10000
  memory_limit = 1024M
  upload_max_filesize = 256M
  post_max_size = 256M
  session.gc_maxlifetime = 1440
  ```

**Warum diese Einstellungen?**

- Die Anpassung dieser Einstellungen optimiert die PHP-Leistung für Shopware und stellt sicher, dass größere Anfragen und Dateien verarbeitet werden können.

## Supervisor-Konfiguration

- **Arbeitsverzeichnis:** `/home/runcloud/webapps/shopware`
- **Zusätzliche Einstellungen:**

  - **startsecs:** 1
  - **stopwaitsecs:** 10

- **Hinweis:**

  - Supervisor sorgt dafür, dass die Shopware-Worker kontinuierlich laufen. Die Einstellungen `startsecs` und `stopwaitsecs` kontrollieren das Start- und Stop-Verhalten der Prozesse.

## Zusätzliche Hinweise

- **Sicherheit:**
  - Stellen Sie sicher, dass Ihr Server durch eine Firewall geschützt ist und dass Dienste wie Redis und Elasticsearch nicht von außen erreichbar sind.
  - Halten Sie Ihr System und alle Komponenten regelmäßig auf dem neuesten Stand.

- **Fehlerbehebung:**
  - Überprüfen Sie die Log-Dateien (z. B. `/var/log/nginx/`, `/var/log/php8.3-fpm.log`), wenn Probleme auftreten.
  - Stellen Sie sicher, dass alle Dienste laufen und korrekt konfiguriert sind.

- **Leistung:**
  - Passen Sie die Einstellungen für PHP-FPM und MySQL entsprechend den Ressourcen Ihres Servers an.
  - Verwenden Sie die Caching-Mechanismen von Shopware, um die Performance zu verbessern.

## Credits

Dieses Repository wird von der [JUNU Marketing Group LTD](https://ju.nu/) bereitgestellt. Alle Rechte vorbehalten.