#!/bin/bash

set +o history

dnf update -y

dnf install -y dhcp-server

enp0s9

ip addr add 192.168.1.1/24 dev enp0s9
ip link set enp0s9 up

bash -c 'cat > /etc/dhcp/dhcpd.conf << EOF
subnet 192.168.1.0 netmask 255.255.255.0 {
    range 192.168.1.0 192.168.1.100;
    range 192.168.1.120 192.168.1.254;
    option domain-name-servers 192.168.1.10, 192.168.1.11;
    option domain-name "redos.test";
    option routers 192.168.1.1;
    option broadcast-address 192.168.1.255;
    default-lease-time 600;
    max-lease-time 7200;
}
EOF'

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

bash -c "echo 'DHCPDARGS=enp0s9' > /etc/sysconfig/dhcpd"
systemctl enable --now firewalld
firewall-cmd --permanent --add-service=dhcp
firewall-cmd --reload

systemctl enable --now dhcpd
systemctl start dhcpd

dnf install -y vsftpd

cp /etc/vsftpd/vsftpd.conf /etc/vsftpd/vsftpd.conf.bak

bash -c 'cat > /etc/vsftpd/vsftpd.conf << EOF
anonymous_enable=NO
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
EOF'

useradd -m ftpuser
echo "ftpuser:password123" | sudo chpasswd


firewall-cmd --permanent --add-service=ftp
firewall-cmd --reload


systemctl enable vsftpd
systemctl start vsftpd