#!/bin/bash
# Zabbix Installation Script for Ubuntu 22.04
# This script installs Zabbix 6.4 with MySQL database

set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration variables - customize these as needed
DB_PASSWORD="Secure@password@321"
ZABBIX_VERSION="6.4"
UBUNTU_VERSION="ubuntu22.04"

echo -e "${GREEN}Starting Zabbix $ZABBIX_VERSION installation on Ubuntu 22.04...${NC}"

# Step 1: Install Zabbix repository
echo -e "${GREEN}Installing Zabbix repository...${NC}"
wget https://repo.zabbix.com/zabbix/$ZABBIX_VERSION/$UBUNTU_VERSION/pool/main/z/zabbix-release/zabbix-release_$ZABBIX_VERSION-1+$UBUNTU_VERSION\_all.deb
sudo dpkg -i zabbix-release_$ZABBIX_VERSION-1+$UBUNTU_VERSION\_all.deb
sudo apt update

# Step 2: Install Zabbix server, frontend, and agent
echo -e "${GREEN}Installing Zabbix components...${NC}"
sudo apt install -y zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf zabbix-sql-scripts zabbix-agent

# Step 3: Install MySQL if not already installed
echo -e "${GREEN}Installing MySQL server if not already installed...${NC}"
sudo apt install -y mysql-server

# Step 4: Create initial database
echo -e "${GREEN}Creating Zabbix database...${NC}"
sudo mysql -e "create database zabbix character set utf8mb4 collate utf8mb4_bin;"
sudo mysql -e "create user zabbix@localhost identified by '$DB_PASSWORD';"
sudo mysql -e "grant all privileges on zabbix.* to zabbix@localhost;"
sudo mysql -e "set global log_bin_trust_function_creators = 1;"

# Step 5: Import initial schema and data
echo -e "${GREEN}Importing initial schema and data (this may take a few minutes)...${NC}"
zcat /usr/share/doc/zabbix-sql-scripts/mysql/create.sql.gz | sudo mysql -uzabbix -p"$DB_PASSWORD" zabbix

# Step 6: Disable log_bin_trust_function_creators option after import
echo -e "${GREEN}Configuring MySQL after import...${NC}"
sudo mysql -e "set global log_bin_trust_function_creators = 0;"

# Step 7: Configure the database for Zabbix server
echo -e "${GREEN}Configuring Zabbix server...${NC}"
sudo sed -i "s/# DBPassword=/DBPassword=$DB_PASSWORD/" /etc/zabbix/zabbix_server.conf

# Step 8: Configure PHP for Zabbix frontend
echo -e "${GREEN}Configuring PHP for Zabbix frontend...${NC}"
sudo sed -i 's/;date.timezone =/date.timezone = UTC/' /etc/php/*/apache2/php.ini

# Step 9: Start Zabbix server and agent processes
echo -e "${GREEN}Starting Zabbix services...${NC}"
sudo systemctl restart zabbix-server zabbix-agent apache2
sudo systemctl enable zabbix-server zabbix-agent apache2

# Step 10: Check service status
echo -e "${GREEN}Checking service status...${NC}"
sudo systemctl status zabbix-server --no-pager
sudo systemctl status zabbix-agent --no-pager
sudo systemctl status apache2 --no-pager

# Cleanup
rm zabbix-release_$ZABBIX_VERSION-1+$UBUNTU_VERSION\_all.deb

echo -e "${GREEN}Zabbix installation completed!${NC}"
echo -e "${GREEN}Access the Zabbix web interface at http://server_ip_or_name/zabbix${NC}"
echo -e "${GREEN}Default credentials: Admin / zabbix${NC}"
