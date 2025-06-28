#!/bin/bash

set +o history

dnf update -y

dnf install -y dhcp-server

INTERFACE=$(ip route | grep default | awk '{print $5}' | head -n 1)
if [ -z "$INTERFACE" ]; then
    INTERFACE=$(ip link | awk -F: '$0 !~ "lo|vir|^[^0-9]"{print $2;getline}' | head -n 1 | xargs)
fi

read

ip addr add 192.168.1.1/24 dev $INTERFACE
ip link set $INTERFACE up

bash -c 'cat > /etc/dhcp/dhcpd.conf << EOF
subnet 192.168.0.0 netmask 255.255.255.0 {
    range 192.168.0.0 192.168.0.100;
    range 192.168.0.120 192.168.0.254;
    option domain-name-servers 192.168.0.10, 192.168.0.11;
    option domain-name "redos.test";
    option routers 192.168.0.1;
    option broadcast-address 192.168.0.255;
    default-lease-time 600;
    max-lease-time 7200;
}
EOF'

bash -c "cat > /etc/sysconfig/network-scripts/ifcfg-$INTERFACE << EOF
TYPE="Ethernet"
BOOTPROTO="none"
DNS1="192.168.0.1"
IPADDR0="192.168.0.1"
PREFIX0=24
GATEWAY0=192.168.0.1
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
NAME="$INTERFACE"
DEVICE="$INTERFACE"
ON BOOT="yes"
EOF"

bash -c "echo 'DHCPDARGS=$INTERFACE' > /etc/sysconfig/dhcpd"
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