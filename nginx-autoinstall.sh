#!/bin/bash

# Colors
CSI="\\033["
CEND="${CSI}0m"
CRED="${CSI}1;31m"
CGREEN="${CSI}1;32m"

if [[ "$EUID" -ne 0 ]]; then
	echo -e "Sorry, you need to run this as root"
	exit 1
fi

# Variables
NGINX_MAINLINE_VER=1.17.4
OPENSSL_VER=1.1.1d
NPS_VER=1.13.35.2
HEADERMOD_VER=0.33
LIBMAXMINDDB_VER=1.3.2
GEOIP2_VER=3.2

rm /tmp/nginx-autoinstall.log

clear
echo ""
echo "Welcome to the nginx-autoinstall script."
echo ""
echo "What do you want to do?"
echo "   1) Install or update Nginx"
echo "   2) Uninstall Nginx"
echo "   3) Update the script"
echo "   4) Exit"
echo ""
while [[ $OPTION !=  "1" && $OPTION != "2" && $OPTION != "3" && $OPTION != "4" ]]; do
	read -p "Select an option [1-4]: " OPTION
done
case $OPTION in
	1)
		echo ""
		echo "This script will install Nginx with some optional modules."
		echo "install Nginx mainline $NGINX_MAINLINE_VER"
		
		NGINX_VER=$NGINX_MAINLINE_VER

		echo ""
		echo "Please tell me which modules you want to install."
		echo "If you select none, Nginx will be installed with its default modules."
		echo ""
		echo "Modules to install :"
		while [[ $PAGESPEED != "y" && $PAGESPEED != "n" ]]; do
			read -p "       PageSpeed $NPS_VER [y/n]: " -e PAGESPEED
		done
		while [[ $BROTLI != "y" && $BROTLI != "n" ]]; do
			read -p "       Brotli [y/n]: " -e BROTLI
		done
		while [[ $HEADERMOD != "y" && $HEADERMOD != "n" ]]; do
			read -p "       Headers More $HEADERMOD_VER [y/n]: " -e HEADERMOD
		done
		while [[ $GEOIP != "y" && $GEOIP != "n" ]]; do
			read -p "       GeoIP [y/n]: " -e GEOIP
		done
		while [[ $FANCYINDEX != "y" && $FANCYINDEX != "n" ]]; do
			read -p "       Fancy index [y/n]: " -e FANCYINDEX
		done
		while [[ $CACHEPURGE != "y" && $CACHEPURGE != "n" ]]; do
			read -p "       ngx_cache_purge [y/n]: " -e CACHEPURGE
		done

		read -n1 -r -p "Nginx is ready to be installed, press any key to continue..."
		echo ""

		# Cleanup
		# The directory should be deleted at the end of the script, but in case it fails
		rm -r /usr/local/src/nginx/ >> /tmp/nginx-autoinstall.log 2>&1
		mkdir -p /usr/local/src/nginx/modules >> /tmp/nginx-autoinstall.log 2>&1

		# Dependencies
		apt-get update >> /tmp/nginx-autoinstall.log 2>&1
		apt-get install -y build-essential ca-certificates wget curl libpcre3 libpcre3-dev autoconf unzip automake libtool tar git libssl-dev zlib1g-dev uuid-dev lsb-release >> /tmp/nginx-autoinstall.log 2>&1

		if [ $? -eq 0 ]; then
			echo -ne "       Installing dependencies        [${CGREEN}OK${CEND}]\\r"
			echo -ne "\\n"
		else
			echo -e "        Installing dependencies      [${CRED}FAIL${CEND}]"
			echo ""
			echo "Please look at /tmp/nginx-autoinstall.log"
			echo ""
			exit 1
		fi

		# PageSpeed
		if [[ "$PAGESPEED" = 'y' ]]; then
			cd /usr/local/src/nginx/modules || exit 1
			wget https://github.com/pagespeed/ngx_pagespeed/archive/v${NPS_VER}-stable.zip >> /tmp/nginx-autoinstall.log 2>&1
			unzip v${NPS_VER}-stable.zip  >> /tmp/nginx-autoinstall.log 2>&1
			cd incubator-pagespeed-ngx-${NPS_VER}-stable || exit 1
			psol_url=https://dl.google.com/dl/page-speed/psol/${NPS_VER}.tar.gz
			[ -e scripts/format_binary_url.sh ] && psol_url=$(scripts/format_binary_url.sh PSOL_BINARY_URL)
			
			if [ $? -eq 0 ]; then
				echo -ne "       Downloading ngx_pagespeed      [${CGREEN}OK${CEND}]\\r"
				echo -ne "\\n"
			else
				echo -e "       Downloading ngx_pagespeed      [${CRED}FAIL${CEND}]"
				echo ""
				echo "Please look at /tmp/nginx-autoinstall.log"
				echo ""
				exit 1
			fi
			wget "${psol_url}" >> /tmp/nginx-autoinstall.log 2>&1
			tar -xzvf "$(basename "${psol_url}")" >> /tmp/nginx-autoinstall.log 2>&1
		fi

		#Brotli
		if [[ "$BROTLI" = 'y' ]]; then
			cd /usr/local/src/nginx/modules || exit 1
			echo -ne "       Downloading ngx_brotli         [..]\\r"
			git clone https://github.com/eustas/ngx_brotli >> /tmp/nginx-autoinstall.log 2>&1
			cd ngx_brotli || exit 1
			git checkout v0.1.2 >> /tmp/nginx-autoinstall.log 2>&1
			git submodule update --init >> /tmp/nginx-autoinstall.log 2>&1

			if [ $? -eq 0 ]; then
				echo -ne "       Downloading ngx_brotli         [${CGREEN}OK${CEND}]\\r"
				echo -ne "\\n"
			else
				echo -e "       Downloading ngx_brotli         [${CRED}FAIL${CEND}]"
				echo ""
				echo "Please look at /tmp/nginx-autoinstall.log"
				echo ""
				exit 1
			fi
		fi

		# More Headers
		if [[ "$HEADERMOD" = 'y' ]]; then
			cd /usr/local/src/nginx/modules || exit 1
			echo -ne "       Downloading ngx_headers_more   [..]\\r"
			wget https://github.com/openresty/headers-more-nginx-module/archive/v${HEADERMOD_VER}.tar.gz >> /tmp/nginx-autoinstall.log 2>&1
			tar xaf v${HEADERMOD_VER}.tar.gz >> /tmp/nginx-autoinstall.log 2>&1

			if [ $? -eq 0 ]; then
				echo -ne "       Downloading ngx_headers_more   [${CGREEN}OK${CEND}]\\r"
				echo -ne "\\n"
			else
				echo -e "       Downloading ngx_headers_more   [${CRED}FAIL${CEND}]"
				echo ""
				echo "Please look at /tmp/nginx-autoinstall.log"
				echo ""
				exit 1
			fi
		fi

		# GeoIP
		if [[ "$GEOIP" = 'y' ]]; then
			cd /usr/local/src/nginx/modules || exit 1
			# install libmaxminddb
			wget https://github.com/maxmind/libmaxminddb/releases/download/${LIBMAXMINDDB_VER}/libmaxminddb-${LIBMAXMINDDB_VER}.tar.gz >> /tmp/nginx-autoinstall.log 2>&1
			tar xaf libmaxminddb-${LIBMAXMINDDB_VER}.tar.gz  >> /tmp/nginx-autoinstall.log 2>&1
			cd libmaxminddb-${LIBMAXMINDDB_VER}/
			./configure >> /tmp/nginx-autoinstall.log 2>&1
			make >> /tmp/nginx-autoinstall.log 2>&1
			make install >> /tmp/nginx-autoinstall.log 2>&1
			ldconfig >> /tmp/nginx-autoinstall.log 2>&1

			cd ../
			wget https://github.com/leev/ngx_http_geoip2_module/archive/${GEOIP2_VER}.tar.gz >> /tmp/nginx-autoinstall.log 2>&1
			tar xaf ${GEOIP2_VER}.tar.gz >> /tmp/nginx-autoinstall.log 2>&1

			mkdir geoip-db
			cd geoip-db || exit 1
			wget https://geolite.maxmind.com/download/geoip/database/GeoLite2-Country.tar.gz >> /tmp/nginx-autoinstall.log 2>&1
			wget https://geolite.maxmind.com/download/geoip/database/GeoLite2-City.tar.gz >> /tmp/nginx-autoinstall.log 2>&1
			tar -xf GeoLite2-City.tar.gz >> /tmp/nginx-autoinstall.log 2>&1
			tar -xf GeoLite2-Country.tar.gz >> /tmp/nginx-autoinstall.log 2>&1
			geo_dir="/opt/geoip"
			if [[ ! -e $geo_dir ]]; then
				mkdir $geo_dir
			fi
			cd GeoLite2-City_*/
			mv GeoLite2-City.mmdb /opt/geoip/
			cd ../
			cd GeoLite2-Country_*/
			mv GeoLite2-Country.mmdb /opt/geoip/

			if [ $? -eq 0 ]; then
				echo -ne "       Downloading GeoIP databases    [${CGREEN}OK${CEND}]\\r"
				echo -ne "\\n"
			else
				echo -e "       Downloading GeoIP databases    [${CRED}FAIL${CEND}]"
				echo ""
				echo "Please look at /tmp/nginx-autoinstall.log"
				echo ""
				exit 1
			fi
		fi

		# Cache Purge
		if [[ "$CACHEPURGE" = 'y' ]]; then
			cd /usr/local/src/nginx/modules || exit 1
			echo -ne "       Downloading ngx_cache_purge    [..]\\r"
			git clone https://github.com/FRiCKLE/ngx_cache_purge >> /tmp/nginx-autoinstall.log 2>&1

			if [ $? -eq 0 ]; then
				echo -ne "       Downloading ngx_cache_purge    [${CGREEN}OK${CEND}]\\r"
				echo -ne "\\n"
			else
				echo -e "       Downloading ngx_cache_purge    [${CRED}FAIL${CEND}]"
				echo ""
				echo "Please look at /tmp/nginx-autoinstall.log"
				echo ""
				exit 1
			fi
		fi

		# OpenSSL
		OPENSSL=y
		if [[ "$OPENSSL" = 'y' ]]; then
			cd /usr/local/src/nginx/modules || exit 1
			echo -ne "       Downloading OpenSSL            [..]\\r"
			wget https://www.openssl.org/source/openssl-${OPENSSL_VER}.tar.gz >> /tmp/nginx-autoinstall.log 2>&1
			tar xaf openssl-${OPENSSL_VER}.tar.gz
			cd openssl-${OPENSSL_VER}
			curl -s https://raw.githubusercontent.com/hakasenyang/openssl-patch/master/openssl-equal-1.1.1d_ciphers.patch | patch -s -p1
			curl -s https://raw.githubusercontent.com/hakasenyang/openssl-patch/master/openssl-1.1.1d-chacha_draft.patch | patch -s -p1

			if [ $? -eq 0 ]; then
				echo -ne "       Downloading OpenSSL            [${CGREEN}OK${CEND}]\\r"
				echo -ne "\\n"
			else
				echo -e "       Downloading OpenSSL            [${CRED}FAIL${CEND}]"
				echo ""
				echo "Please look at /tmp/nginx-autoinstall.log"
				echo ""
				exit 1
			fi

			echo -ne "       Configuring OpenSSL            [..]\\r"
			./config >> /tmp/nginx-autoinstall.log 2>&1

			if [ $? -eq 0 ]; then
				echo -ne "       Configuring OpenSSL            [${CGREEN}OK${CEND}]\\r"
				echo -ne "\\n"
			else
				echo -e "       Configuring OpenSSL          [${CRED}FAIL${CEND}]"
				echo ""
				echo "Please look at /tmp/nginx-autoinstall.log"
				echo ""
				exit 1
			fi
		fi

		# Download and extract of Nginx source code
		cd /usr/local/src/nginx/ || exit 1
		echo -ne "       Downloading Nginx              [..]\\r"
		wget -qO- http://nginx.org/download/nginx-${NGINX_VER}.tar.gz | tar zxf -
		cd nginx-${NGINX_VER}
		curl -s https://raw.githubusercontent.com/kn007/patch/d6bd9f7e345a0afc88e050a4dd991a57b7fb39be/nginx.patch | patch -s -p1
		curl -s https://raw.githubusercontent.com/hakasenyang/openssl-patch/master/nginx_strict-sni_1.15.10.patch | patch -s -p1

		if [ $? -eq 0 ]; then
			echo -ne "       Downloading Nginx              [${CGREEN}OK${CEND}]\\r"
			echo -ne "\\n"
		else
			echo -e "       Downloading Nginx              [${CRED}FAIL${CEND}]"
			echo ""
			echo "Please look at /tmp/nginx-autoinstall.log"
			echo ""
			exit 1
		fi
		# As the default nginx.conf does not work, we download a clean and working conf from my GitHub.
		# We do it only if it does not already exist, so that it is not overriten if Nginx is being updated
		if [[ ! -e /etc/nginx/nginx.conf ]]; then
			mkdir -p /etc/nginx
			cd /etc/nginx || exit 1
			wget https://raw.githubusercontent.com/Angristan/nginx-autoinstall/master/conf/nginx.conf >> /tmp/nginx-autoinstall.log 2>&1
		fi
		cd /usr/local/src/nginx/nginx-${NGINX_VER} || exit 1

		NGINX_OPTIONS="
		--prefix=/etc/nginx \
		--sbin-path=/usr/sbin/nginx \
		--conf-path=/etc/nginx/nginx.conf \
		--error-log-path=/var/log/nginx/error.log \
		--http-log-path=/var/log/nginx/access.log \
		--pid-path=/var/run/nginx.pid \
		--lock-path=/var/run/nginx.lock \
		--http-client-body-temp-path=/var/cache/nginx/client_temp \
		--http-proxy-temp-path=/var/cache/nginx/proxy_temp \
		--http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
		--user=nginx \
		--group=nginx \
		--with-cc-opt=-Wno-deprecated-declarations"

		NGINX_MODULES="--with-threads \
		--with-file-aio \
		--with-http_ssl_module \
		--with-http_v2_module \
		--with-http_mp4_module \
		--with-http_auth_request_module \
		--with-http_slice_module \
		--with-http_stub_status_module \
		--with-http_realip_module"

		# Optional modules
		if [[ "$LIBRESSL" = 'y' ]]; then
			NGINX_MODULES=$(echo "$NGINX_MODULES"; echo --with-openssl=/usr/local/src/nginx/modules/libressl-${LIBRESSL_VER})
		fi

		if [[ "$PAGESPEED" = 'y' ]]; then
			NGINX_MODULES=$(echo "$NGINX_MODULES"; echo "--add-module=/usr/local/src/nginx/modules/incubator-pagespeed-ngx-${NPS_VER}-stable")
		fi

		if [[ "$BROTLI" = 'y' ]]; then
			NGINX_MODULES=$(echo "$NGINX_MODULES"; echo "--add-module=/usr/local/src/nginx/modules/ngx_brotli")
		fi

		if [[ "$HEADERMOD" = 'y' ]]; then
			NGINX_MODULES=$(echo "$NGINX_MODULES"; echo "--add-module=/usr/local/src/nginx/modules/headers-more-nginx-module-${HEADERMOD_VER}")
		fi

		if [[ "$GEOIP" = 'y' ]]; then
			NGINX_MODULES=$(echo "$NGINX_MODULES"; echo "--add-module=/usr/local/src/nginx/modules/ngx_http_geoip2_module-${GEOIP2_VER}")
		fi

		if [[ "$OPENSSL" = 'y' ]]; then
			NGINX_MODULES=$(echo "$NGINX_MODULES"; echo "--with-openssl=/usr/local/src/nginx/modules/openssl-${OPENSSL_VER}")
		fi

		if [[ "$CACHEPURGE" = 'y' ]]; then
			NGINX_MODULES=$(echo "$NGINX_MODULES"; echo "--add-module=/usr/local/src/nginx/modules/ngx_cache_purge")
		fi

		if [[ "$FANCYINDEX" = 'y' ]]; then
			git clone --quiet https://github.com/aperezdc/ngx-fancyindex.git /usr/local/src/nginx/modules/fancyindex >> /tmp/nginx-autoinstall.log 2>&1
			NGINX_MODULES=$(echo "$NGINX_MODULES"; echo --add-module=/usr/local/src/nginx/modules/fancyindex)
		fi

		echo -ne "       Configuring Nginx              [..]\\r"
		./configure $NGINX_OPTIONS $NGINX_MODULES >> /tmp/nginx-autoinstall.log 2>&1
		
		if [ $? -eq 0 ]; then
			echo -ne "       Configuring Nginx              [${CGREEN}OK${CEND}]\\r"
			echo -ne "\\n"
		else
			echo -e "       Configuring Nginx              [${CRED}FAIL${CEND}]"
			echo ""
			echo "Please look at /tmp/nginx-autoinstall.log"
			echo ""
			exit 1
		fi
		
		echo -ne "       Compiling Nginx                [..]\\r"
		make -j "$(nproc)" >> /tmp/nginx-autoinstall.log 2>&1

		if [ $? -eq 0 ]; then
			echo -ne "       Compiling Nginx                [${CGREEN}OK${CEND}]\\r"
			echo -ne "\\n"
		else
			echo -e "       Compiling Nginx                [${CRED}FAIL${CEND}]"
			echo ""
			echo "Please look at /tmp/nginx-autoinstall.log"
			echo ""
			exit 1
		fi

		echo -ne "       Installing Nginx               [..]\\r"
		make install >> /tmp/nginx-autoinstall.log 2>&1

		# remove debugging symbols
		strip -s /usr/sbin/nginx

		if [ $? -eq 0 ]; then
			echo -ne "       Installing Nginx               [${CGREEN}OK${CEND}]\\r"
			echo -ne "\\n"
		else
			echo -e "       Installing Nginx               [${CRED}FAIL${CEND}]"
			echo ""
			echo "Please look at /tmp/nginx-autoinstall.log"
			echo ""
			exit 1
		fi

		# Nginx installation from source does not add an init script for systemd and logrotate
		# Using the official systemd script and logrotate conf from nginx.org
		if [[ ! -e /lib/systemd/system/nginx.service ]]; then
			cd /lib/systemd/system/ || exit 1
			wget https://raw.githubusercontent.com/Angristan/nginx-autoinstall/master/conf/nginx.service >> /tmp/nginx-autoinstall.log 2>&1
			# Enable nginx start at boot
			systemctl enable nginx >> /tmp/nginx-autoinstall.log 2>&1
		fi

		if [[ ! -e /etc/logrotate.d/nginx ]]; then
			cd /etc/logrotate.d/ || exit 1
			wget https://raw.githubusercontent.com/Angristan/nginx-autoinstall/master/conf/nginx-logrotate -O nginx >> /tmp/nginx-autoinstall.log 2>&1
		fi

		# Nginx's cache directory is not created by default
		if [[ ! -d /var/cache/nginx ]]; then
			mkdir -p /var/cache/nginx
		fi

		# We add the sites-* folders as some use them.
		if [[ ! -d /etc/nginx/sites-available ]]; then
			mkdir -p /etc/nginx/sites-available
		fi
		if [[ ! -d /etc/nginx/sites-enabled ]]; then
			mkdir -p /etc/nginx/sites-enabled
		fi

		# Restart Nginx
		echo -ne "       Restarting Nginx               [..]\\r"
		systemctl restart nginx >> /tmp/nginx-autoinstall.log 2>&1
		
		if [ $? -eq 0 ]; then
			echo -ne "       Restarting Nginx               [${CGREEN}OK${CEND}]\\r"
			echo -ne "\\n"
		else
			echo -e "       Restarting Nginx               [${CRED}FAIL${CEND}]"
			echo ""
			echo "Please look at /tmp/nginx-autoinstall.log"
			echo ""
			exit 1
		fi

		# Block Nginx from being installed via APT
		if [[ $(lsb_release -si) == "Debian" ]] || [[ $(lsb_release -si) == "Ubuntu" ]]
		then
			echo -ne "       Blocking nginx from APT        [..]\\r"
			cd /etc/apt/preferences.d/ || exit 1
			echo -e "Package: nginx*\\nPin: release *\\nPin-Priority: -1" > nginx-block
			echo -ne "       Blocking nginx from APT        [${CGREEN}OK${CEND}]\\r"
			echo -ne "\\n"
		fi

		# Removing temporary Nginx and modules files
		echo -ne "       Removing Nginx files           [..]\\r"
		rm -r /usr/local/src/nginx >> /tmp/nginx-autoinstall.log 2>&1
		echo -ne "       Removing Nginx files           [${CGREEN}OK${CEND}]\\r"
		echo -ne "\\n"

		# We're done !
		echo ""
		echo -e "       ${CGREEN}Installation successful !${CEND}"
		echo ""
		echo "       Installation log: /tmp/nginx-autoinstall.log"
		echo ""
	exit
	;;
	2) # Uninstall Nginx
		while [[ $RM_CONF !=  "y" && $RM_CONF != "n" ]]; do
			read -p "       Remove configuration files ? [y/n]: " -e RM_CONF
		done
		while [[ $RM_LOGS !=  "y" && $RM_LOGS != "n" ]]; do
			read -p "       Remove logs files ? [y/n]: " -e RM_LOGS
		done
		# Stop Nginx
		systemctl stop nginx

		# Removing Nginx files and modules files
		rm -r /usr/local/src/nginx \
		/usr/sbin/nginx* \
		/etc/logrotate.d/nginx \
		/var/cache/nginx \
		/lib/systemd/system/nginx.service \
		/etc/systemd/system/multi-user.target.wants/nginx.service

		# Remove conf files
		if [[ "$RM_CONF" = 'y' ]]; then
			rm -r /etc/nginx/
		fi

		# Remove logs
		if [[ "$RM_LOGS" = 'y' ]]; then
			rm -r /var/log/nginx
		fi

		# Remove Nginx APT block
		if [[ $(lsb_release -si) == "Debian" ]] || [[ $(lsb_release -si) == "Ubuntu" ]]
		then
			rm /etc/apt/preferences.d/nginx-block
		fi

		# We're done !
		echo "Uninstallation done."

	exit
	;;
	3) # Update the script
		wget https://raw.githubusercontent.com/feeeei/nginx-autoinstall/master/nginx-autoinstall.sh -O nginx-autoinstall.sh >> /tmp/nginx-autoinstall.log 2>&1
		chmod +x nginx-autoinstall.sh
		echo ""
		echo "Update done."
		sleep 2
		./nginx-autoinstall.sh
		exit
	;;
	4) # Exit
		exit
	;;

esac

