#!/bin/bash 

if [ $(id -u) -ne 0 ]; then 
  echo "You should be a root user to perform this command"
  exit 1 
fi 

yum install java-11-openjdk -y 
URL=$(curl -s https://www.sonarqube.org/downloads/ | grep 'Community Edition' | head -1  | xargs -n 1  | grep ^href | awk -F = '{print $2}')
FILENAME=$(echo $URL | awk -F / '{print $NF}')
FOLDERNAME=$(echo $FILENAME | sed -e 's/.zip//g')

id sonar &>/dev/null 
if [ $? -ne 0 ]; then 
  useradd sonar 
fi 

cd /home/sonar 
pkill java 
rm -rf sonarqube 
curl -s -o $FILENAME $URL 
unzip $FILENAME 
rm -f $FILENAME
mv $FOLDERNAME sonarqube

chown sonar:sonar sonarqube -R 
#curl -s https://raw.githubusercontent.com/venkat09docs/jenkins-project/master/tools/sonarqube/sonar.service >/etc/systemd/system/sonarqube.service 
systemctl daemon-reload 
systemctl enable sonarqube 
sed -i -e '/^RUN_AS_USER/ d' -e '/#RUN_AS_USER/ a RUN_AS_USER=sonar' /home/sonar/sonarqube/bin/linux-x86-64/sonar.sh
systemctl start sonarqube
