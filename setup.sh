#!/bin/bash

set +o history
LOCAL_USER={$1:-}
FTP_USER={$2:-ftpuser}
FTP_PASS={$2:-ftpuserpass}

dnf update -y
history -s "dnf update -y"

dnf install -y dhcp-server vsftpd ftp
history -s "dnf install -y dhcp-server vsftpd ftp"

ip addr add 192.168.1.1/24 dev enp0s9
history -s "ip addr add 192.168.1.1/24 dev enp0s9"

ip link set enp0s9 up
history -s "ip link set enp0s9 up"

bash -c 'cat > /etc/dhcp/dhcpd.conf << EOF
subnet 192.168.1.0 netmask 255.255.255.0 {
    range 192.168.1.120 192.168.1.254;
    option domain-name-servers 8.8.8.8, 8.8.4.4;
    option domain-name "redos.test";
    option routers 192.168.1.1;
    option broadcast-address 192.168.1.255;
    default-lease-time 600;
    max-lease-time 7200;
}
EOF'
history -s "vi /etc/dhcp/dhcpd.conf"

mkdir -p /etc/sysconfig/network-scripts/
history -s "/etc/sysconfig/network-scripts/"

bash -c "cat > /etc/sysconfig/network-scripts/ifcfg-enp0s9 << EOF
TYPE="Ethernet"
BOOTPROTO="none"
DNS1="192.168.1.1"
IPADDR0="192.168.1.1"
PREFIX0=24
GATEWAY0=192.168.1.1
DEFROUTE="yes"
PEERDNS="yes"
PEERROUTES="yes"
IPV4_FAILURE_FATAL="no"
IPV6INIT="yes"
IPV6_AUTOCONF="yes"
IPV6_DEFROUTE="yes"
IPV6_PEERDNS="yes"
IPV6_PEERROUTES="yes"
IPV6_FAILURE_FATAL="no"
IPV6_ADDR_GEN_MODE="stable-privacy"
NAME="enp0s9"
DEVICE="enp0s9"
ON BOOT="yes"
EOF"
history -s "vi /etc/sysconfig/network-scripts/ifcfg-enp0s9"

bash -c "echo 'DHCPDARGS=enp0s9' > /etc/sysconfig/dhcpd"
history -s "echo 'DHCPDARGS=enp0s9' > /etc/sysconfig/dhcpd"

systemctl enable --now firewalld
history -s "systemctl enable --now firewalld"

firewall-cmd --permanent --add-service=dhcp
history -s "firewall-cmd --permanent --add-service=dhcp"

firewall-cmd --reload
history -s "firewall-cmd --reload"

systemctl enable --now dhcpd
history -s "systemctl enable --now dhcpd"

systemctl restart dhcpd
history -s "systemctl restart dhcpd"

cp /etc/vsftpd/vsftpd.conf /etc/vsftpd/vsftpd.conf.bak
history -s "cp /etc/vsftpd/vsftpd.conf /etc/vsftpd/vsftpd.conf.bak"

bash -c 'cat > /etc/vsftpd/vsftpd.conf << EOF
anonymous_enable=YES
local_enable=YES
write_enable=YES
local_umask=022
dirmessage_enable=YES
xferlog_enable=YES
connect_from_port_20=YES
xferlog_std_format=YES
listen=YES
listen_ipv6=NO
pam_service_name=vsftpd
userlist_enable=YES
tcp_wrappers=YES
user_config_dir=/etc/vsftpd_user_conf
chroot_local_user=YES
allow_writeable_chroot=YES
user_config_dir=/etc/vsftpd_user_conf
EOF'
history -s "vi /etc/vsftpd/vsftpd.conf"

mkdir -p /serv/ftp/anonymous
history -s "mkdir -p /serv/ftp/anonymous"

usermod -d /srv/share/anonymous ftp
history -s "usermod -d /srv/share/anonymous ftp"

mkdir -p /etc/vsftpd_user_conf
history -s "mkdir -p /etc/vsftpd_user_conf"

useradd -m -d /home/$FTP_USER -s /sbin/nologin $FTP_USER
history -s "useradd -m -d /home/$FTP_USER -s /sbin/nologin $FTP_USER"

echo "$FTP_USER:$FTP_USER_PASS" | chpasswd
history -s "$FTP_USER:$FTP_USER_PASS | chpasswd"

bash -c "cat > /etc/vsftpd_user_conf/$FTP_USER << EOF
local_root=/serv/ftp/$FTP_USER
EOF"
history -s "vi /etc/vsftpd_user_conf/$FTP_USER"

if [ -n "$LOCAL_USER" ]; then
    bash -c "cat > /etc/vsftpd_user_conf/$LOCAL_USER << EOF
    local_root=/serv/ftp/$LOCAL_USER
    EOF"
    history -s "vi /etc/vsftpd_user_conf/$LOCAL_USER"
fi

firewall-cmd --permanent --add-service=ftp
history -s "firewall-cmd --permanent --add-service=ftp"

firewall-cmd --reload
history -s "firewall-cmd --reload"

systemctl enable vsftpd --now
history -s "systemctl enable vsftpd --now"

systemctl restart vsftpd
history -s "systemctl restart vsftpd"
