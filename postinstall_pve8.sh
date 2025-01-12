#!/bin/bash
echo "########################################################################"
echo " ## script post-installation pour Proxmox 7.x                        ###"
echo " ### Date : 07/01/2025                                               ###"
echo " ### Modification :                                                  ###"
echo " ### Auteur : fred                                                   ###"
echo " ### web site : https://memo-linux.com                               ###"
echo " ### Version : 1.0                                                   ###"
echo " ### Licence : WTFPL (https://fr.wikipedia.org/wiki/WTFPL)           ###"
echo "########################################################################"
echo ""
echo "Veuillez répondre aux questions suivantes"
echo ""
####initialisation des variables

# local
export LANG="fr_FR.UTF-8"
export LC_ALL="C"

##mail de l'admin
echo "Votre Adresse mail :"
read -r adminmail

##gestion du proxy local
read -r -p "Aves-vous un proxy local ? <Y/n> " prompt
if [[ $prompt == "y" || $prompt == "Y" || $prompt == "yes" || $prompt == "Yes" ]]
then
echo "Votre serveur proxy sans le port (IP ou nom DNS)"
read -r proxy
echo "Port du proxy"
read -r portproxy
else
echo "ok pas de serveur proxy"
noproxy=1
fi

##serveur ntp
echo "Votre serveur ntp :"
read -r ntp

##domaine smtp
echo "Votre domaine d'émission smtp :"
read -r domainesmtp

##relay smtp
echo "Votre relay smtp :"
read -r relaysmtp

#read -r -p "Noeud utilisé pour de la réplication ? <O/N> " prompt
#if [[ $prompt == "N" || $prompt == "n" ]] ; then
#echo -e "${tnorm}"
#sed -i 's/OnCalendar=minutely/OnCalendar=monthly/g' /etc/systemd/system/timers.target.wants/pvesr.timer &>/dev/nul
#sed -i 's/OnCalendar=minutely/OnCalendar=monthly/g' /usr/lib/systemd/system/pvesr.timer &>/dev/nul
#systemctl daemon-reload
#echo "Délai service réplication passé à monthly. Pour vérifier (attendre un peu...) : zgrep replication /var/log/syslog*"
#fi 

echo "Vos réponses :"
echo "votre mail :" "$adminmail";
echo "votre proxy :" "$proxy":"$portproxy";
echo "votre serveur ntp :" "$ntp";
echo "votre domaine smtp :" "$domainesmtp";
echo "votre relay smtp :" "$relaysmtp";
echo -e '\033[1;33m La poste configuration de votre serveur PVE va commencer ... \033[0m'
sleep 3

##conf proxy pour wget at apt 
if [[ "$noproxy" != "1" ]];
then
sed -i 's/proxy\.yoyodyne\.com\:18023/'"$proxy"':8080/g' /etc/wgetrc
sed -i 's/\#https\_proxy/https\_proxy/g' /etc/wgetrc
sed -i 's/\#http\_proxy/http\_proxy/g' /etc/wgetrc
sed -i 's/\#ftp\_proxy/ftp\_proxy/g' /etc/wgetrc
sed -i 's/\#use\_proxy/use\_proxy/g' /etc/wgetrc

echo 'Acquire::http::Proxy "http://'"$proxy"':'"$portproxy"'/";' > /etc/apt/apt.conf.d/76pveproxy
fi

##ajout du dépot pve-no-subscription et non-free
echo -e '\033[1;33m Ajout du depot non-free \033[0m'
grep 'non-free' /etc/apt/sources.list
if [ $? = "1" ]
then
sed -i "s/main/main\\ non-free-firmware/g" /etc/apt/sources.list
else
echo "non-free existant"
fi

echo -e '\033[1;33m Ajout du depot pve-no-subscription \033[0m'
echo "deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription" >> /etc/apt/sources.list
echo "deb http://download.proxmox.com/debian/ceph-reef bookworm no-subscription" > /etc/apt/sources.list.d/ceph.list
rm /etc/apt/sources.list.d/pve-enterprise.list

