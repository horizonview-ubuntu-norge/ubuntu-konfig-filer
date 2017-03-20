#!/bin/bash
# Script for å sette opp statisk IP på DHCP-provisjonerte maskiner
# Krever at ipcalc er installert for å kunne hente ut CIDR-prefiks fra netmask
# Safet Amedov 03/2017 USIT
#
primdns=129.240.2.27
secdns=129.240.2.40
nettkort=$(ls /sys/class/net | grep -v lo)
# Hent IP-addresse fra DNS
ipaddr=$(dig +short $(hostname).uio.no)
# Hent gateway
gateway=$(route | grep default | awk '{print $2}')
netmask=$(ifconfig $nettkort | awk -F: '/Mask:/{print $4;}')
prefiks=$(ipcalc 1.2.3.4 $netmask | awk -F "[ :=]" '/Netmask:/{print $8}')
macaddress=$(cat /sys/class/net/$nettkort/address)
IPmedPrefiks=$(echo "$ipaddr/$prefiks")
GWmedPrefiks=$(echo "$ipaddr/$prefiks")

# Fjern dhcp-oppsett fra interfaces-fila
sed -i '3,6d' /etc/network/interfaces

# Restart Network-Manager
service network-manager restart

# Slå av aktiv device slik at nmcli tilkoblingen "wired connection 1" kan slettes uten
# at det blir opprettet ny
nmcli d disconnect $(nmcli -t -f state,device d | awk -F "[ :]" '/connected:/{print $2}')

# Her opprettes ny nettverkstilkobling
nmcli con add con-name nettverk ifname $nettkort type ethernet ip4 ${IPmedPrefiks} gw4 ${gateway}
nmcli con mod nettverk ipv4.addresses $IPmedPrefiks
nmcli con mod nettverk ipv4.method manual
nmcli con mod nettverk ipv4.dns "${primdns} ${secdns}"
nmcli con mod nettverk ipv4.routes $GWmedPrefiks
nmcli con mod nettverk ipv4.gateway $gateway
nmcli con mod nettverk ethernet.mac-address $macaddress
nmcli con mod nettverk ipv4.dns-search uio.no
nmcli con up nettverk
# Slett alle inaktive nettverkskort
for i in $(nmcli -t -f active,uuid c | awk -F "[ :]" '/no:/ {print $2}'); do nmcli con delete uuid $i ;done
