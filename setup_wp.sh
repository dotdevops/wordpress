#!/bin/bash
#
#

SOFTWARE_BASE=/root/software

NGINX_VER="1.0.5"
VARNISH_VER="3.0.0"
PHP_VER="5.3.6"
MHASH_VER="0.9.9.9"
MCRYPT_VER="2.6.8"
WWW_ROOT=/home/nginx/html/default
DATE=$(date +%Y_%m_%d-%H%M%S)

if [ ! -f /etc/redhat-release ] ; then
  echo "This only work on RedHat & CentOS systems"
  exit 15
fi

ARCH=`uname -i`
if [ ${ARCH} == "i386" ] ; then
  OS=32
else
  OS=64
fi

# Install EPEL
rpm -Uvh http://download.fedoraproject.org/pub/epel/6/`uname -i`/epel-release-6-5.noarch.rpm

# Upgrade old packages and install required ones
yum update -y
yum install -y curl curl-devel iftop openssl openssl-devel mysql mysql-server mysql-devel gcc gcc-c++ make bison flex patch autoconf locate pcre pcre-devel zlib zlib-devel libjpeg-devel libpng-devel libmcrypt libmcrypt-devel atk audit-libs cairo cracklib cups-libs db4 device-mapper e2fsprogs-libs expat fontconfig freetype gdbm glib2 glibc gnutls gtk2 keyutils-libs krb5-libs libX11 libXau libXcursor libXdmcp libXext libXfixes libXft libXi libXinerama libXrandr libXrender libgcc libgcrypt libgpg-error libhugetlbfs libjpeg libpng libselinux libsepol libstdc++ automake libtool libtool-ltdl libcurl libcurl-devel GeoIP GeoIP-devel gd wget libxml2 libxml2-devel libXpm libXpm-devel freetype freetype-devel 

# Setup MySQL
/sbin/chkconfig mysqld on
# Code to update my.cnf
service mysqld start

# Install & setup nginx
mkdir -p $SOFTWARE_BASE
cd $SOFTWARE_BASE
wget http://nginx.org/download/nginx-${NGINX_VER}.tar.gz
tar -xzvf nginx-${NGINX_VER}.tar.gz
cd nginx-${NGINX_VER}

if [ ${OS} == "32" ] ; then
  CONFIGURE_OPTS="--prefix=/var/nginx --pid-path=/var/run/nginx.pid --sbin-path=/usr/sbin/nginx --with-md5=/usr/lib --with-sha1=/usr/lib --with-http_ssl_module --with-http_dav_module --conf-path=/etc/nginx/nginx.conf --user=nginx --group=nginx --with-http_realip_module --with-http_stub_status_module --with-http_ssl_module --http-log-path=/var/log/nginx/access.log --http-client-body-temp-path=/var/tmp/nginx/client/ --error-log-path=/var/log/nginx/error.log --without-mail_pop3_module --without-mail_imap_module --without-mail_smtp_module --http-proxy-temp-path=/var/tmp/nginx/proxy --http-fastcgi-temp-path=/var/tmp//nginx/fastcgi --http-uwsgi-temp-path=/var/tmp//nginx/uwsgi --http-scgi-temp-path=/var/tmp//nginx/scgi --pid-path=/var/run/nginx.pid --lock-path=/var/lock/subsys/nginx --with-http_realip_module --with-http_addition_module  --with-http_geoip_module --with-http_sub_module --with-http_dav_module --with-http_flv_module --with-http_gzip_static_module --with-http_random_index_module --with-http_secure_link_module --with-http_degradation_module --with-pcre"
else
  CONFIGURE_OPTS="--prefix=/var/nginx --pid-path=/var/run/nginx.pid --sbin-path=/usr/sbin/nginx --with-md5=/usr/lib --with-sha1=/usr/lib --with-http_ssl_module --with-http_dav_module --conf-path=/etc/nginx/nginx.conf --user=nginx --group=nginx --with-http_realip_module --with-http_stub_status_module --with-http_ssl_module --http-log-path=/var/log/nginx/access.log --http-client-body-temp-path=/var/tmp/nginx/client/ --error-log-path=/var/log/nginx/error.log --without-mail_pop3_module --without-mail_imap_module --without-mail_smtp_module --http-proxy-temp-path=/var/tmp/nginx/proxy --http-fastcgi-temp-path=/var/tmp//nginx/fastcgi --http-uwsgi-temp-path=/var/tmp//nginx/uwsgi --http-scgi-temp-path=/var/tmp//nginx/scgi --pid-path=/var/run/nginx.pid --lock-path=/var/lock/subsys/nginx --with-http_realip_module --with-http_addition_module  --with-http_geoip_module --with-http_sub_module --with-http_dav_module --with-http_flv_module --with-http_gzip_static_module --with-http_random_index_module --with-http_secure_link_module --with-http_degradation_module --with-pcre -with-ld-opt='-L /usr/lib64'"
