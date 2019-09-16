#!/bin/bash
echo "########################################################################"
echo " ## script post-installation pour Proxmox 6 sur des serveurs DELL    ###"
echo " ### Date : 16/09/2019                                               ###"
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
echo "Votre serveur proxy"
read -r proxy
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

echo "Vos réponses :"
echo "votre mail :" "$adminmail";
echo "votre proxy :" "$proxy";
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

touch /etc/apt/apt.conf
echo 'Acquire::http::Proxy "http://proxy:8080/";' > /etc/apt/apt.conf
sed -i 's/proxy/'"$proxy"'/g' /etc/apt/apt.conf
fi

##ajout du dépot pve-no-subscription et non-free
echo -e '\033[1;33m Ajout du depot pve-no-subscription et non-free \033[0m'
echo "deb http://download.proxmox.com/debian buster pve-no-subscription" > /etc/apt/sources.list.d/pve-enterprise.list

grep 'non-free' /etc/apt/sources.list
if [ $? = "1" ]
then
sed -i "s/main/main\\ non-free/g" /etc/apt/sources.list
else
echo "non-free existant"
fi

##maj proxmox + install outils
echo -e '\033[1;33m Mise a jour du serveur Proxmox \033[0m'
apt update && apt -y full-upgrade && apt -y dist-upgrade
echo -e '\033[1;33m Installation des outils \033[0m'
apt install -y  dirmngr pigz htop iptraf iotop iftop snmpd ntp ncdu ethtool snmp-mibs-downloader apticron --force-yes

##Configuration du serveur ntp
sed -i '/^#NTP/ s/#NTP=.*/NTP='"$ntp"'/g' /etc/systemd/timesyncd.conf
apt -y purge ntp
systemctl restart systemd-timesyncd
timedatectl set-ntp true

##remplacement de gzip par pigz
##pour pigz, je lui attribu que le nombre de tread par cpu
echo -e '\033[1;33m Remplacement de Gzip par Pigz \033[0m'
touch /bin/pigzwrapper
echo '#!/bin/sh' > /bin/pigzwrapper
echo "PATH=${GZIP_BINDIR-'/bin'}:$PATH" >> /bin/pigzwrapper
echo 'GZIP="-1"' >> /bin/pigzwrapper
cpu=$(echo "$(grep -c "processor" /proc/cpuinfo) / $(grep "physical id" /proc/cpuinfo |sort -u |wc -l)" | bc)
echo 'exec /usr/bin/pigz -p cpu  "$@"'  >> /bin/pigzwrapper
sed -i 's/cpu/'"$cpu"'/g' /bin/pigzwrapper
chmod +x /bin/pigzwrapper
mv /bin/gzip /bin/gzip.original
cp /bin/pigzwrapper /bin/gzip

##Mise en place des fichiers de conf snmp hébergés ur un serveur web
#echo -e '\033[1;33m Mise en place des fichiers de conf pour la supervision \033[0m'
#wget -c --no-proxy --no-check-certificate https://snmpd.domaine.tld/rep/snmpd
#wget -c --no-proxy --no-check-certificate https://snmpd.domaine.tld/rep/snmpd.conf
#mv snmpd /etc/default/
#mv snmpd.conf /etc/snmp/

##paramétrage de postfix 
postconf -e "relayhost=${relaysmtp}"
postconf -e "myhostname=${domainesmtp}"
postconf -e "inet_protocols = ipv4"
postconf compatibility_level=2
##pour éviter erreur : error: open database /etc/aliases.db: No such file or directory
newaliases
postfix reload

##Paramétrage du apticron
echo "Ajout pour apticron de la boite mail de l'admin :"
cp /usr/lib/apticron/apticron.conf /etc/apticron/
sed -i 's/root/'"$adminmail"'/g' /etc/apticron/apticron.conf

##Envoie de mail avec le nom et l'IP du nouveau serveur PVE
hostname -f > info.txt
hostname -i >> info.txt
echo "Mettre en supervision ce nouveau serveur Proxmox :" | mail -s "Nouveau Serveur Proxmox" "$adminmail" < info.txt

##suppression baniere
sed -i "s/data.status !== 'Active'/false/g" /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js

# creation tache de verification de desactivation de la banniere
touch /etc/cron.daily/pve-nosub.sh
echo "#!/bin/sh" > /etc/cron.daily/pve-nosub.sh
echo "sed -i "s/data.status !== 'Active'/false/g" /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js" >> /etc/cron.daily/pve-nosub.sh
chmod a+x /etc/cron.daily/pve-nosub.sh
  
##modification du bashrc pour notification de connexion ssh avec l'history
echo -e "echo 'Avertissement! Connexion au serveur :' \`hostname\` 'par:' \`who | grep -v localhost\` | mail -s \"[ \`hostname\` ] Avertissement!!! connexion au serveur le: \`date +'%Y/%m/%d'\`  \`who | grep -v localhost | awk {'print $5'}\`$adminmail" >> /etc/bash.bashrc
echo -e "PROMPT_COMMAND='history -a >(logger -t \"\$USER[\$PWD] \$SSH_CONNECTION\")'\"" >> /etc/bash.bashrc
read -r -p "Terminer, voulez-vous redémarrer le serveur maintenant ? <Y/n> " prompt
if [[ $prompt == "y" || $prompt == "Y" || $prompt == "yes" || $prompt == "Yes" ]]
then
echo "le serveur va redémarrer"
shutdown -r now
else
echo "le serveur doit être redémarré"
fi
exit 0
