# cc-mek-scada
Systeme SCADA ComputerCraft configurable pour le controle multi-reacteurs de reacteurs de fission Mekanism, avec interface graphique, securite automatique, pilotage du traitement des dechets, et plus encore.

![GitHub](https://img.shields.io/github/license/MikaylaFischler/cc-mek-scada)
![GitHub release (latest by date including pre-releases)](https://img.shields.io/github/v/release/MikaylaFischler/cc-mek-scada?include_prereleases)
![GitHub Workflow Status (with branch)](https://img.shields.io/github/actions/workflow/status/MikaylaFischler/cc-mek-scada/check.yml?branch=main&label=main)
![GitHub Workflow Status (with branch)](https://img.shields.io/github/actions/workflow/status/MikaylaFischler/cc-mek-scada/check.yml?branch=devel&label=devel)

### Rejoignez le [Discord](https://discord.gg/R9NSCkhcwt) !

![Discord](https://img.shields.io/discord/1129075839288496259?logo=Discord&logoColor=white&label=discord)

## Versions publiees des composants

![Installer](https://img.shields.io/endpoint?url=https%3A%2F%2Fmikaylafischler.github.io%2Fcc-mek-scada%2Finstaller.json)

![Bootloader](https://img.shields.io/endpoint?url=https%3A%2F%2Fmikaylafischler.github.io%2Fcc-mek-scada%2Fbootloader.json)
![Comms](https://img.shields.io/endpoint?url=https%3A%2F%2Fmikaylafischler.github.io%2Fcc-mek-scada%2Fcommon.json)
![Comms](https://img.shields.io/endpoint?url=https%3A%2F%2Fmikaylafischler.github.io%2Fcc-mek-scada%2Fcomms.json)
![Graphics](https://img.shields.io/endpoint?url=https%3A%2F%2Fmikaylafischler.github.io%2Fcc-mek-scada%2Fgraphics.json)
![Lockbox](https://img.shields.io/endpoint?url=https%3A%2F%2Fmikaylafischler.github.io%2Fcc-mek-scada%2Flockbox.json)

![Reactor PLC](https://img.shields.io/endpoint?url=https%3A%2F%2Fmikaylafischler.github.io%2Fcc-mek-scada%2Freactor-plc.json)
![RTU](https://img.shields.io/endpoint?url=https%3A%2F%2Fmikaylafischler.github.io%2Fcc-mek-scada%2Frtu.json)
![Supervisor](https://img.shields.io/endpoint?url=https%3A%2F%2Fmikaylafischler.github.io%2Fcc-mek-scada%2Fsupervisor.json)
![Coordinator](https://img.shields.io/endpoint?url=https%3A%2F%2Fmikaylafischler.github.io%2Fcc-mek-scada%2Fcoordinator.json)
![Pocket](https://img.shields.io/endpoint?url=https%3A%2F%2Fmikaylafischler.github.io%2Fcc-mek-scada%2Fpocket.json)

## Prerequis

Prerequis mods :
- CC: Tweaked
- Mekanism v10.1+

Mods recommandes :
- Advanced Peripherals (ajoute la detection du niveau de radiation environnementale)
- Immersive Engineering (fournit la redstone groupee, ou tout autre mod equivalent)

v10.1+ est requis car le support complet de CC:Tweaked a ete ajoute dans Mekanism v10.1.

## Installation

Vous pouvez installer ce projet sur un ordinateur ComputerCraft avec :
- `wget https://raw.githubusercontent.com/MikaylaFischler/cc-mek-scada/main/ccmsi.lua`
- `pastebin get sqUN6VUb ccmsi.lua`
- Installation hors ligne (HTTP desactive) via les [release bundles](https://github.com/MikaylaFischler/cc-mek-scada/wiki/Alternative-Installation-Strategies#release-bundles)

Utilisation de ce depot comme source d'installation :
- Si vous copiez ce depot complet sur un PC ComputerCraft et lancez `ccmsi`, l'installateur utilise automatiquement les fichiers locaux du depot (`install_manifest.json` + arborescence projet).
- Pour forcer une source distante personnalisee (fork), creez `ccmsi_source.lua` a partir de `ccmsi_source.example.lua`.

## Wiki FR detaille

Un wiki complet en francais est disponible dans le depot :
- [Accueil wiki FR](wiki/fr/README.md)
- [Integration Fusion Mekanism](wiki/fr/04-integration-fusion-mekanism.md)
- [Tests et depannage](wiki/fr/06-tests-validation-depannage.md)

## Contributions

Merci de me contacter via Discord, email, ou GitHub si vous envisagez une contribution.
Ce projet est un challenge personnel, et je souhaite encore garder la maitrise sur les evolutions principales pendant la phase beta.

Une fois la beta terminee, les contributions externes seront plus ouvertes.

## [SCADA](https://en.wikipedia.org/wiki/SCADA)
> Supervisory control and data acquisition (SCADA) est une architecture de controle industriel composee d'ordinateurs, de communications reseau et d'interfaces graphiques pour superviser des machines et des procedes. Elle inclut egalement des capteurs et des automates (PLC) relies aux installations.

Ce projet implemente ces concepts dans ComputerCraft.
Si vous voulez bien comprendre l'architecture, la page Wikipedia SCADA est une bonne base.

![Architecture](https://upload.wikimedia.org/wikipedia/commons/thumb/1/10/Functional_levels_of_a_Distributed_Control_System.svg/1000px-Functional_levels_of_a_Distributed_Control_System.svg.png)

Terminologie utilisee dans le projet :
- Supervisory Computer : collecte les donnees et pilote le procede
- Coordinating Computer : composant IHM/HMI, traite les demandes utilisateur de haut niveau
- RTU : Remote Terminal Unit
- PLC : Programmable Logic Controller

## Architecture ComputerCraft

### Serveur Coordinator

Il ne peut y en avoir qu'un. Ce serveur couvre un role hybride des niveaux 3 et 4 du schema SCADA ci-dessus.
En plus de la supervision sur moniteurs avances, il peut fournir l'acces a un ou plusieurs ordinateurs Pocket.

### Ordinateurs Supervisor

Il doit y en avoir un par installation.
Actuellement, cela veut dire un seul Supervisor.
A terme, plusieurs Supervisors permettraient de coordonner plusieurs installations (fission, fusion, etc.).

### RTU

Les RTU fournissent les entrees/sorties vers le systeme SCADA sans logique locale avancee.
Un seul Advanced Computer peut representer plusieurs RTU : ici, le modele RTU correspond plutot aux modems relies a la machine qu'a la machine elle-meme.
Chaque RTU est reference via un identifiant Modbus, ce qui permet de distribuer les commandes vers plusieurs appareils.

Le code RTU est volontairement generalise :
chaque operation I/O est reliee a une fonction, au lieu de coder les comportements en dur.
Exemple : relier un registre d'entree a `turbine.getFlowRate()` revient a passer la reference de fonction a `connect_input_reg()`.
Ensuite, `read_input_reg()` sur cette adresse execute cette fonction et renvoie la valeur.

### PLC

Les PLC sont des equipements plus evolues qui assurent mesure, commande, et comportements autonomes.
Actuellement, il existe un seul type de PLC : le PLC reacteur.
Il supervise et pilote le reacteur, et applique une securite autonome (RPS) :
il detecte differents dangers et declenche un arret d'urgence si une condition critique est detectee.

Il doit y avoir un PLC par reacteur.
Un Advanced Computer fait office de PLC, relie soit directement, soit via modem cable au port logique du reacteur.

## Communications

Le systeme utilise un protocole inspire de [Modbus](https://en.wikipedia.org/wiki/Modbus) pour communiquer avec les RTU.

Termes utiles :
- Discrete Inputs : bit unique lecture seule (entrees digitales)
- Coils : bit unique lecture/ecriture (I/O digitales)
- Input Registers : registre multi-octets lecture seule (entrees analogiques)
- Holding Registers : registre multi-octets lecture/ecriture (I/O analogiques)

### Securite

Une authentification HMAC des messages est disponible en option pour limiter les attaques de rejeu et la falsification de commandes/donnees sur le reseau.
Cette fonction repose sur [lua-lockbox](https://github.com/somesocks/lua-lockbox).

Une autre securite, plus simple, permet de limiter la distance maximale de transmission autorisee (parametrable par appareil).