fi
./configure ${CONFIGURE_OPTS}
make && make install
groupadd nginx
wget http://www.magnet-id.com/download/nginx/nginx-daemon -O /etc/init.d/nginx
useradd -g nginx -s /bin/nologin nginx
mkdir -p /var/log/nginx
mkdir -p /var/www/html/default
mkdir -p /var/tmp/nginx/client
chown -R nginx:nginx /var/tmp/nginx
chown -R nginx:nginx /var/log/nginx
if [ ! -d ${WWW_ROOT} ] ; then
  mkdir -p ${WWW_ROOT}
  chown -R nginx:nginx ${WWW_ROOT}
fi

# Install Varnish
cd $SOFTWARE_BASE
wget http://repo.varnish-cache.org/source/varnish-${VARNISH_VER}.tar.gz
tar -xzvf varnish-${VARNISH_VER}.tar.gz 
cd varnish-${VARNISH_VER}
./autogen.sh
./configure --enable-debugging-symbols --enable-developer-warnings 
make && make install

# Install mhash
cd $SOFTWARE_BASE
wget "http://downloads.sourceforge.net/project/mhash/mhash/0.9.9.9/mhash-0.9.9.9.tar.gz?r=&amp;ts=1312943985&amp;use_mirror=softlayer"
tar -xzvf mhash-${MHASH_VER}.tar.gz
cd mhash-${MHASH_VER}
./configure 
make && make install && ldconfig
echo "/usr/local/lib" >> /etc/ld.so.conf
ldconfig

# Install mcrypt
cd $SOFTWARE_BASE
wget "http://downloads.sourceforge.net/project/mcrypt/MCrypt/2.6.8/mcrypt-2.6.8.tar.gz?r=http%3A%2F%2Fsourceforge.net%2Fprojects%2Fmcrypt%2F&ts=1312180294&use_mirror=surfnet"
tar -xzvf mcrypt-${MCRYPT_VER}.tar.gz
cd mcrypt-${MCRYPT_VER}
./configure


# Install PHP
if [ -f /usr/lib/libltdl.so ] ; then
  echo "won't install unless we can find libltdl.so"
  echo "try ldconfig -p |grep ltdl"
  echo "then symlink ln -s <output> to /usr/lib/libltdl.so"
  exit 15
fi

cd $SOFTWARE_BASE
wget http://www.php.net/get/php-${PHP_VER}.tar.gz/from/us2.php.net/mirror
tar -xzvf php-${PHP_VER}.tar.gz
cd php-${PHP_VER}
if [ ${OS} == "32" ] ; then
  CONFIGURE_OPTS="--enable-fpm  --with-mcrypt  --enable-mbstring  --with-openssl  --with-mysql  --with-mysql-sock  --with-gd  --with-png-dir=/usr/lib  --with-jpeg-dir=/usr/lib  --with-xpm-dir=/usr/lib  --enable-gd-native-ttf   --with-pdo-mysql  --with-libxml-dir=/usr/lib  --with-mysqli=/usr/bin/mysql_config  --with-curl  --enable-zip  --enable-sockets  --with-zlib  --enable-exif  --enable-ftp  --with-iconv  --with-gettext  --enable-gd-native-ttf --with-freetype-dir=/usr  --prefix=/usr/local/php --enable-sockets --enable-sysvsem --enable-pcntl --enable-mbregex --with-mhash --enable-zip --with-pcre-regex --with-config-file-path=/etc"
else
  CONFIGURE_OPTS="--enable-fpm  --with-mcrypt  --enable-mbstring  --with-openssl  --with-mysql  --with-mysql-sock  --with-gd  --with-png-dir=/usr/lib64  --with-jpeg-dir=/usr/lib64  --with-xpm-dir=/usr/lib64  --enable-gd-native-ttf   --with-pdo-mysql  --with-libxml-dir=/usr/lib64  --with-mysqli=/usr/bin/mysql_config  --with-curl  --enable-zip  --enable-sockets  --with-zlib  --enable-exif  --enable-ftp  --with-iconv  --with-gettext  --enable-gd-native-ttf --with-freetype-dir=/usr  --prefix=/usr/local/php --enable-sockets --enable-sysvsem --enable-pcntl --enable-mbregex --with-mhash --enable-zip --with-pcre-regex --with-config-file-path=/etc"
fi
./configure ${CONFIGURE_OPTS}
make && make install
mkdir /etc/php
if [ -f /etc/php/php.ini ] ; then
  cp  /etc/php/php.ini /etc/php/php.ini-${DATE}
fi
cp php.ini-production /etc/php/php.ini
if [ -f /etc/php/php-fpm.conf ] ; then
  cp /etc/php/php-fpm.conf /etc/php/php-fpm.conf-${DATE}
fi
cp /usr/local/php/etc/php-fpm.conf.default /etc/php/php-fpm.conf
cp /root/software/php-5.3.6/sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm
chmod 750 /etc/init.d/php-fpm
mkdir -p /var/log/php
# Update php-fpm.conf for correct username * locations for logs

# Install WP
cd ${WWW_ROOT}
wget http://wordpress.org/latest.tar.gz
tar -xzvf latest.tar.gz

cat <<EOF
 
 You will need to update /etc/php/php-fpm.conf with the correct user & log location
 Also, don't forget to load your robots.txt
 You can also download mine if needed 
 wget "https://github.com/dotdevops/wordpress/blob/master/robots.txt"

EOF

