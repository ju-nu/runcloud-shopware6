Shopware 6 Production Environment on runcloud
These steps are neccessary to have a fully running system.

0 Configure a new webapp with nginx native
1 Change the PHP CLI to 8.3 by...
2 Change the working directory to /public
3 Add SSL
4 Append mysql and php configs to files by ssh from our repo
5 Disabled Redis pass in Runcloud
6 Restart services
7 Installed elastic and added config
    cd /tmp 
    wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-8.15.1-amd64.deb
    sudo dpkg -i elasticsearch-8.15.1-amd64.deb
    sudo apt-get install -f
    sudo systemctl enable elasticsearch
    sudo systemctl start elasticsearch
    sudo systemctl status elasticsearch
    ##config
    sudo systemctl restart elasticsearch
8 Create a Database in runcloud
 8.1) Create Database User -> Create Database with this user
 8.2) Database with collation: utf8mb4_unicode_ci
9 Install Shopware by CLI with these commands
    runcloud@nue01:~$ cd webapps/shopware/
    runcloud@nue01:~/webapps/shopware$ rm -rf * .*
    runcloud@nue01:~/webapps/shopware$ php /usr/sbin/composer create-project shopware/production .
10 Install Redis Messenger for Shopware
    runcloud@nue01:~/webapps/cyber$ composer require symfony/redis-messenger
11 Add the Shopware config files from our repo to Shopware
11 Restarted all services redis, elastic through runcloud
12 Check all running
13 Create Supervisor entries
    /RunCloud/Packages/php83rc/bin/php /home/runcloud/webapps/shopware/bin/console messenger:consume async low_priority scheduler_shopware --time-limit=600 --memory-limit=1024M --sleep=1
    /RunCloud/Packages/php83rc/bin/php /home/runcloud/webapps/shopware/bin/console messenger:consume default --time-limit=600 --memory-limit=1024M --sleep=1
    /RunCloud/Packages/php83rc/bin/php /home/runcloud/webapps/shopware/bin/console messenger:consume failed --time-limit=600 --memory-limit=1024M --sleep=1
    /RunCloud/Packages/php83rc/bin/php /home/runcloud/webapps/shopware/bin/console scheduled-task:run --time-limit=600 --memory-limit=512M

    Supervisor running directory: /home/runcloud/webapps/shopware
    Supervisor Additional Config:
    startsecs=1
    stopwaitsecs=10


Here are additional config params for that

FPM Config
Process Manager = Dynamic
pm.start_servers = 20
pm.min_spare_servers = 10
pm.max_spare_servers = 30
pm.max_children = 80
pm.max_requests = 500

PHP Settings:
disable_functions: 
getmyuid,passthru,leak,listen,diskfreespace,tmpfile,link,shell_exec,dl,exec,system,highlight_file,source,show_source,fpassthru,virtual,posix_ctermid,posix_getcwd,posix_getegid,posix_geteuid,posix_getgid,posix_getgrgid,posix_getgrnam,posix_getgroups,posix_getlogin,posix_getpgid,posix_getpgrp,posix_getpid,posix_getppid,posix_getpwuid,posix_getrlimit,posix_getsid,posix_getuid,posix_isatty,posix_kill,posix_mkfifo,posix_setegid,posix_seteuid,posix_setgid,posix_setpgid,posix_setsid,posix_setuid,posix_times,posix_ttyname,posix_uname,escapeshellcmd,ini_alter,popen,pcntl_exec,socket_accept,socket_bind,socket_clear_error,socket_close,socket_connect,symlink,posix_geteuid,ini_alter,socket_listen,socket_create_listen,socket_read,socket_create_pair,stream_socket_server


max_execution_time = 300
max_input_time = 300
max_input_vars = 10000
memory_limit = 1024
upload_max_filesize = 256
post_max_size = 256
session.gc_maxlifetime = 1440




