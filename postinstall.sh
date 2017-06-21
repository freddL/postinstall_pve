#!/bin/bash

##script post-installation pour les serveurs Proxmox sur des machines DELL
##Date : 21/06/2017
##Auteur : Freddy
##Version : 1.0
##Licence : WTFPL (https://fr.wikipedia.org/wiki/WTFPL)

##ajout du dépot pve-no-subscription, DELL et non-free
echo -e '\033[1;33m Ajout du depot pve-no-subscription, DELL et non-free \033[0m'
echo "deb http://download.proxmox.com/debian jessie pve-no-subscription" > /etc/apt/sources.list.d/pve-enterprise.list
echo "deb http://linux.dell.com/repo/community/debian jessie openmanage" > /etc/apt/sources.list.d/linux.dell.com.sources.list

##ajout des dépôts non free
grep 'non-free' /etc/apt/sources.list
if [ $? = "1" ]
then
sed -i "s/main/main\ non-free/g" /etc/apt/sources.list
else
echo "non-free existant"
fi

##ajout proxy pour wget
echo -e '\033[1;33m Ajout du proxy pour wget \033[0m'
sed -i 's/http\:\/\/proxy\.yoyodyne\.com\:18023/http\:\/\/proxy.domaine.tld:8080/g' /etc/wgetrc
sed -i 's/\#https\_proxy/https\_proxy/g' /etc/wgetrc
sed -i 's/\#http\_proxy/http\_proxy/g' /etc/wgetrc
sed -i 's/\#ftp\_proxy/ftp\_proxy/g' /etc/wgetrc
sed -i 's/\#use\_proxy/use\_proxy/g' /etc/wgetrc

##ajout proxy pour apt
echo -e '\033[1;33m Ajout du proxy pour la commande apt \033[0m'
[ -f /etc/apt/apt.conf ]
if [ $? = "1" ]
then
touch /etc/apt/apt.conf
echo 'Acquire::http::Proxy "http://proxy.domaine.tld:8080/";' | tee -a /etc/apt/apt.conf
else
echo "proxy déjà présent"
fi

##Ajout de la clé pour le dépôt DELL
echo -e '\033[1;33m Ajout de la clé pour le dépôt DELL \033[0m'
gpg --list-sigs 1285491434D8786F
if [ $? = 1 ]
then
gpg --keyserver-options http-proxy=http://direct1.proxy.i2:8080 --keyserver hkp://pool.sks-keyservers.net:80 --recv-key 1285491434D8786F
gpg -a --export 1285491434D8786F | apt-key add -
else
echo "clé déjà importée"
fi

##maj proxmox + install divers outils et srvadmin 
echo -e '\033[1;33m Mise a jour du serveur Proxmox \033[0m'
apt update && apt -y full-upgrade && apt -y dist-upgrade
echo -e '\033[1;33m Installation d'outils et d'Openmanage \033[0m'
apt install -y pigz htop iptraf iotop iftop snmpd ntp ncdu ethtool srvadmin-deng-snmp srvadmin-storage-snmp srvadmin-storage srvadmin-storage-cli srvadmin-storageservices srvadmin-idracadm8 srvadmin-base snmp-mibs-downloader --force-yes

##ajout du serveur ntp local
sed -i 's/0.debian.pool.ntp.org/ntp.domaine.tld/g' /etc/systemd/timesyncd.conf
timedatectl set-ntp true
date

##remplacement de gzip par pigz
##pour pigz, je lui attribu que le nombre de tread par cpu 
echo -e '\033[1;33m Remplacement de Gzip par Pigz \033[0m'
touch /bin/pigzwrapper
echo '#!/bin/sh' > /bin/pigzwrapper
echo 'PATH=${GZIP_BINDIR-'/bin'}:$PATH' >> /bin/pigzwrapper
echo 'GZIP="-1"' >> /bin/pigzwrapper
cpu=`echo "$(grep -c "processor" /proc/cpuinfo) / $(grep "physical id" /proc/cpuinfo |sort -u |wc -l)" | bc`
echo 'exec /usr/bin/pigz -p cpu  "$@"'  >> /bin/pigzwrapper
sed -i "s/cpu/"$cpu"/g" /bin/pigzwrapper
chmod +x /bin/pigzwrapper
mv /bin/gzip /bin/gzip.original
cp /bin/pigzwrapper /bin/gzip

##Mise en place des fichiers de conf snmp hébergés sur un serveur web
echo -e '\033[1;33m Mise en place des fichiers de conf pour la supervision \033[0m'
cd /tmp
wget -c --no-proxy http://srv.domaine.tld/script/snmp/snmpd
wget -c --no-proxy http://srv.domaine.tld/script/snmp/snmpd.conf
mv snmpd /etc/default/
mv snmpd.conf /etc/snmp/

##Ajout du relais smtp local 
grep 'smtp.domaine.tld' /etc/postfix/main.cf
if [ $? = "1" ]
then
echo -e '\033[1;33m Ajout de smpt.domaine.tld dans postfix \033[0m'
sed -i '/^relayhost\ =/ s/$/\ smtp.domaine.tld/' /etc/postfix/main.cf
echo -e '\033[1;33m Modification du domaine smptp par domaine.tld dans postfix \033[0m'
sed -i '/^myhostname\=/ s/myhostname=.*/myhostname=domaine.tld/' /etc/postfix/main.cf
else
echo "postfix déjà paramétré"
fi

##Notification par mail de l'installation d'un nouveau serveur Proxmox pour ajout dans la supervision
hostname -f > info.txt
hostname -i >> info.txt
echo "Nouveau serveur Proxmox {hostname -f} vient d'être installé.\n A mettre en supervision le serveur :\n"| mail -s "Nouveau Serveur Proxmox" admin@domaine.tld < info.txt

##supprimer baniere
sed -i.bak 's/NotFound/Active/g' /usr/share/perl5/PVE/API2/Subscription.pm

##modification du bashrc pour notification de connexion ssh avec l'history
echo -e "echo 'Avertissement! Connexion au serveur :' \`hostname\` 'le:' \`date +'%Y/%m/%d'\` \`who | grep -v localhost\` | mail -s \"[ \`hostname\` ] Avertissement!!! connexion au serveur le: \`date +'%Y/%m/%d'\` \`who | grep -v localhost | awk {'print $5'}\`\"admin@domaine.tld\"" >> /etc/bash.bashrc
echo -e "PROMPT_COMMAND='history -a >(logger -t \"\$USER[\$PWD] \$SSH_CONNECTION\")'\"" >> /etc/bash.bashrc

##script Terminer
echo -e '\033[1;33m Terminer et redémarrage du serveur \033[0m'
reboot

exit 0
