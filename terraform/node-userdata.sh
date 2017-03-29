#!/bin/bash -v

whoami
env

systemctl stop firewalld
systemctl disable firewalld
yum update -y
yum install -y epel-release
yum install -y git
yum install -y nodejs
npm install -g pm2
git clone ${repoUrl} /opt/app
cd /opt/app
npm --no-color install
DB_HOST=${databaseIp} DB_PORT=3306 DB_USER=brooklyn DB_PASSWORD=br00k11n DB_NAME=todo pm2 start node ${repoScript}
sleep 1
