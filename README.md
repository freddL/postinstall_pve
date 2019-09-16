# postinstall_pve
Script de post-installation pour Proxmox
plus d'infos : https://memo-linux.com/proxmox-script-post-installation/

<ul>
<li>Télécharger le script :</li>
git clone https://github.com/freddL/postinstall_pve.git

<li>Se rendre dans le dossier :
cd postinstall_pve/

Dans le dossier se trouve deux script : postinstall_pve4.sh et postinstall_pve5.sh

<ul>
<li>Pour Proxmox 4 :
<ul>
  <li>Rendre le script éxécutable :</li>
chmod +x postinstall_pve4.sh
  <li>Exécuter le script :</li>
./postinstall_pve4.sh
  </ul></li>
  </ul>
<ul>
<li>Pour Proxmox 5 :
<ul>
  <li>Rendre le script éxécutable :</li>
chmod +x postinstall_pve5.sh
  <li>Exécuter le script :</li>
./postinstall_pve5.sh
  </ul></li>
  
  <li>Pour Proxmox 6 :
<ul>
  <li>Rendre le script éxécutable :</li>
chmod +x postinstall_pve6.sh
  <li>Exécuter le script :</li>
./postinstall_pve6.sh
  </ul></li>
  </ul>
  </li>
  </ul>
  <ul>
  <li>Dans le cas d'un Proxmox 4 en Entreprise derrière un proxy :
    <ul>
      <li>Télécharger le script :</li>
https_proxy="http://IP_PROXY:PORT/" wget -c https://raw.githubusercontent.com/freddL/postinstall_pve/master/postinstall_pve4.sh -O postinstall.sh
      <li>Rendre le script exécutable :</li>
chmod +x postinstall.sh
      <li>Exécuter le script :</li>
./postinstall.sh
    </ul>
  </li>
  
  <li>Dans le cas d'un Proxmox 5 en Entreprise derrière un proxy :
    <ul>
      <li>Télécharger le script :</li>
https_proxy="http://IP_PROXY:PORT/" wget -c https://raw.githubusercontent.com/freddL/postinstall_pve/master/postinstall_pve5.sh -O postinstall.sh
      <li>Rendre le script exécutable :</li>
chmod +x postinstall.sh
      <li>Exécuter le script :</li>
./postinstall.sh
      </ul>
  </li>
  
  <li>Dans le cas d'un Proxmox 6 en Entreprise derrière un proxy :
    <ul>
      <li>Télécharger le script :</li>
https_proxy="http://IP_PROXY:PORT/" wget -c https://raw.githubusercontent.com/freddL/postinstall_pve/master/postinstall_pve6.sh -O postinstall.sh
      <li>Rendre le script exécutable :</li>
chmod +x postinstall.sh
      <li>Exécuter le script :</li>
./postinstall.sh
      </ul>
  </li>
  </ul>
  <ul>
  <li>nb : la syntaxe des scripts testée avec https://www.shellcheck.net/</li>
  </ul>
