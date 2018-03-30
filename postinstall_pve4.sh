#!/bin/bash
echo "########################################################################"
echo " ## script post-installation pour Proxmox 4.4 sur des serveurs DELL  ###"
echo " ### Date : 21/06/2017                                               ###"
echo " ### Auteur : Freddy                                                 ###"
echo " ### Version : 1.0                                                   ###"
echo " ### Licence : WTFPL (https://fr.wikipedia.org/wiki/WTFPL)           ###"
echo "#########################################################################"
echo ""
echo "Veuillez répondre questions suivantes"
echo ""
##set variable
##mail de l'admin
echo "Adresse mail de l'administrateur :"
read adminmail
adminmail=$adminmail

##proxy
echo "Proxy Y/n"
read reponse

if [ $reponse = "Y" ];
then
echo "IP du Proxy"
read proxy
##conf proxy  pour wget
sed -i 's/proxy\.yoyodyne\.com\:18023/'$proxy':8080/g' /etc/wgetrc
sed -i 's/\#https\_proxy/https\_proxy/g' /etc/wgetrc
sed -i 's/\#http\_proxy/http\_proxy/g' /etc/wgetrc
sed -i 's/\#ftp\_proxy/ftp\_proxy/g' /etc/wgetrc
sed -i 's/\#use\_proxy/use\_proxy/g' /etc/wgetrc

touch /etc/apt/apt.conf
echo 'Acquire::http::Proxy "http://proxy:8080/";' > /etc/apt/apt.conf
sed -i 's/proxy/'$proxy'/g' /etc/apt/apt.conf
else
echo "ok pas de proxy"
fi

##serveur ntp
echo "Serveur ntp :"
read ntp
ntp=$ntp

##domaine smtp
echo "Domaine smtp :"
read domainesmtp
domainesmtp=$domainesmtp

##relay smtp
echo "Relay smtp :"
read relaysmtp
relaysmtp=$relaysmtp

echo "Vos réponses :"
echo "votre mail :" $adminmail;
echo "votre proxy :" $proxy;
echo "votre serveur ntp :" $ntp;
echo "votre domaine smtp :" $domainesmtp;
echo "votre relay smtp :" $relaysmtp;

echo -e '\033[1;33m La poste configuration de votre serveur PVE va commencer ... \033[0m'
sleep 3

##ajout du dépot pve-no-subscription, DELL et non-free
echo -e '\033[1;33m Ajout du depot pve-no-subscription, DELL et non-free \033[0m'
echo "deb http://download.proxmox.com/debian jessie pve-no-subscription" > /etc/apt/sources.list.d/pve-enterprise.list
echo "deb http://linux.dell.com/repo/community/debian jessie openmanage" > /etc/apt/sources.list.d/linux.dell.com.sources.list 

grep 'non-free' /etc/apt/sources.list
if [ $? = "1" ]
then
sed -i "s/main/main\ non-free/g" /etc/apt/sources.list
else
echo "non-free existant"
fi

##Ajout de la clé pour le dépôt DELL
echo -e '\033[1;33m Ajout de la clé pour le dépôt DELL \033[0m'
gpg --list-sigs 1285491434D8786F
if [ $? = 1 ]
then
gpg --keyserver-options http-proxy=http://$proxy:8080 --keyserver hkp://pool.sks-keyservers.net:80 --recv-key 1285491434D8786F 
gpg -a --export 1285491434D8786F | apt-key add -
else
echo "clé déjà importée"
fi

##maj proxmox + install outils et srvadmin 
echo -e '\033[1;33m Mise a jour du serveur Proxmox \033[0m'
apt update && apt -y full-upgrade && apt -y dist-upgrade
echo -e '\033[1;33m Installation des outils et OpenManage \033[0m'
apt install -y pigz htop iptraf iotop iftop snmpd ntp ncdu ethtool  snmp-mibs-downloader apticron --force-yes 
apt install -y srvadmin-deng-snmp srvadmin-storage-snmp srvadmin-storage srvadmin-storage-cli srvadmin-storageservices srvadmin-idracadm8 srvadmin-base --force-yes 

##configuration du ntp pour Proxmox 4
sed -i '/^#Server/ s/#Servers=.*/Servers='$ntp'/g' /etc/systemd/timesyncd.conf
timedatectl set-ntp true

##remplacement de gzip par pigz
##pour pigz, je lui attribu que le nombre de tread par cpu 
echo -e '\033[1;33m Remplacement de Gzip par Pigz \033[0m'
touch /bin/pigzwrapper
echo '#!/bin/sh' > /bin/pigzwrapper
echo 'PATH=${GZIP_BINDIR-'/bin'}:$PATH' >> /bin/pigzwrapper
echo 'GZIP="-1"' >> /bin/pigzwrapper
cpu=`echo "$(grep -c "processor" /proc/cpuinfo) / $(grep "physical id" /proc/cpuinfo |sort -u |wc -l)" | bc`
echo 'exec /usr/bin/pigz -p cpu  "$@"'  >> /bin/pigzwrapper
sed -i 's/cpu/'$cpu'/g' /bin/pigzwrapper
chmod +x /bin/pigzwrapper
mv /bin/gzip /bin/gzip.original
cp /bin/pigzwrapper /bin/gzip

##Mise en place des fichiers de conf snmp hébergés ur un serveur web
#echo -e '\033[1;33m Mise en place des fichiers de conf pour la supervision \033[0m'
#cd /tmp
#wget -c --no-proxy http://web.domaine.tld/script/snmp/snmpd
#wget -c --no-proxy http://web.domaine.tld/script/snmp/snmpd.conf
#mv snmpd /etc/default/
#mv snmpd.conf /etc/snmp/

##paramétrage de postfix 
postconf -e "relayhost=${relaysmtp} »
postconf -e "myhostname=${domainesmtp}"
postconf -e "inet_protocols = ipv4"

##Paramétrage du apticron
echo "Ajout pour apticron de la boite mail de l'admin :"
sed -i 's/root/'$adminmail'/g' /etc/apticron/apticron.conf

##Envoie de mail avec le nom et l'IP du nouveau serveur PVE
hostname -f > info.txt
hostname -i >> info.txt
echo "Nouveau serveur Proxmox {hostname -f} vient d'être installé.\n A mettre en supervision le serveur :\n"| mail -s "Nouveau Serveur Proxmox" $adminmail < info.txt 

##supprimer baniere
sed -i.bak 's/NotFound/Active/g' /usr/share/perl5/PVE/API2/Subscription.pm

##modification du bashrc pour notification de connexion ssh avec l'history
echo -e "echo 'Avertissement! Connexion au serveur :' \`hostname\` 'par:' \`who | grep -v localhost\` | mail -s \"[ \`hostname\` ] Avertissement!!! connexion au serveur le: \`date +'%Y/%m/%d'\` \`who | grep -v localhost | awk {'print $5'}\`\"$adminmail\"" >> /etc/bash.bashrc
echo -e "PROMPT_COMMAND='history -a >(logger -t \"\$USER[\$PWD] \$SSH_CONNECTION\")'\"" >> /etc/bash.bashrc

##script Terminer
echo -e '\033[1;33m Terminer, voulez-vous redémarer le serveur maintenant : Y/n \033[0m'
read reponse
if [ $reponse = "Y" ];
then
echo "le serveur va redémarrer"
shutdown -r now
else
echo "le serveur doit être redémarré"
fi
exit 0
