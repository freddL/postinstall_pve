# postinstall_pve
Script de post-installation pour Proxmox 4.4
plus d'infos : https://memo-linux.com/proxmox-script-post-installation/

Télécharger le script :
git clone https://github.com/freddL/postinstall_pve.git

Se rendre dans le dossier :
cd postinstall_pve/

Rendre le script éxécutable :
chmod +x postinstall.sh

Exécuter le script :
./postinstall.sh

Dans le cas d'un Proxmox en Entreprise derrière un proxy :

https_proxy="http://Ip_PROXY:PORT/" wget -c https://raw.githubusercontent.com/freddL/postinstall_pve/master/postinstall.sh -O postinstall.sh
chmod +x postinstall.sh
./postinstall.sh
