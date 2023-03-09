#! /bin/sh
hostname -v www.localhost.com
yum -y install httpd php mysql mysql-server php-mysql php-gd php-imap unzip
IP=ifconfig |grep "inet addr"| cut -f 2 -d ":"|cut -f 1 -d " " |grep -v 127.0.0.1
/etc/init.d/mysqld start
mysqlrootpwd="admin@1234"
mysqladmin -u root password $mysqlrootpwd
cat > /tmp/mysql_sec_script << EOF
use mysql;
update user set password=password('$mysqlrootpwd') where user='root';
update user set host='%' where user='root' and host='localhost';
flush privileges;
EOF
rm -f /tmp/mysql_sec_script
/etc/init.d/mysqld restart


#create oempro database
cat > /tmp/mysql_create_db << EOF
create database oem;
grant all privileges on oem.* to oem@localhost identified by "oempro";
flush privileges;
EOF
mysql -u root -p$mysqlrootpwd -h localhost < /tmp/mysql_create_db
rm -f /tmp/mysql_create_db


#install PMTA
curl_dir=/usr/local/src

if [[ `uname -m` == "x86_64" ]];then
        cd $curl_dir
        unzip Opmta4.5r1.zip
        cd pmta4.5r1
        rpm -ivh PowerMTA-4.5r1.rpm
        \cp -rf license /etc/pmta/license
        \cp usr/sbin/pmtad /usr/sbin/pmtad
        \cp usr/sbin/pmta /usr/sbin/pmta
fi

if [[ `uname -m` != "x86_64" ]];then
        cd $curl_dir
        unzip Opmta4.5r1.zip
        cd pmta4.5r1
        rpm -ivh PowerMTA-4.5r1.rpm
        \cp -rf license /etc/pmta/license
        \cp usr/sbin/pmtad /usr/sbin/pmtad
        \cp usr/sbin/pmta /usr/sbin/pmta
fi

\cp $curl_dir/conf/config /etc/pmta/
/etc/init.d/pmta restart

cd $curl_dir
tar zxvf oempro432.tar.gz
mv oempro432 /var/www/html/oem
mv php.ini /etc
mv crontab /etc
mv my.cnf /etc
chmod 777 /var/www/html/oem/*
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
setenforce 0

chkconfig httpd on
chkconfig mysqld on
/etc/init.d/iptables stop
chkconfig iptables off
/etc/init.d/httpd start
/etc/init.d/mysqld start

mkdir -p /var/www/tmp
mkdir -p /var/www/badmail
chmod -R 777 /var/www/tmp
chmod -R 777 /var/www/badmail
IP=`ifconfig |grep "inet addr"| cut -f 2 -d ":"|cut -f 1 -d " " |grep -v 127.0.0.1|head -n 1 `
echo "* * * * * curl -s http://$IP/oem/cli/web_send.php > /dev/null 2>&1"  >> /var/spool/cron/root
/etc/init.d/crond restart
/etc/init.d/mysqld restart

service pmtahttp restart

