#!/bin/bash

# проверка root
 if [[ $EUID -ne 0 ]]; then      echo "This script must be run as root"
    exit 1
fi

# проверка установки nginx
apt-get update -y
I=$(apt-cache policy nginx | grep "Installed")
if [ -n "$I" ]
    then
	echo "Nginx already installed"
    else
    apt-get install nginx
fi
# при наличии установленых доп. сервисов, удалить их
rm /lib/systemd/system/nginx1.service*
rm /lib/systemd/system/nginx2.service*
# запустить первый nginx
systemctl enable nginx.service
systemctl start nginx.service
# создаем сервис файлы и меняем pid-ы процессов
sed 's/nginx.pid/nginx1.pid/g' /lib/systemd/system/nginx.service >> /lib/systemd/system/nginx1.service
sed 's/nginx.pid/nginx2.pid/g' /lib/systemd/system/nginx.service >> /lib/systemd/system/nginx2.service
# заменяем абсолютные ссылки на релативные, кроме ссылок на модули
symlinks -cvr /etc/nginx/ | grep -v mod
# создаем необходимые для доп. хостов папки
mkdir /etc/nginx1
mkdir /etc/nginx2
mkdir /var/log/nginx1
mkdir /var/log/nginx2
mkdir /var/www/html1
mkdir /var/www/html2
# копируем конфиги
cp -rHv /etc/nginx/* /etc/nginx1
cp -rHv /etc/nginx/* /etc/nginx2
# меняем конфиги
cd /etc/nginx1 || exit
sed --in-place=.orig 's+/nginx+/nginx1+g' /etc/nginx1/nginx.conf >> /etc/nginx1/nginx.conf
sed --in-place=.orig 's+/nginx+/nginx2+g' /etc/nginx2/nginx.conf >> /etc/nginx2/nginx.conf
sed --in-place=.orig 's/listen 80;/listen 81;/g' ./sites-available/default  >> ./sites-available/default
sed --in-place=.orig 's+:80;+:81;+g' ./sites-available/default  >> ./sites-available/default
sed --in-place=.orig 's/server_name localhost;/server_name 1.localhost;/g' ./sites-available/default  >> ./sites-available/default
sed --in-place=.orig 's+var/www/html;+var/www/html1;+g' ./sites-available/default  >> ./sites-available/default
cd /etc/nginx2 || exit
sed --in-place=.orig 's/listen 80;/listen 82;/g' ./sites-available/default  >> ./sites-available/default
sed --in-place=.orig 's+:80;+:82;+g' ./sites-available/default  >> ./sites-available/default
sed --in-place=.orig 's/server_name localhost;/server_name 2.localhost;/g' ./sites-available/default  >> ./sites-available/default
sed --in-place=.orig 's+var/www/html+var/www/html2+g' ./sites-available/default  >> ./sites-available/default
cd ~ || exit
sed --in-place=.orig "s|/usr/sbin/nginx |/usr/sbin/nginx -c /etc/nginx1/nginx.conf |g" /lib/systemd/system/nginx1.service >> /lib/systemd/system/nginx1.service
sed --in-place=.orig "s|/usr/sbin/nginx |/usr/sbin/nginx -c /etc/nginx2/nginx.conf |g" /lib/systemd/system/nginx2.service >> /lib/systemd/system/nginx2.service
# запускаем доп. процессы
systemctl enable nginx1.service 
systemctl enable nginx2.service
systemctl start nginx1.service nginx2.service
# создаем функцию, которая создает страничку с нужным процессом
# и вызываем ее для каждого хоста
./include/index.sh "/var/www/html/index.html" "/run/nginx.pid"
./include/index.sh "/var/www/html1/index.html" "/run/nginx1.pid"
./include/index.sh "/var/www/html2/index.html" "/run/nginx2.pid"