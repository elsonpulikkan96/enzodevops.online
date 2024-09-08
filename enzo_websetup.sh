
touch enzo_websetup.sh

chmod +x enzo_websetup.sh

#!/bin/bash 
ip=$(wget -qO - icanhazip.com)
echo "Public IP of EC2 instance is: http://$ip"
sudo hostnamectl set-hostname enzodevops.online
sudo apt-get update && sudo apt-get upgrade -y
sudo sed -i 's/#Port 22/Port 1243/g' /etc/ssh/sshd_config
echo "ClientAliveInterval 360" | sudo tee -a /etc/ssh/sshd_config
sudo systemctl restart ssh
sudo apt-get install -y net-tools git lynx unzip zip curl apache2 openssl certbot python3-certbot-apache

sudo a2enmod rewrite
sudo a2enmod ssl
sudo systemctl enable apache2
sudo systemctl restart apache2.service
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
    RewriteCond %{SERVER_NAME} =enzodevops.online [OR]
    RewriteCond %{SERVER_NAME} =www.enzodevops.online
    RewriteRule ^ https://%{SERVER_NAME}%{REQUEST_URI} [END,NE,R=permanent]
</VirtualHost>

<VirtualHost *:443>
    ServerAdmin admin@enzodevops.online
    ServerName enzodevops.online
    ServerAlias www.enzodevops.online
    DocumentRoot /var/www/html

    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
    RewriteEngine on
    RewriteCond %{HTTPS} off
    RewriteRule ^/?(.*) https://%{SERVER_NAME}/$1 [R=301,L]
    SSLCertificateFile /etc/letsencrypt/live/enzodevops.online/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/enzodevops.online/privkey.pem
    <FilesMatch "\.(cgi|shtml|phtml|php)$">
        SSLOptions +StdEnvVars
    </FilesMatch>

    <Directory /usr/lib/cgi-bin>
        SSLOptions +StdEnvVars
    </Directory>
SSLCertificateFile /etc/letsencrypt/live/enzodevops.online/fullchain.pem
SSLCertificateKeyFile /etc/letsencrypt/live/enzodevops.online/privkey.pem
Include /etc/letsencrypt/options-ssl-apache.conf
</VirtualHost> 
EOF

sudo a2ensite enzodevops.online
sudo certbot --apache -d enzodevops.online --non-interactive --agree-tos -m admin@enzodevops.online
sudo systemctl restart apache2.service
sudo systemctl status apache2.service



#Work around if getting SSL related errors:


#nslookup enzodevops.online -  check if enzodevops.online is pointed to an A Record 


 #Temporary comment on the Config for SSL on /etc/apache2/sites-available/enzodevops.online.conf

    #SSLCertificateFile /etc/letsencrypt/live/enzodevops.online/fullchain.pem
    #SSLCertificateKeyFile /etc/letsencrypt/live/enzodevops.online/privkey.pem


# sudo certbot --apache -d enzodevops.online --non-interactive --agree-tos -m admin@enzodevops.online

#Re-enable HTTPS Redirection with SSL by regenerate certificates and uncomment SSL config on <VirtualHost *:443>

sudo systemctl restart apache2.service
