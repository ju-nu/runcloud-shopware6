# Shopware 6 Produktionsumgebung auf RunCloud

Dieses Repository bietet Konfigurationsdateien und eine detaillierte Anleitung, um Shopware 6 in einer produktiven Umgebung auf RunCloud einzurichten. Die Konfiguration umfasst die Integration von Redis, Elasticsearch, optimierte PHP- und SQL-Einstellungen sowie die Einrichtung von Supervisor für die Verwaltung der Shopware-Worker.

## Inhaltsverzeichnis

- [Shopware 6 Produktionsumgebung auf RunCloud](#shopware-6-produktionsumgebung-auf-runcloud)
  - [Inhaltsverzeichnis](#inhaltsverzeichnis)
  - [Voraussetzungen](#voraussetzungen)
  - [Installationsschritte](#installationsschritte)
    - [1. Neue Web-App mit Nginx Native konfigurieren](#1-neue-web-app-mit-nginx-native-konfigurieren)
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
    - [14. Supervisor-Einträge erstellen](#14-supervisor-einträge-erstellen)
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

### 1. Neue Web-App mit Nginx Native konfigurieren

- Melden Sie sich im RunCloud-Dashboard an.
- Navigieren Sie zu **Web Applications** und klicken Sie auf **Create Web Application**.
- Wählen Sie **Nginx Native** als Web Application Stack.
- Füllen Sie die erforderlichen Details wie Domainname und Anwendungsname aus.
- Klicken Sie auf **Add Web Application**, um sie zu erstellen.

### 2. PHP CLI auf Version 8.3 ändern

**Hinweis:** Die Änderung der PHP CLI Version erfolgt auf Server-Ebene, nicht auf Anwendungsebene.

- Melden Sie sich im RunCloud-Dashboard an.
- Gehen Sie zu **Server Settings** > **PHP-CLI Version**.
- Wählen Sie **PHP 8.3** aus der Dropdown-Liste.
- Klicken Sie auf **Save Changes**, um die Einstellung zu speichern.

Alternativ können Sie die PHP CLI Version über SSH ändern:

```bash
sudo update-alternatives --set php /usr/bin/php8.3
```

### 3. Arbeitsverzeichnis auf `/public` setzen

- Im RunCloud-Dashboard navigieren Sie zu **Web Applications**.
- Wählen Sie Ihre neu erstellte Web-App aus.
- Gehen Sie zu **Settings**.
- Unter **Web Application Root** setzen Sie das Arbeitsverzeichnis auf `/public`.
- Speichern Sie die Änderungen.

### 4. SSL-Zertifikat hinzufügen

- Im RunCloud-Dashboard gehen Sie zu **Web Applications**.
- Wählen Sie Ihre Web-App aus.
- Navigieren Sie zu **SSL/TLS**.
- Klicken Sie auf **Install Free SSL Certificate**, um ein Let's Encrypt SSL-Zertifikat zu installieren.
- Folgen Sie den Anweisungen, um die SSL-Installation abzuschließen.

### 5. MySQL- und PHP-Konfigurationen hinzufügen

- Verbinden Sie sich per SSH mit Ihrem Server.

**Für die MySQL-Konfiguration:**

- Kopieren Sie die bereitgestellte MySQL-Konfigurationsdatei [shopware.cnf](https://github.com/ju-nu/runcloud-shopware6/blob/main/root/etc/mysql/conf.d/shopware.conf) in das Verzeichnis `/etc/mysql/conf.d/`.
- Die Datei muss in den Benutzernamen der Webapplikation geändert werden.

```bash
sudo cp username.cnf /etc/mysql/conf.d/
sudo chown root:root /etc/mysql/conf.d/username.cnf
sudo chmod 644 /etc/mysql/conf.d/username.cnf
```

**Für die PHP-Konfiguration:**

- Kopieren Sie die bereitgestellte PHP-Konfigurationsdatei (z. B. `username.conf`) in das Verzeichnis `/etc/php/8.3/fpm/pool.d/`.

```bash
sudo cp username.conf /etc/php/8.3/fpm/pool.d/
sudo chown root:root /etc/php/8.3/fpm/pool.d/username.conf
sudo chmod 644 /etc/php/8.3/fpm/pool.d/username.conf
```

### 6. Redis-Passwort deaktivieren

- Melden Sie sich im RunCloud-Dashboard an.
- Gehen Sie zu **Services** > **Redis**.
- Klicken Sie auf **Settings**.
- Deaktivieren Sie die Option **Require Password**, um lokale Verbindungen ohne Authentifizierung zu ermöglichen.
- Klicken Sie auf **Save Changes**.

### 7. Dienste neu starten

- Starten Sie die folgenden Dienste im RunCloud-Dashboard neu:

  - **Services** > **MySQL** > **Restart**
  - **Services** > **Redis** > **Restart**

- Starten Sie PHP-FPM über SSH neu:

```bash
sudo systemctl restart php8.3-fpm
```

### 8. Elasticsearch installieren und konfigurieren

- Verbinden Sie sich per SSH mit Ihrem Server.
- Installieren Sie Elasticsearch:

```bash
cd /tmp
wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-8.15.1-amd64.deb
sudo dpkg -i elasticsearch-8.15.1-amd64.deb
sudo apt-get install -f
```

- Elasticsearch beim Systemstart aktivieren und starten:

```bash
sudo systemctl enable elasticsearch
sudo systemctl start elasticsearch
sudo systemctl status elasticsearch
```

- Elasticsearch konfigurieren:

  - Bearbeiten Sie die Elasticsearch-Konfigurationsdatei:

    ```bash
    sudo nano /etc/elasticsearch/elasticsearch.yml
    ```

  - Fügen Sie folgende Einstellungen hinzu:

    ```yaml
    network.host: 127.0.0.1
    http.port: 9200
    xpack.security.enabled: false
    ```

- Elasticsearch neu starten:

```bash
sudo systemctl restart elasticsearch
```

### 9. Datenbank in RunCloud erstellen

- Im RunCloud-Dashboard gehen Sie zu **Database**.
- Klicken Sie auf **Create Database User**.
  - Geben Sie einen Benutzernamen und ein Passwort ein.
- Klicken Sie auf **Create Database**.
  - Geben Sie den Datenbanknamen ein.
  - Ordnen Sie den zuvor erstellten Benutzer dieser Datenbank zu.
  - Setzen Sie die Kollation auf `utf8mb4_unicode_ci`.
- Speichern Sie die Änderungen.

### 10. Shopware über die CLI installieren

- Verbinden Sie sich per SSH mit Ihrem Server.
- Navigieren Sie zum Verzeichnis Ihrer Web-App:

```bash
cd ~/webapps/your-webapp-name/
```

- Entfernen Sie vorhandene Dateien:

```bash
rm -rf * .*
```

- Shopware mit Composer installieren:

```bash
php /usr/bin/composer create-project shopware/production .
```

**Hinweis:** Falls Composer nicht unter `/usr/bin/composer` verfügbar ist, prüfen Sie den Installationspfad oder installieren Sie Composer neu.

### 11. Redis Messenger für Shopware installieren

- Im Verzeichnis Ihrer Web-App installieren Sie den Redis Messenger:

```bash
composer require symfony/redis-messenger
```

### 12. Shopware-Konfigurationsdateien hinzufügen

- Kopieren Sie die Konfigurationsdateien aus diesem Repository in Ihre Shopware-Installation.
- Stellen Sie sicher, dass die `.env.local` korrekt mit Ihren Umgebungsvariablen konfiguriert ist.

### 13. Dienste erneut neu starten

- Starten Sie Redis und Elasticsearch über das RunCloud-Dashboard oder per SSH neu:

```bash
sudo systemctl restart redis
sudo systemctl restart elasticsearch
```

### 14. Supervisor-Einträge erstellen

Supervisor wird verwendet, um die Hintergrundprozesse von Shopware zu verwalten.

- Supervisor installieren (falls noch nicht installiert):

```bash
sudo apt-get install supervisor
```

- Erstellen Sie die Supervisor-Konfigurationsdateien für jeden Worker-Prozess.

- Beispielkonfiguration (`/etc/supervisor/conf.d/shopware.conf`):

```ini
[program:shopware_async]
command=/RunCloud/Packages/php83rc/bin/php /home/runcloud/webapps/your-webapp-name/bin/console messenger:consume async low_priority scheduler_shopware --time-limit=600 --memory-limit=1024M --sleep=1
directory=/home/runcloud/webapps/your-webapp-name
autostart=true
autorestart=true
startsecs=1
stopwaitsecs=10

[program:shopware_default]
command=/RunCloud/Packages/php83rc/bin/php /home/runcloud/webapps/your-webapp-name/bin/console messenger:consume default --time-limit=600 --memory-limit=1024M --sleep=1
directory=/home/runcloud/webapps/your-webapp-name
autostart=true
autorestart=true
startsecs=1
stopwaitsecs=10

[program:shopware_failed]
command=/RunCloud/Packages/php83rc/bin/php /home/runcloud/webapps/your-webapp-name/bin/console messenger:consume failed --time-limit=600 --memory-limit=1024M --sleep=1
directory=/home/runcloud/webapps/your-webapp-name
autostart=true
autorestart=true
startsecs=1
stopwaitsecs=10

[program:shopware_scheduled_task]
command=/RunCloud/Packages/php83rc/bin/php /home/runcloud/webapps/your-webapp-name/bin/console scheduled-task:run --time-limit=600 --memory-limit=512M
directory=/home/runcloud/webapps/your-webapp-name
autostart=true
autorestart=true
startsecs=1
stopwaitsecs=10
```

- Ersetzen Sie `your-webapp-name` durch den tatsächlichen Namen Ihrer Web-App.

- Supervisor aktualisieren, um die Änderungen zu übernehmen:

```bash
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl status
```

## Optimierung der PHP- und SQL-Einstellungen

### PHP-FPM-Konfiguration

- Im RunCloud-Dashboard gehen Sie zu **Web Applications**.
- Wählen Sie Ihre Web-App aus und navigieren Sie zu **Settings** > **PHP-FPM**.
- Setzen Sie den **Process Manager** auf **Dynamic**.
- Konfigurieren Sie die folgenden Parameter:

  ```ini
  pm.start_servers = 20
  pm.min_spare_servers = 10
  pm.max_spare_servers = 30
  pm.max_children = 80
  pm.max_requests = 500
  ```

### PHP-Einstellungen

- Unter **PHP Settings** konfigurieren Sie die folgenden Einstellungen:

  - **Disable Functions**:

    ```ini
    getmyuid,passthru,leak,listen,diskfreespace,tmpfile,link,shell_exec,dl,exec,system,highlight_file,source,show_source,fpassthru,virtual,posix_ctermid,posix_getcwd,posix_getegid,posix_geteuid,posix_getgid,posix_getgrgid,posix_getgrnam,posix_getgroups,posix_getlogin,posix_getpgid,posix_getpgrp,posix_getpid,posix_getppid,posix_getpwuid,posix_getrlimit,posix_getsid,posix_getuid,posix_isatty,posix_kill,posix_mkfifo,posix_setegid,posix_seteuid,posix_setgid,posix_setpgid,posix_setsid,posix_setuid,posix_times,posix_ttyname,posix_uname,escapeshellcmd,ini_alter,popen,pcntl_exec,socket_accept,socket_bind,socket_clear_error,socket_close,socket_connect,symlink,posix_geteuid,ini_alter,socket_listen,socket_create_listen,socket_read,socket_create_pair,stream_socket_server
    ```

  - **Weitere Einstellungen**:

    ```ini
    max_execution_time = 300
    max_input_time = 300
    max_input_vars = 10000
    memory_limit = 1024M
    upload_max_filesize = 256M
    post_max_size = 256M
    session.gc_maxlifetime = 1440
    ```

## Supervisor-Konfiguration

- Stellen Sie sicher, dass Supervisor läuft und dass Ihre Shopware-Worker-Prozesse von Supervisor verwaltet werden.
- Die Parameter `startsecs` und `stopwaitsecs` in der Supervisor-Konfiguration sorgen dafür, dass die Prozesse schnell gestartet werden und genügend Zeit haben, um sauber zu beenden.

## Zusätzliche Hinweise

- **Elasticsearch-Probleme:** Wenn Sie Probleme mit Elasticsearch haben, insbesondere bei älteren Shopware-Versionen, müssen Sie möglicherweise die Replica-Einstellungen anpassen oder Index-Templates erstellen.

- **Sicherheit:** Da Elasticsearch und Redis lokal ohne Authentifizierung laufen, stellen Sie sicher, dass Ihr Server sicher konfiguriert ist und dass keine externen Zugriffe auf diese Dienste möglich sind.

- **Updates:** Halten Sie Ihren Server und alle installierten Pakete auf dem neuesten Stand, um Sicherheit und Leistung zu gewährleisten.

## Credits

Dieses Repository wird von der [JUNU Marketing Group LTD](https://ju.nu/) bereitgestellt. Alle Rechte vorbehalten.

---

Dieses README soll Anfängern helfen, eine robuste und skalierbare Shopware 6 Installation auf RunCloud einzurichten. Wenn Sie Fragen haben oder auf Probleme stoßen, können Sie gerne ein Issue in diesem Repository eröffnen oder uns direkt kontaktieren.

[GitHub Repository](https://github.com/ju-nu/runcloud-shopware6)

---

**Hinweis:** Diese Anleitung wurde sorgfältig erstellt, um alle notwendigen Schritte für die Einrichtung von Shopware 6 auf RunCloud abzudecken. Bitte folgen Sie den Anweisungen genau und prüfen Sie jede Konfiguration, um sicherzustellen, dass Ihre Installation erfolgreich ist.