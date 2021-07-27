############################################################
# Install 3proxy (version 0.6.1, perfect proxy for LEB, supports authentication, easy config)
############################################################
function install_3proxy {

	if [ -z "$1" ]
	then
		die "Usage: `basename $0` install [http-proxy port #]"
	fi
        echo "You have chosen port $http_porty"
	# Build 3proxy
	echo "Downloading and building 3proxy"
	mkdir /tmp/proxy
	cd /tmp/proxy
	wget http://www.3proxy.ru/0.6.1/3proxy-0.6.1.tgz
	tar -xvzf 3proxy-0.6.1.tgz
	rm 3proxy-0.6.1.tgz
	cd 3proxy-0.6.1
	apt-get install build-essential
	make -f Makefile.Linux
	
	# Navigate to 3proxy Install Directory
	cd src
	mkdir /etc/3proxy/
	
	# Move 3proxy program to a non-temporary location and navigate there
	mv 3proxy /etc/3proxy/
	cd /etc/3proxy/
	
	# Create a Log File
	touch /var/log/3proxy.log
	
	# Create basic config that sets up HTTP proxy with user authentication
	touch /etc/3proxy/3proxy.cfg
	
	cat > "/etc/3proxy/3proxy.cfg" <<END
# Specify valid name servers. You can locate them on your VPS in /etc/resolv.conf
#
nserver 8.8.8.8
nserver 8.8.4.4
# Leave default cache size for DNS requests:
#
nscache 65536
# Leave default timeout as well:
#
timeouts 1 5 30 60 180 1800 15 60
# If your server has several IP-addresses, you need to provide an external one
# Alternatively, you may ignore this line
#external YOURSEVERIP
# Provide the IP-address to be listened
# If you ignore this line, proxy will listen all the server.s IP-addresses
#internal YOURSEVERIP
# Create users proxyuser1 and proxyuser2 and specify a password
#
users \$/etc/3proxy/.proxyauth
# Specify daemon as a start mode
#
daemon
# and the path to logs, and log format. Creation date will be added to a log name
log /var/log/3proxy.log
logformat "- +_L%t.%. %N.%p %E %U %C:%c %R:%r %O %I %h %T"
# Compress the logs using gzip
#
archiver gz /usr/bin/gzip %F
# store the logs for 30 days
rotate 30
# Configuring http(s) proxy
#
# enable strong authorization. To disable authentication, simply change to 'auth none'
# added authentication caching to make life easier
authcache user 60
auth strong cache
# and restrict access for ports via http(s)-proxy and deny access to local interfaces
#
deny * * 127.0.0.1,192.168.1.1
allow * * * 80-88,8080-8088 HTTP
allow * * * 443,8443 HTTPS
# run http-proxy ... without ntlm-authorization, complete anonymity and port ...
#
proxy -n -p$1 -a
# Configuring socks5-proxy
#
# enable strong authorization and authentication caching
#
# Purge the access-list of http-proxy and allow certain users
#
# set the maximum number of simultaneous connections to 32
#authcache user 60
#auth strong cache
#flush
#allow userdefined
#socks
END
	
	# Give appropriate permissions for config file
	chmod 600 /etc/3proxy/3proxy.cfg
	
	# Create external user authentication file
	touch /etc/3proxy/.proxyauth
	chmod 600 /etc/3proxy/.proxyauth 
	cat > "/etc/3proxy/.proxyauth" <<END
## addusers in this format:
## user:CL:password
## see for documenation:  http://www.3proxy.ru/howtoe.asp#USERS
END
	
	# Create initialization scripty so 3proxy starts with system
	touch /etc/init.d/3proxy
	chmod  +x /etc/init.d/3proxy
	cat > "/etc/init.d/3proxy" <<END
#!/bin/sh
#
# chkconfig: 2345 20 80
# description: 3proxy tiny proxy server
#
#
#
#

case "\$1" in
   start)
       echo Starting 3Proxy

       /etc/3proxy/3proxy /etc/3proxy/3proxy.cfg
       ;;

   stop)
       echo Stopping 3Proxy
       /usr/bin/killall 3proxy
       ;;

   restart|reload)
       echo Reloading 3Proxy
       /usr/bin/killall -s USR1 3proxy
       ;;
   *)
       echo Usage: \$0 "{start|stop|restart}"
       exit 1
esac
exit 0

END

	# Make sure 3proxy starts with system

	update-rc.d 3proxy defaults	

	# Add Iptable entry for specified port
	echo "Adding necessary iptables-entry"
	iptables -I INPUT -p tcp --dport $1 -j ACCEPT
	if [ -f /etc/iptables.up.rules ];
	then
	iptables-save < /etc/iptables.up.rules
	fi
	echo ''
	echo '3proxy successfully installed, before you can use it you must add a user and password, for proxy authentication. ' 
	echo 'This can be done using the "3proxyauth [user] [password]" it will add the user to the 3proxy auth file. '
	echo 'If you do not want authentication, edit the 3proxy config file /etc/3proxy/3proxy.cfg  and set authentication to none (auth none)'
	echo 'This will leave your http proxy open to anyone and everyone.'
	
	/etc/init.d/3proxy start
	
	echo "3proxy started"
}

function 3proxyauth {

	if [[ -z "$1" || -z "$2" ]]
	then
		die "Usage: `basename $0` auth username password"
	fi
	
	if [ -f /etc/3proxy/.proxyauth ];
	then
	echo "$1:CL:$2" >> "/etc/3proxy/.proxyauth"
	echo "User: $1 successfully added"
	else
	echo "Please install 3proxy (through this script) first."
	fi

}

######################################################################## 
# START OF PROGRAM
########################################################################
export PATH=/bin:/usr/bin:/sbin:/usr/sbin

case "$1" in
install)
	install_3proxy $2
	;;
auth)
	3proxyauth $2 $3
	;;	
*)
	echo '  '
	echo 'Usage:' `basename $0` '[option] [argument]'
	echo '- install   (Install 3proxy - Free tiny proxy server, with authenticatin support, HTTP, SOCKS5 and whatever you can throw at it)'
	echo '- auth      (add users/passwords to your proxy user authentication list)'
	;;
esac

