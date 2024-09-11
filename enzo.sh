#!/bin/bash
# Author: https://github.com/elsonpulikkan96

ip=$(wget -qO- icanhazip.com)
echo "Public IP of EC2 instance is: $ip"

echo -e "\nMake sure your domain enzodevops.online points to the server's public IP with an A record in DNS."
echo "If using AWS Route 53, verify the hosted zone is configured properly before running Certbot."

sudo hostnamectl set-hostname enzodevops.online
sudo apt-get update && sudo apt-get upgrade -y
sudo sed -i 's/#Port 22/Port 1243/g' /etc/ssh/sshd_config
echo "ClientAliveInterval 360" | sudo tee -a /etc/ssh/sshd_config
sudo systemctl restart ssh
sudo apt-get install -y net-tools git lynx unzip zip curl apache2 openssl certbot python3-certbot-apache
sudo systemctl enable apache2
sudo systemctl restart apache2
sudo unlink /etc/apache2/sites-available/000-default.conf
sudo rm /etc/apache2/sites-available/*
sudo rm /etc/apache2/sites-enabled/*
sudo rm -rf /var/www/html/*
cd /opt/
sudo git clone https://github.com/elsonpulikkan96/enzodevops.online
sudo cp -R /opt/enzodevops.online/* /var/www/html/
CONF_FILE="/etc/apache2/sites-available/enzodevops.online.conf"
sudo touch $CONF_FILE
cat << EOF | sudo tee $CONF_FILE
<VirtualHost *:80>
    ServerAdmin admin@enzodevops.online
    ServerName enzodevops.online
    ServerAlias www.enzodevops.online
    DocumentRoot /var/www/html
    RewriteEngine on
    RewriteCond %{HTTPS} off
    RewriteRule ^/?(.*) https://%{SERVER_NAME}/\$1 [R=301,L]
    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF

sudo a2ensite enzodevops.online
sudo systemctl reload apache2
sudo a2enmod ssl rewrite
sudo systemctl restart apache2
sudo certbot --apache -d enzodevops.online --non-interactive --agree-tos -m admin@enzodevops.online

cat << EOF | sudo tee -a $CONF_FILE
<VirtualHost *:443>
    ServerAdmin admin@enzodevops.online
    ServerName enzodevops.online
    ServerAlias www.enzodevops.online
    DocumentRoot /var/www/html
    SSLEngine on
    SSLCertificateFile /etc/letsencrypt/live/enzodevops.online/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/enzodevops.online/privkey.pem
    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
    RewriteEngine on
    <FilesMatch "\.(cgi|shtml|phtml|php)$">
        SSLOptions +StdEnvVars
    </FilesMatch>
    <Directory /usr/lib/cgi-bin>
        SSLOptions +StdEnvVars
    </Directory>
</VirtualHost>
EOF

sudo systemctl reload apache2 && sudo systemctl restart apache2
sudo systemctl status apache2
