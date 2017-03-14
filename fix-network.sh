#!/bin/bash
# Script for å sette opp statisk IP på DHCP-provisjonerte maskiner
# Safet Amedov 03/2017 USIT
#################

#fjern dhcp-oppsett fra interfaces-fila
sed -i '3,6d' /etc/network/interfaces
# sett nmcli til å manage nettverket
sed -i 's/false/true/' /etc/NetworkManager/NetworkManager.conf


######################################
# Hent all viktig nettverksinfo her  #
######################################
# Hent gammel IP
oldipaddr=`ifconfig | grep inet | sed 's/\:/ /' | awk 'NR==1 {print $3}'`
# Hent IP-addresse fra DNS
ipaddr=$(dig +short $(hostname).uio.no)
# Hent gateway
gateway=$(route | grep default  | awk '{print $2}')
netmask=$(ifconfig ens160 | awk -F: '/Mask:/{print $4;}')
prefixxx=$(ipcalc 1.2.3.4 $netmask | awk -F "[ :=]" '/Netmask:/{print $8}')
#restart network-manager
service network-manager restart
#slå av device
nmcli d disconnect ens160
# slett gammel connection
nmcli connection delete id "Wired connection 1"

ethernetnavn () {
		ls /sys/class/net | grep -v lo
}

hostname=$(hostname)
macaddress=$(cat /sys/class/net/ens160/address)
primdns=129.240.2.27
secdns=129.240.2.40
nettkort=$(ethernetnavn)
ipmedprefiks=$(echo $ipaddr/$prefixxx)
gwmedprefiks=$(echo $ipaddr/$prefixxx)


# adding network card
nmcli con add con-name nettverk ifname $nettkort type ethernet ip4 ${ipmedprefiks} gw4 ${gateway}
nmcli con mod nettverk ipv4.addresses $ipmedprefiks
nmcli con mod nettverk ipv4.method manual
nmcli con mod nettverk ipv4.dns "${primdns} ${secdns}"
nmcli con mod nettverk ipv4.routes $gwmedprefiks
nmcli con mod nettverk ipv4.gateway $gateway
nmcli con mod nettverk ethernet.mac-address $macaddress
nmcli con mod nettverk ipv4.dns-search uio.no
nmcli d connect ens160
#restart network
systemctl restart networking
