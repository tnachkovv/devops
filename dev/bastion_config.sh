#!/bin/bash
sudo su
yum update
yum install wget -y
mkdir /opt/jfrog
cd /opt/jfrog
wget https://releases.jfrog.io/artifactory/artifactory-pro/org/artifactory/pro/jfrog-artifactory-pro/7.71.9/jfrog-artifactory-pro-7.71.9-linux.tar.gz
tar -xvf jfrog-artifactory-pro-7.71.9-linux.tar.gz
export JFROG_HOME=/opt/jfrog/artifactory-pro-7.71.9
$JFROG_HOME/bin/artifactory.sh start
