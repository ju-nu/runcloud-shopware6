# Shopware 6 Produktionsumgebung auf RunCloud

Dieses Repository bietet eine Anleitung zur Einrichtung von Shopware 6 in einer produktiven Umgebung auf RunCloud. Mithilfe eines automatisierten Skripts werden zahlreiche Konfigurationsschritte übernommen, einschließlich der Integration von Redis, Elasticsearch und optimierter PHP- und SQL-Einstellungen.

## Inhaltsverzeichnis

- [Shopware 6 Produktionsumgebung auf RunCloud](#shopware-6-produktionsumgebung-auf-runcloud)
  - [Inhaltsverzeichnis](#inhaltsverzeichnis)
  - [Voraussetzungen](#voraussetzungen)
  - [Installationsschritte](#installationsschritte)
    - [1. Neue Web-App mit Nginx Native erstellen](#1-neue-web-app-mit-nginx-native-erstellen)
    - [2. PHP CLI auf Version 8.3 ändern](#2-php-cli-auf-version-83-ändern)
    - [3. Arbeitsverzeichnis auf `/public` setzen](#3-arbeitsverzeichnis-auf-public-setzen)
    - [4. SSL-Zertifikat hinzufügen](#4-ssl-zertifikat-hinzufügen)
    - [5. Redis-Passwort deaktivieren](#5-redis-passwort-deaktivieren)
    - [6. Datenbank in RunCloud erstellen](#6-datenbank-in-runcloud-erstellen)
    - [7. Skript ausführen](#7-skript-ausführen)
    - [8. PHP-Einstellungen in RunCloud anpassen](#8-php-einstellungen-in-runcloud-anpassen)
      - [PHP-FPM Einstellungen](#php-fpm-einstellungen)
      - [PHP-Einstellungen](#php-einstellungen)
    - [9. Supervisor-Einträge in RunCloud erstellen](#9-supervisor-einträge-in-runcloud-erstellen)
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
    - **Domain Name:** Geben Sie den Domainnamen ein (z. B. `example.com`).
    - **Web Application Name:** Geben Sie einen Namen für die Anwendung ein (z. B. `shopware`).
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

### 5. Redis-Passwort deaktivieren

- **Im RunCloud-Dashboard:**
  - Gehen Sie zu **Services** im linken Menü.
  - Wählen Sie **Redis** aus der Liste der Dienste.
  - Klicken Sie auf **Settings**.
  - Deaktivieren Sie die Option **Require Password**, um lokale Verbindungen ohne Authentifizierung zu ermöglichen.
  - Klicken Sie auf **Update Redis**, um die Änderung zu speichern.

**Warum das Passwort deaktivieren?**

- Da Redis lokal auf dem Server läuft und nicht von außen erreichbar ist, ist es sicher, das Passwort zu deaktivieren. Dies erleichtert die Konfiguration mit Shopware.

### 6. Datenbank in RunCloud erstellen

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

### 7. Skript ausführen

Das Skript automatisiert viele der erforderlichen Installations- und Konfigurationsschritte für Shopware 6. Folgen Sie den nachstehenden Anweisungen, um das Skript auszuführen.

**Per SSH:**

- **Skript herunterladen:**

  ```bash
  wget -O install_shopware.sh https://github.com/ju-nu/runcloud-shopware6/raw/main/install_shopware.sh
  chmod +x install_shopware.sh
  ```

  *Ersetzen Sie `https://github.com/ju-nu/runcloud-shopware6/raw/main/install_shopware.sh` durch die tatsächliche URL des Skripts, falls abweichend.*

- **Skript ausführen:**

  ```bash
  ./install_shopware.sh -u USERNAME -w WEBAPP -a APP_URL -m MYSQL_USER -p 'MYSQL_PASSWORD' -d MYSQL_DATABASE
  ```

  **Parameterbeschreibung:**

  - `-u USERNAME`: Systembenutzername, unter dem Shopware installiert wird (z. B. `runcloud`).
  - `-w WEBAPP`: Name der Web-App oder des Verzeichnisses (z. B. `shopware`).
  - `-a APP_URL`: URL, unter der Ihre Shopware-Anwendung erreichbar ist (z. B. `https://example.com`).
  - `-m MYSQL_USER`: MySQL-Benutzername für die Shopware-Datenbank.
  - `-p 'MYSQL_PASSWORD'`: Passwort für den MySQL-Benutzer (in einfachen Anführungszeichen, wenn es Sonderzeichen enthält).
  - `-d MYSQL_DATABASE`: Name der MySQL-Datenbank für Shopware.

  **Beispiel:**

  ```bash
  ./install_shopware.sh -u runcloud -w shopware -a https://example.com -m shopware_user -p 'starkesPasswort123' -d shopware_db
  ```

**Hinweis zur Sicherheit:**

- Beachten Sie, dass das Übergeben des MySQL-Passworts als Befehlszeilenargument potenzielle Sicherheitsrisiken birgt, da es möglicherweise in Prozesslisten sichtbar ist. Stellen Sie sicher, dass Ihr System entsprechend gesichert ist.

### 8. PHP-Einstellungen in RunCloud anpassen

Obwohl das Skript viele Konfigurationsschritte automatisiert, müssen einige PHP-Einstellungen manuell in RunCloud angepasst werden, um die optimale Leistung und Sicherheit Ihrer Shopware-Installation zu gewährleisten.

#### PHP-FPM Einstellungen

- **Im RunCloud-Dashboard:**
  - Navigieren Sie zu **Web Applications** und wählen Sie Ihre Shopware-Web-App aus.
  - Gehen Sie zu **Settings** > **PHP-FPM Settings**.

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

#### PHP-Einstellungen

- **Im RunCloud-Dashboard:**
  - Unter **PHP Settings** können Sie die folgenden Einstellungen anpassen.

- **Disable Functions:**

  - Fügen Sie die Liste der zu deaktivierenden Funktionen hinzu, um die Sicherheit zu erhöhen.

    ```ini
    getmyuid,passthru,leak,listen,diskfreespace,tmpfile,link,shell_exec,dl,exec,system,highlight_file,source,show_source,fpassthru,virtual,posix_ctermid,posix_getcwd,posix_getegid,posix_geteuid,posix_getgid,posix_getgrgid,posix_getgrnam,posix_getgroups,posix_getlogin,posix_getpgid,posix_getpgrp,posix_getpid,posix_getppid,posix_getpwuid,posix_getrlimit,posix_getsid,posix_getuid,posix_isatty,posix_kill,posix_mkfifo,posix_setegid,posix_seteuid,posix_setgid,posix_setpgid,posix_setsid,posix_setuid,posix_times,posix_ttyname,posix_uname,escapeshellcmd,ini_alter,popen,pcntl_exec,socket_accept,socket_bind,socket_clear_error,socket_close,socket_connect,symlink,socket_listen,socket_create_listen,socket_read,socket_create_pair,stream_socket_server
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

### 9. Supervisor-Einträge in RunCloud erstellen

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
      /RunCloud/Packages/php83rc/bin/php /home/USERNAME/webapps/WEBAPP/bin/console messenger:consume async low_priority scheduler_shopware --time-limit=600 --memory-limit=1024M --sleep=1
      ```

    - **Directory:** `/home/USERNAME/webapps/WEBAPP`
    - **Autostart:** Aktivieren
    - **Autorestart:** Aktivieren
    - **Zusätzliche Einstellungen:**
      - `startsecs=1`
      - `stopwaitsecs=10`

  - **Job 2: Shopware Default Worker**

    - **Name:** `shopware_default`
    - **Command:**

      ```bash
      /RunCloud/Packages/php83rc/bin/php /home/USERNAME/webapps/WEBAPP/bin/console messenger:consume default --time-limit=600 --memory-limit=1024M --sleep=1
      ```

    - **Directory:** `/home/USERNAME/webapps/WEBAPP`
    - **Weitere Einstellungen wie oben**

  - **Job 3: Shopware Failed Worker**

    - **Name:** `shopware_failed`
    - **Command:**

      ```bash
      /RunCloud/Packages/php83rc/bin/php /home/USERNAME/webapps/WEBAPP/bin/console messenger:consume failed --time-limit=600 --memory-limit=1024M --sleep=1
      ```

    - **Directory:** `/home/USERNAME/webapps/WEBAPP`
    - **Weitere Einstellungen wie oben**

  - **Job 4: Shopware Scheduled Task**

    - **Name:** `shopware_scheduled_task`
    - **Command:**

      ```bash
      /RunCloud/Packages/php83rc/bin/php /home/USERNAME/webapps/WEBAPP/bin/console scheduled-task:run --time-limit=600 --memory-limit=512M
      ```

    - **Directory:** `/home/USERNAME/webapps/WEBAPP`
    - **Weitere Einstellungen wie oben**

- **Supervisor neu starten:**

  - Nach dem Hinzufügen aller Jobs klicken Sie auf **Restart Supervisor**, um die Änderungen zu übernehmen.

**Warum Supervisor?**

- Supervisor stellt sicher, dass die Hintergrundprozesse von Shopware kontinuierlich laufen und bei Bedarf automatisch neu gestartet werden.

## Zusätzliche Hinweise

- **Sicherheit:**
  - Stellen Sie sicher, dass Ihr Server durch eine Firewall geschützt ist und dass Dienste wie Redis und Elasticsearch nicht von außen erreichbar sind.
  - Halten Sie Ihr System und alle Komponenten regelmäßig auf dem neuesten Stand.

- **Fehlerbehebung:**
  - Überprüfen Sie die Log-Dateien (z. B. `/var/log/nginx/`, `/var/log/php8.3-fpm.log`), wenn Probleme auftreten.
  - Stellen Sie sicher, dass alle Dienste laufen und korrekt konfiguriert sind.

- **Leistung:**
  - Passen Sie die Einstellungen für PHP-FPM und MySQL entsprechend den Ressourcen Ihres Servers an.
  - Verwenden Sie die Caching-Mechanismen von Shopware, um die Performance zu verbessern.

## Credits

Dieses Repository wird von der [JUNU Marketing Group LTD](https://ju.nu/) bereitgestellt. Alle Rechte vorbehalten.
