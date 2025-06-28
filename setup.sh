#!/bin/bash

sudo dnf update -y

sudo dnf install -y dhcp-server


INTERFACE=$(ip route | grep default | awk '{print $5}' | head -n 1)
if [ -z "$INTERFACE" ]; then
    INTERFACE=$(ip link | awk -F: '$0 !~ "lo|vir|^[^0-9]"{print $2;getline}' | head -n 1 | xargs)
fi

sudo ip addr add 192.168.1.1/24 dev $INTERFACE
sudo ip link set $INTERFACE up


sudo bash -c 'cat > /etc/dhcp/dhcpd.conf << EOF
default-lease-time 600;
max-lease-time 7200;
authoritative;

log-facility local7;

subnet 192.168.1.0 netmask 255.255.255.0 {
    range 192.168.1.2 192.168.1.2;
    option routers 192.168.1.1;
    option subnet-mask 255.255.255.0;
    option domain-name-servers 8.8.8.8, 8.8.4.4;
}
EOF'


sudo bash -c "echo 'DHCPDARGS=$INTERFACE' > /etc/sysconfig/dhcpd"


sudo systemctl enable dhcpd
sudo systemctl start dhcpd


sudo dnf install -y vsftpd


sudo cp /etc/vsftpd/vsftpd.conf /etc/vsftpd/vsftpd.conf.bak


sudo bash -c 'cat > /etc/vsftpd/vsftpd.conf << EOF
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

sudo useradd -m ftpuser
echo "ftpuser:password123" | sudo chpasswd


sudo firewall-cmd --permanent --add-service=ftp
sudo firewall-cmd --reload


sudo systemctl enable vsftpd
sudo systemctl start vsftpd