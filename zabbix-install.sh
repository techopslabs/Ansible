#!/bin/bash
# zabbix-install.sh
# Zabbix 7.2 Installation Script for Ubuntu 22.04

set -e

# Configuration variables
DB_PASSWORD="Secure@password@321"
ZABBIX_REPO_URL="https://repo.zabbix.com/zabbix/7.2/release/ubuntu/pool/main/z/zabbix-release/zabbix-release_latest_7.2+ubuntu22.04_all.deb"

echo "Starting Zabbix 7.2 installation on Ubuntu 22.04..."

# Step 1: Install Zabbix repository
echo "Installing Zabbix repository..."
wget "$ZABBIX_REPO_URL"
dpkg -i zabbix-release_latest_7.2+ubuntu22.04_all.deb
apt update

# Step 2: Install Zabbix server, frontend, and agent
echo "Installing Zabbix components..."
apt install -y zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf zabbix-sql-scripts zabbix-agent

# Step 3: Install MySQL if not already installed
echo "Installing MySQL server if not already installed..."
apt install -y mysql-server

# Step 4: Create initial database
echo "Creating Zabbix database..."
mysql -e "create database zabbix character set utf8mb4 collate utf8mb4_bin;"
mysql -e "create user zabbix@localhost identified by '$DB_PASSWORD';"
mysql -e "grant all privileges on zabbix.* to zabbix@localhost;"
mysql -e "set global log_bin_trust_function_creators = 1;"

# Step 5: Import initial schema and data
echo "Importing initial schema and data (this may take a few minutes)..."
zcat /usr/share/doc/zabbix-sql-scripts/mysql/create.sql.gz | mysql -uzabbix -p"$DB_PASSWORD" zabbix

# Step 6: Disable log_bin_trust_function_creators option after import
echo "Configuring MySQL after import..."
mysql -e "set global log_bin_trust_function_creators = 0;"

# Step 7: Configure the database for Zabbix server
echo "Configuring Zabbix server..."
sed -i "s/# DBPassword=/DBPassword=$DB_PASSWORD/" /etc/zabbix/zabbix_server.conf

# Step 8: Configure PHP for Zabbix frontend
echo "Configuring PHP for Zabbix frontend..."
sed -i 's/;date.timezone =/date.timezone = UTC/' /etc/php/*/apache2/php.ini

# Step 9: Start Zabbix server and agent processes
echo "Starting Zabbix services..."
systemctl restart zabbix-server zabbix-agent apache2
systemctl enable zabbix-server zabbix-agent apache2

# Step 10: Check service status
echo "Checking service status..."
systemctl status zabbix-server --no-pager
systemctl status zabbix-agent --no-pager
systemctl status apache2 --no-pager

# Cleanup
rm zabbix-release_latest_7.2+ubuntu22.04_all.deb

echo "Zabbix installation completed!"
echo "Access the Zabbix web interface at http://$(hostname -I | awk '{print $1}')/zabbix"
echo "Default credentials: Admin / zabbix"
