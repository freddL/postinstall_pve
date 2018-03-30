# postinstall_pve
Script de post-installation pour Proxmox
plus d'infos : https://memo-linux.com/proxmox-script-post-installation/

Télécharger le script :
git clone https://github.com/freddL/postinstall_pve.git

Se rendre dans le dossier :
cd postinstall_pve/

Dans le dossier se trouve deux script : postinstall_pve4.sh et postinstall_pve5.sh

Pour Proxmox 4 :
Rendre le script éxécutable :
chmod +x postinstall_pve4.sh
Exécuter le script :
./postinstall_ve4.sh

Dans le cas d'un Proxmox 4 en Entreprise derrière un proxy :

https_proxy="http://IP_PROXY:PORT/" wget -c https://raw.githubusercontent.com/freddL/postinstall_pve/master/postinstall_pve4.sh -O postinstall.sh
chmod +x postinstall.sh
./postinstall.sh

Pour Proxmox 5 :
Rendre le script éxécutable :
chmod +x postinstall_pve5.sh
Exécuter le script :
./postinstall_pve5.sh

Dans le cas d'un Proxmox 5 en Entreprise derrière un proxy :
https_proxy="http://IP_PROXY:PORT/" wget -c https://raw.githubusercontent.com/freddL/postinstall_pve/master/postinstall_pve5.sh -O postinstall.sh
chmod +x postinstall.sh
./postinstall.sh