##maj proxmox + install outils
echo -e '\033[1;33m Mise a jour du serveur Proxmox \033[0m'
apt update && apt full-upgrade -y
echo -e '\033[1;33m Installation des outils \033[0m'
apt install dirmngr htop iptraf-ng iotop iftop snmpd ncdu ethtool apticron net-tools dnsutils ifupdown2 mlocate screen ncdu ntfs-3g ipmitool -y
apt autoremove -y
apt clean

##Configuration du serveur ntp
touch /etc/chrony/sources.d/local-ntp-server.sources
echo "server $ntp iburst" > /etc/chrony/sources.d/local-ntp-server.sources
chronyc reload soucres

##remplacement de gzip par pigz
##pour pigz, je lui attribu que le nombre de tread par cpu
#if [ ! -f "/bin/pigzwrapper" ];then
#echo -e '\033[1;33m Remplacement de Gzip par Pigz \033[0m'
#touch /bin/pigzwrapper
#echo '#!/bin/sh' > /bin/pigzwrapper
#echo "PATH=${GZIP_BINDIR-'/bin'}:$PATH" >> /bin/pigzwrapper
#echo 'GZIP="-1"' >> /bin/pigzwrapper
#cpu=$(echo "$(grep -c "processor" /proc/cpuinfo) / $(grep "physical id" /proc/cpuinfo |sort -u |wc -l)" | bc)
#echo 'exec /usr/bin/pigz -p cpu  "$@"'  >> /bin/pigzwrapper
#sed -i 's/cpu/'"$cpu"'/g' /bin/pigzwrapper
#chmod +x /bin/pigzwrapper
#mv /bin/gzip /bin/gzip.original
#cp /bin/pigzwrapper /bin/gzip
#fi

##paramétrage de postfix 
##pour éviter erreur : error: open database /etc/aliases.db: No such file or directory
newaliases
postconf -e "relayhost=${relaysmtp}"
postconf -e "myhostname=${domainesmtp}"
postconf -e "inet_protocols = ipv4"
postconf compatibility_level=2
postfix reload

#configuraiton du mail pour root
installmail=$(egrep -o '[[:alnum:]_.-]+@[[:alnum:].]+' /etc/pve/user.cfg | grep -v root@pam)
sed -i "s/'"$installmail"'/'"$adminmail"'/" /etc/pve/user.cfg

##Paramétrage du apticron
echo "Ajout pour apticron de la boite mail de l'admin :"
cp /usr/lib/apticron/apticron.conf /etc/apticron/
sed -i 's/root/'"$adminmail"'/g' /etc/apticron/apticron.conf

##Envoie de mail avec le nom et l'IP du nouveau serveur PVE
hostname -f > info.txt
hostname -i >> info.txt
echo "Mettre en supervision ce nouveau serveur Proxmox :" | mail -s "Nouveau Serveur Proxmox" "$adminmail" < info.txt

##suppression baniere
#sed -Ezi.bak "s/(Ext.Msg.show\(\{\s+title: gettext\('No valid sub)/void\(\{ \/\/\1/g" /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js

# creation tache de verification de desactivation de la banniere
#if [ ! -f "/etc/cron.daily/pve-nosub" ];then
#touch /etc/cron.daily/pve-nosub
#echo '#!/bin/sh' > /etc/cron.daily/pve-nosub
#echo "sed -i \"s/data.status.toLowerCase() !== 'active'/false/g\" /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js" >> /etc/cron.daily/pve-nosub
#chmod a+x /etc/cron.daily/pve-nosub
#fi

read -r -p "Terminer, voulez-vous redémarrer le serveur maintenant ? <Y/n> " prompt
if [[ $prompt == "y" || $prompt == "Y" || $prompt == "yes" || $prompt == "Yes" ]]
then
echo "le serveur va redémarrer"
shutdown -r now
else
echo "le serveur doit être redémarré"
fi
exit 0
