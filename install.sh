#!/usr/bin/env bash

function install_mysql(){
    cd ~/$tmp
	yum install ncurses-devel libaio-devel cmake gcc gcc-c++ make autoconf -y
	wget http://dev.mysql.com/get/Downloads/MySQL-5.6/mysql-5.6.21.tar.gz
	tar -zxvf mysql-5.6.21.tar.gz
	cd mysql-5.6.21

	cmake .
	make
	sudo make install


	sudo groupadd mysql
	sudo useradd -r -g mysql mysql

	cd /usr/local/mysql/
	sudo chown -R root .
	sudo chown -R mysql data


	sudo yum install perl-Data-Dumper -y

	sudo scripts/mysql_install_db --user=mysql
	sudo cp support-files/my-default.cnf /etc/my.cnf

	sudo cp support-files/mysql.server /etc/init.d/mysql
	sudo chmod u+x /etc/init.d/mysql
	sudo chkconfig --add mysql
	# MySQL 环境变量
	cd ~
	echo 'if [ -d "/usr/local/mysql/bin" ] ; then
		PATH=$PATH:/usr/local/mysql/bin
		export PATH
	fi' > env_mysql.sh
	sudo cp env_mysql.sh /etc/profile.d/env_mysql.sh
	touch /usr/local/vagrant.mysql.lock
	ln -s /usr/local/mysql/bin/mysql /usr/bin
	systemctl start mysql
	mysql -uroot -e "CREATE DATABASE $db_name;" 
	echo "Mysql install successful"
}

function install_python(){
	# the version of python
	version="3.8.0"
	# the installation directory of python
	python3_install_dir="/usr/local/python3"
	cd ~/$tmp
	file_name="Python-$version.tgz"
	sudo yum -y install zlib-devel bzip2-devel openssl-devel ncurses-devel sqlite-devel readline-devel tk-devel gcc make libffi-devel
	rm `pwd`"/$file_name"
	wget "https://www.python.org/ftp/python/$version/$file_name"
	mkdir $tmp
	tar -xf $file_name -C $tmp
	make_dir="$tmp/Python-$version"
	cd $make_dir
	mkdir -p $python3_install_dir
	./configure --prefix=$python3_install_dir --with-ssl
	sudo make
	sudo make install
	ln -s /usr/local/python3/bin/python3 /usr/bin/python3
	cd ~/tmp
	wget --no-check-certificate  https://pypi.python.org/packages/source/s/setuptools/setuptools-19.6.tar.gz
	tar -zxvf setuptools-19.6.tar.gz
	cd setuptools-19.6
	python3 setup.py build
	python3 setup.py install
	ln -s /usr/local/python3/bin/pip3 /usr/bin/pip3
	rm -rf ~/$tmp
	echo "all in well !"
}

# -----------------------    安装mysql    ------------------------------
# 编译MySQL时间比较长，需要等很长时间
read -p "Allow Url: " allow_url
read -p "Site Name: " site_name
read -p "Site Url: " site_url
yum install wget git -y
git clone https://github.com/Turnright-git/94imm.git
yum install gcc mariadb-devel -y
cd "94imm"
path=$(pwd)
yum install yum install -y python3-devel
tmp="tmp"
mkdir ~/$tmp
if ! [ -x "$(command -v python3)" ]; then
    echo "Start the Python3 installation process"
    install_python
fi
if ! [ -x "$(command -v mysql)" ]; then
    echo "编译MySQL时间比较长，需要等很长时间,可自安装。行输入n退出"
	read -p "(y , n):" isinstallmysql56
	case "$isinstallmysql56" in
	n|N|No|NO)
    exit
	;;
	*)
	esac
	echo "Start the MySQL installation process"
	install_mysql
	systemctl start mysql
	read -p "Create databases : " db_name
	read -p "Create databases password: " db_pass
	create_db_sql="create database IF NOT EXISTS ${db_name} DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;"
	create_user="update mysql.user set password=password('${db_pass}') where user='root';"
	mysql -uroot -e "${create_db_sql}"
	mysql -uroot -e "${create_user}"
	mysql -uroot -e "${grant_user}"
	mysql -uroot -e "flush privileges;"
else
    read -p "Create databases : " db_name
	read -p "Password for root: " db_pass
	create_db_sql="create database IF NOT EXISTS ${db_name} DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;"
	create_user="update mysql.user set password=password('${db_pass}') where user='root';"
	mysql -uroot -p$db_pass -e "${create_db_sql}"
fi
if ! [ -x "$(command -v nginx)" ]; then
    cd ~/$tmp
    wget https://nginx.org/download/nginx-1.16.0.tar.gz
	tar zxvf nginx-1.16.0.tar.gz
	cd nginx-1.16.0
	./configure --user=nobody --group=nobody --prefix=/usr/local/nginx --with-http_stub_status_module --with-http_gzip_static_module --with-http_realip_module --with-http_sub_module --with-http_ssl_module
	make && make install
cd $path
cat>/lib/systemd/system/nginx.service<<EOF
[Unit]
Description=nginx
After=network.target

[Service]
Type=forking
ExecStart=/usr/local/nginx/sbin/nginx
ExecReload=/usr/local/nginx/sbin/nginx -s reload
ExecStop=/usr/local/nginx/sbin/nginx -s quit
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

cat>/usr/local/nginx/conf/nginx.conf<<EOF
#user  nobody;
worker_processes  1;
events {
    worker_connections  1024;
}


http {
    include       mime.types;
	include       /usr/local/nginx/conf/conf.d/*.conf;
    default_type  application/octet-stream;


    sendfile        on;
    keepalive_timeout  65;

    server {
        listen       80;
        server_name  $site_url;

        #charset koi8-r;

        #access_log  logs/host.access.log  main;

        location / {
		proxy_pass    http://127.0.0.1:8000;
		index index.html index.htm;
		}

        
        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }
    }
}
EOF
/usr/local/nginx/sbin/nginx
fi	
mysql -uroot -p$db_pass $db_name < $path/94imm.sql
cat>"$path/uwsgi.ini"<<EOF
[uwsgi]
chdir=$path/
file=$path/silumz/wsgi.py      
socket=$path/uwsgi.sock     
workers=2
pidfile=$path/uwsgi.pid   
http=127.0.0.1:8000
static-map=/static=$path/static
uid=root
gid=root
master=true
vacuum=true
thunder-lock=true
enable-threads=true
harakiri=30
post-buffering=4096
daemonize=$path/uwsgi.log
stats=8001
EOF
cat>"$path/config.py"<<EOF
mysql_config = {
        'ENGINE': 'django.db.backends.mysql',
        'NAME': '$db_name',
        'USER': 'root',
        'PASSWORD': '$db_name',
        'HOST': '127.0.0.1',
        'PORT': '3306',
    }
allow_url=['$allow_url','127.0.0.1']
cache_time=300
templates="zde"
site_name="$site_name"
site_url = "http://$site_url/"
key_word = "妹子,美女,mm131,妹子图,性感,免费,图片,美女图,胸器"
description = "$site_name分享高品质美女图片，快速无弹窗。可以长期收藏的美女图片站"
email = "amdin@$site_name"
EOF
cd $path
pip3 install -r requirements.txt
uwsgi --ini uwsgi.ini
rm -rf ../tmp