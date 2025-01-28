# postinstall_pve
Script de post-installation pour Proxmox dans un réseau entreprise/privé non connecté directement à Internet
plus d'infos : https://memo-linux.com/proxmox-script-post-installation/

<ul>
<li>Télécharger le script :</li>
git clone https://github.com/freddL/postinstall_pve.git

<li>Ou téléchargement du script derrière un proxy :</li>
https_proxy="http://IP_PROXY:PORT/" wget -c https://raw.githubusercontent.com/freddL/postinstall_pve/master/postinstall_pve8.sh -O postinstall.sh
      <li>Rendre le script exécutable :</li>
chmod +x postinstall.sh
      <li>Exécuter le script :</li>
./postinstall.sh
    </ul>
  </li>
    <li>nb : la syntaxe des scripts testée avec https://www.shellcheck.net/</li>
  </ul>
