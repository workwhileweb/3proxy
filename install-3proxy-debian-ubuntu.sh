#
# Install and configure 3proxy for Ubuntu 16.04 or Debian 9
# https://gist.github.com/ansulev/b3e2c821125d072f0f3288d92c94447b
#

# Update the system and install build tools + fail2ban
apt update -y && apt upgrade -y && apt dist-upgrade -y
apt autoremove -y && apt autoclean -y && apt clean -y
apt -y install fail2ban software-properties-common
apt install -y build-essential libevent-dev libssl-dev

# Install and configure 3proxy
wget https://github.com/z3APA3A/3proxy/archive/0.8.12.tar.gz
tar xzvf 0.8.12.tar.gz 
cd 3proxy-0.8.12/
vim src/proxy.h 
...
#define ANONYMOUS 1
#define MAXNSERVERS 20
...
cd ..
mv 3proxy-0.8.12/ /etc/
cd /etc/
mv 3proxy-0.8.12/ 3proxy
cd 3proxy/
make -f Makefile.Linux
make -f Makefile.Linux install
wget https://gettraffic.pro/docs/3proxy.cfg
chmod 700 3proxy.cfg
cd /etc/3proxy/scripts/rc.d/
mv proxy.sh saved-proxy.sh
wget https://gettraffic.pro/docs/proxy.sh
vim proxy.sh
cd /etc/3proxy/
vim 3proxy.cfg

# Start and test the proxy
sh /etc/3proxy/scripts/rc.d/proxy.sh start
netstat -tlnp

# On ubuntu add to start up
vim /etc/rc.local
...
sh /etc/3proxy/scripts/rc.d/proxy.sh start
...
shutdown -r now
# Check after the reboot
ps aux | grep 3proxy

# On Debian need to create rc-local.service
vim /etc/systemd/system/rc-local.service
...
[Unit]
Description=/etc/rc.local
ConditionPathExists=/etc/rc.local

[Service]
Type=forking
ExecStart=/etc/rc.local start
TimeoutSec=0
StandardOutput=tty
RemainAfterExit=yes
SysVStartPriority=99

[Install]
WantedBy=multi-user.target
...

vim /etc/rc.local
...
#!/bin/sh -e
#
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will "exit 0" on success or any other
# value on error.
#
# In order to enable or disable this script just change the execution
# bits.
#
# By default this script does nothing.

exit 0
...

chmod +x /etc/rc.local
systemctl enable rc-local
systemctl start rc-local
systemctl status rc-local

# Add 3proxy start to on boot
vim /etc/rc.local
...
sh /etc/3proxy/scripts/rc.d/proxy.sh start
...
shutdown -r now
# Check after the reboot
ps aux | grep 3proxy

# fix "kernel: Possible SYN flooding on port X. Sending cookies" is logged error
# https://access.redhat.com/solutions/30453
sysctl -w net.core.somaxconn=2048
sysctl -w net.ipv4.tcp_max_syn_backlog  = 512
echo "net.core.somaxconn = 2048" >> /etc/sysctl.conf
echo "net.ipv4.tcp_max_syn_backlog = 512" >> /etc/sysctl.conf
