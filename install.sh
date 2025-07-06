#!/bin/bash

### --- Script configurazione automatica server Hetzner Ubuntu 24.04 --- ###
# - Installa: Apache, PHP, MySQL, FTP, Certbot, Fail2Ban
# - Configura Firewall (UFW)
# - Crea cartella /var/www e utente FTP
# - Aggiornamenti sistema
# -----------------------------------------------------------

### Aggiorna sistema
apt update && apt upgrade -y

### Installa software base
apt install -y apache2 php php-mysql libapache2-mod-php \
    mysql-server curl unzip git ufw vsftpd certbot python3-certbot-apache fail2ban

### Abilita Apache e MySQL
timedatectl set-timezone Europe/Rome
systemctl enable apache2
systemctl enable mysql
systemctl start apache2
systemctl start mysql

### Configura UFW
ufw allow OpenSSH
ufw allow "Apache Full"
ufw --force enable

### Configura FTP
sed -i 's/anonymous_enable=YES/anonymous_enable=NO/' /etc/vsftpd.conf
echo -e "write_enable=YES\nchroot_local_user=YES\npasv_enable=YES\npasv_min_port=40000\npasv_max_port=50000\nlocal_umask=022\nuser_sub_token=$USER\nlocal_root=/var/www/" >> /etc/vsftpd.conf
systemctl restart vsftpd

### Crea directory per siti e utente FTP
groupadd webmasters
useradd -m -d /var/www/webadmin -s /bin/bash -G webmasters webadmin
echo "webadmin:changeme" | chpasswd
chown -R webadmin:webmasters /var/www
chmod -R 755 /var/www

### Configura MySQL (disabilita login root da remoto)
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'changemysql';"
mysql -e "DELETE FROM mysql.user WHERE User='';"
mysql -e "DROP DATABASE IF EXISTS test;"
mysql -e "FLUSH PRIVILEGES;"

### Configura fail2ban
systemctl enable fail2ban
systemctl start fail2ban

### Messaggio finale
echo -e "\n✅ Setup completato!"
echo -e "\n- Apache disponibile su IP pubblico"
echo -e "- FTP abilitato su porta 21, utente: webadmin (password: changeme)"
echo -e "- MySQL root: changemysql"
echo -e "- Posizionare i siti in: /var/www/"
echo -e "\n⚠️ Ricorda di cambiare le password!"
