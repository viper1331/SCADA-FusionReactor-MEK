--
-- Basic localization helpers
--

---@class i18n
local i18n = {}

local string = string
local tostring = tostring
local type = type

local locale = "fr"

local cache_ui = {}
local cache_console = {}

---@type table<string, string>
local FR_EXACT = {
    -- boot/config console
    ["SCADA BOOTLOADER"] = "DEMARRAGE SCADA",
    ["BOOT> SCANNING FOR APPLICATIONS..."] = "DEMARRAGE> RECHERCHE DES APPLICATIONS...",
    ["BOOT> EXEC REACTOR PLC STARTUP"] = "DEMARRAGE> EXECUTION DU DEMARRAGE PLC REACTEUR",
    ["BOOT> EXEC RTU STARTUP"] = "DEMARRAGE> EXECUTION DU DEMARRAGE RTU",
    ["BOOT> EXEC SUPERVISOR STARTUP"] = "DEMARRAGE> EXECUTION DU DEMARRAGE SUPERVISEUR",
    ["BOOT> EXEC COORDINATOR STARTUP"] = "DEMARRAGE> EXECUTION DU DEMARRAGE COORDINATEUR",
    ["BOOT> EXEC POCKET STARTUP"] = "DEMARRAGE> EXECUTION DU DEMARRAGE POCKET",
    ["BOOT> NO SCADA STARTUP FOUND"] = "DEMARRAGE> AUCUN DEMARRAGE SCADA TROUVE",
    ["BOOT> APPLICATION CRASHED"] = "DEMARRAGE> L'APPLICATION A PLANTE",
    ["CONFIGURE> SCANNING FOR CONFIGURATOR..."] = "CONFIGURATION> RECHERCHE DU CONFIGURATEUR...",
    ["CONFIGURE> NO CONFIGURATOR FOUND"] = "CONFIGURATION> AUCUN CONFIGURATEUR TROUVE",
    ["CONFIGURE> EXIT"] = "CONFIGURATION> SORTIE",

    -- generic/common
    ["monitor too small"] = "moniteur trop petit",
    ["This is monitor"] = "Ceci est le moniteur",
    ["Legacy Options"] = "Options heritees",
    ["Settings saved!"] = "Parametres enregistres !",
    ["Failed to save the settings file."] = "Echec de l'enregistrement du fichier de parametres.",
    ["Failed to save the settings file.\n\nThere may not be enough space for the modification or server file permissions may be denying writes."] = "Echec de l'enregistrement du fichier de parametres.\n\nIl manque peut-etre de l'espace ou les permissions du serveur bloquent l'ecriture.",
    ["Out of space"] = "Espace insuffisant",
    ["DONE"] = "TERMINE",
    ["FAIL"] = "ECHEC",
    ["new!"] = "nouveau !",

    -- main navigation/actions
    ["Configure System"] = "Configurer le systeme",
    ["Configure Gateway"] = "Configurer la passerelle",
    ["View Configuration"] = "Voir la configuration",
    ["View Gateway Configuration"] = "Voir la configuration passerelle",
    ["Color Options"] = "Options de couleur",
    ["Change Log"] = "Journal des changements",
    ["Config Change Log"] = "Journal des changements de config",
    ["Self-Check"] = "Auto-test",
    ["Startup"] = "Demarrage",
    ["Exit"] = "Sortie",
    ["Back"] = "Retour",
    ["\x1b Back"] = "\x1b Retour",
    ["Next \x1a"] = "Suivant \x1a",
    ["Advanced"] = "Avance",
    ["Run Test"] = "Lancer le test",
    ["Revert Changes"] = "Annuler les changements",
    ["Import Legacy 'config.lua'"] = "Importer l'ancien 'config.lua'",
    ["I don't see my device!"] = "Je ne vois pas mon appareil !",
    ["I don't see my relay!"] = "Je ne vois pas mon relais !",
    ["Select one of the below devices to use."] = "Selectionnez un appareil ci-dessous.",
    ["Select one of the below ports to use."] = "Selectionnez un port ci-dessous.",
    ["Please enter a peripheral name."] = "Veuillez saisir un nom de peripherique.",
    ["Please fill out all fields."] = "Veuillez remplir tous les champs.",

    -- headings
    ["Reactor PLC Configurator"] = "Configurateur PLC Reacteur",
    ["RTU Gateway Configurator"] = "Configurateur Passerelle RTU",
    ["Supervisor Configurator"] = "Configurateur Superviseur",
    ["Reactor PLC Self-Check"] = "Auto-test PLC Reacteur",
    ["RTU Gateway Self-Check"] = "Auto-test Passerelle RTU",
    ["PLC Configuration"] = "Configuration PLC",
    ["Network Configuration"] = "Configuration reseau",
    ["Speaker Configuration"] = "Configuration haut-parleur",
    ["Logging Configuration"] = "Configuration journalisation",
    ["Color Configuration"] = "Configuration des couleurs",
    ["Summary"] = "Resume",
    ["Facility Configuration"] = "Configuration installation",
    ["Peripheral Connections"] = "Connexions peripheriques",
    ["Redstone Connections"] = "Connexions redstone",
    ["Import Error"] = "Erreur d'import",
    ["Advanced Options"] = "Options avancees",
    [" Config Change Log"] = " Journal des changements de config",
    [" Reactor PLC Self-Check"] = " Auto-test PLC Reacteur",
    [" RTU Gateway Self-Check"] = " Auto-test Passerelle RTU",
    [" PLC Configuration"] = " Configuration PLC",
    [" Network Configuration"] = " Configuration reseau",
    [" Speaker Configuration"] = " Configuration haut-parleur",
    [" Logging Configuration"] = " Configuration journalisation",
    [" Color Configuration"] = " Configuration des couleurs",
    [" Summary"] = " Resume",
    [" Facility Configuration"] = " Configuration installation",
    [" Peripheral Connections"] = " Connexions peripheriques",
    [" Redstone Connections"] = " Connexions redstone",
    [" Redstone Connections ("] = " Connexions redstone (",
    [" Import Error"] = " Erreur d'import",

    -- startup notices
    ["Welcome to the Reactor PLC configurator! Please select one of the following options."] = "Bienvenue dans le configurateur PLC Reacteur ! Selectionnez une option ci-dessous.",
    ["Welcome to the RTU gateway configurator! Please select one of the following options."] = "Bienvenue dans le configurateur de passerelle RTU ! Selectionnez une option ci-dessous.",
    ["Welcome to the Supervisor configurator! Please select one of the following options."] = "Bienvenue dans le configurateur superviseur ! Selectionnez une option ci-dessous.",
    ["Notice: This device is not configured for this version of the reactor PLC. If you previously had a valid config, it's not lost. You may want to check the Change Log to see what changed."] = "Attention : cet appareil n'est pas configure pour cette version du PLC Reacteur. Votre ancienne configuration valide n'est pas perdue. Consultez le journal des changements pour voir les modifications.",
    ["Notice: This device is not configured for this version of the RTU gateway. If you previously had a valid config, it's not lost. You may want to check the Change Log to see what changed."] = "Attention : cet appareil n'est pas configure pour cette version de la passerelle RTU. Votre ancienne configuration valide n'est pas perdue. Consultez le journal des changements pour voir les modifications.",
    ["Notice: This device is not configured for this version of the supervisor. If you previously had a valid config, it's not lost. You may want to check the Change Log to see what changed."] = "Attention : cet appareil n'est pas configure pour cette version du superviseur. Votre ancienne configuration valide n'est pas perdue. Consultez le journal des changements pour voir les modifications.",

    -- self-check/help
    ["> all tests passed!"] = "> tous les tests sont passes !",
    ["if you still have a problem:"] = "si vous avez encore un probleme :",
    ["- check the wiki on GitHub"] = "- consultez le wiki sur GitHub",
    ["- ask for help on GitHub discussions or Discord"] = "- demandez de l'aide sur GitHub Discussions ou Discord",

    -- common form text
    ["Would you like to set this PLC as networked?"] = "Voulez-vous definir ce PLC en mode reseau ?",
    ["Networked"] = "En reseau",
    ["Please enter the reactor unit ID for this PLC."] = "Veuillez saisir l'ID d'unite reacteur pour ce PLC.",
    ["Unit #"] = "Unite #",
    ["Please set a unit ID."] = "Veuillez definir un ID d'unite.",
    ["Please select the network interface(s)."] = "Veuillez selectionner les interfaces reseau.",
    ["Please set the network channels below."] = "Veuillez definir les canaux reseau ci-dessous.",
    ["Connection Timeout"] = "Delai de connexion",
    ["Trusted Range"] = "Portee de confiance",
    ["Trusted Range (Wireless Only)"] = "Portee de confiance (sans fil uniquement)",
    ["Please set the trusted range."] = "Veuillez definir la portee de confiance.",
    ["Please set the wireless trusted range below."] = "Veuillez definir la portee de confiance sans fil ci-dessous.",
    ["Please set all channels."] = "Veuillez definir tous les canaux.",
    ["Please set all connection timeouts."] = "Veuillez definir tous les delais de connexion.",
    ["Please set the connection timeout."] = "Veuillez definir le delai de connexion.",
    ["Please set the connection timeouts below."] = "Veuillez definir les delais de connexion ci-dessous.",
    ["Please set the supervisor channel."] = "Veuillez definir le canal superviseur.",
    ["Please set the PLC channel."] = "Veuillez definir le canal PLC.",
    ["Please set the RTU channel."] = "Veuillez definir le canal RTU.",
    ["Please set the number of reactors."] = "Veuillez definir le nombre de reacteurs.",
    ["Please enter the number of reactors you have, also referred to as reactor units or 'units' for short. A maximum of 4 is currently supported."] = "Veuillez saisir votre nombre de reacteurs (ou unites). Le maximum pris en charge est 4.",
    ["Please select a modem type."] = "Veuillez selectionner un type de modem.",
    ["Please select a wired modem."] = "Veuillez selectionner un modem cable.",
    ["Please provide a log file path."] = "Veuillez fournir un chemin de fichier journal.",
    ["Please configure logging below."] = "Configurez la journalisation ci-dessous.",
    ["Log File Mode"] = "Mode du fichier journal",
    ["Log File Path"] = "Chemin du fichier journal",
    ["Append on Startup"] = "Ajouter au demarrage",
    ["Replace on Startup"] = "Remplacer au demarrage",
    ["Enable Logging Debug Messages"] = "Activer les messages de debug",
    ["Please set a volume."] = "Veuillez definir un volume.",
    ["Auth Key (Wireless Only, Not Used for Wired)"] = "Cle d'authentification (sans fil uniquement, ignoree en cable)",
    ["Facility Auth Key"] = "Cle auth installation",
    ["Unhide Auth Key"] = "Afficher la cle auth",
    ["Key must be at least 8 characters."] = "La cle doit contenir au moins 8 caracteres.",
    ["seconds (default 5)"] = "secondes (defaut 5)",
    ["[missing]"] = "[manquant]",
    ["<not set>"] = "<non defini>",
    ["[PLC_CHANNEL]"] = "[CANAL_PLC]",
    ["[SVR_CHANNEL]"] = "[CANAL_SVR]",
    [" OK "] = " OK ",

    -- PLC configurator extended
    ["!! CAUTION !!"] = "!! ATTENTION !!",
    ["> check configuration..."] = "> verification configuration...",
    ["> check fission reactor connected..."] = "> verification reacteur a fission connecte...",
    ["> check fission reactor formed..."] = "> verification reacteur a fission forme...",
    ["> check for no more than one reactor..."] = "> verification qu'il n'y a pas plus d'un reacteur...",
    ["> check wired comms modem connected..."] = "> verification modem com cable connecte...",
    ["> check wired supervisor connection..."] = "> verification connexion cable au superviseur...",
    ["> check wireless supervisor connection..."] = "> verification connexion sans fil au superviseur...",
    ["> check wireless/ender modem connected..."] = "> verification modem sans fil/ender connecte...",
    ["> no modem, can't test supervisor connection"] = "> aucun modem, test connexion superviseur impossible",
    ["Added blue indicator color modes"] = "Ajout des modes de couleur d'indicateur bleu",
    ["Added color accessibility modes"] = "Ajout des modes d'accessibilite couleurs",
    ["Added front panel UI theme"] = "Ajout du theme d'interface du panneau frontal",
    ["Added option for fast burn rate ramping in automatic control modes"] = "Ajout d'une option de rampe rapide du debit de combustion en mode automatique",
    ["Added option to invert emergency coolant redstone control"] = "Ajout d'une option pour inverser la commande redstone du refroidissement d'urgence",
    ["Added standard with black off state color mode"] = "Ajout du mode standard avec etat eteint noir",
    ["Added support for wired communications modems"] = "Ajout de la prise en charge des modems de communication cables",
    ["another reactor PLC is connected with this reactor unit ID"] = "un autre PLC reacteur est connecte avec cet ID d'unite reacteur",
    ["AuthKey minimum length is now 8 (if set)"] = "La longueur minimale de AuthKey est maintenant de 8 (si definie)",
    ["Bundled Redstone Configuration"] = "Configuration redstone groupee",
    ["Click 'Accessibility' below to access colorblind assistive options."] = "Cliquez sur 'Accessibilite' ci-dessous pour acceder aux options daltoniennes.",
    ["configurator error: "] = "erreur configurateur : ",
    ["connecting it to peripherals will cause issues"] = "le connecter a des peripheriques causera des problemes",
    ["ConnTimeout can now have a fractional part"] = "ConnTimeout peut maintenant avoir une partie decimale",
    ["Digital I/O is already inverted (or not) based on intended use. If you have a non-standard setup, you can use this option to avoid needing a redstone inverter."] = "Les E/S numeriques sont deja inversees (ou non) selon l'usage prevu. Si votre montage est non standard, utilisez cette option pour eviter un inverseur redstone.",
    ["Don't show this warning again"] = "Ne plus afficher cet avertissement",
    ["Each of the 5 uniquely named channels, including the 2 below, must be the same for each device in this SCADA network. For multiplayer servers, it is recommended to not use the default channels."] = "Chacun des 5 canaux nommes de facon unique, y compris les 2 ci-dessous, doit etre identique sur tous les appareils du reseau SCADA. En multijoueur, il est recommande de ne pas utiliser les canaux par defaut.",
    ["Emergency Coolant Redstone Output Side"] = "Cote de sortie redstone du refroidissement d'urgence",
    ["Enable Fast Ramping"] = "Activer la rampe rapide",
    ["Enable PLC Emergency Coolant Control"] = "Activer le controle PLC du refroidissement d'urgence",
    ["ensure the fission reactor multiblock is formed"] = "assurez-vous que le multibloc reacteur a fission est forme",
    ["error: didn't get an establish reply from supervisor"] = "erreur : aucune reponse d'etablissement du superviseur",
    ["error: invalid reply from supervisor"] = "erreur : reponse invalide du superviseur",
    ["error: invalid reply length from supervisor"] = "erreur : longueur de reponse invalide du superviseur",
    ["error: supervisor connection denied"] = "erreur : connexion superviseur refusee",
    ["error: unknown receive channel"] = "erreur : canal de reception inconnu",
    ["Fast ramping has an increased risk of your reactor running low on coolant and overheating. First test this under supervision, as an insufficient cooling setup or lack of auxiliary coolant can cause the reactor to ramp faster than your turbine(s)/boiler(s) can handle."] = "La rampe rapide augmente le risque de manque de refroidissement et de surchauffe du reacteur. Testez d'abord sous supervision, car un refroidissement insuffisant ou l'absence de refroidissement auxiliaire peut faire monter le reacteur plus vite que vos turbine(s)/chaudiere(s) ne peuvent suivre.",
    ["go through Configure System and apply settings to set any missing settings and repair any corrupted ones"] = "passez par Configurer le systeme et appliquez les parametres pour definir ceux manquants et reparer ceux corrompus",
    ["Here you can select the color theme for the front panel."] = "Vous pouvez selectionner ici le theme de couleur du panneau frontal.",
    ["If this is a networked PLC, currently only IDs 1 through 4 are acceptable."] = "Si ce PLC est en reseau, seuls les ID de 1 a 4 sont actuellement acceptes.",
    ["If you didn't mean to enable this, go back."] = "Si vous ne vouliez pas activer cette option, revenez en arriere.",
    ["If you have a supervisor, select the box. You will later be prompted to select the network configuration. If you instead want to use this as a standalone safety system, don't select the box."] = "Si vous avez un superviseur, cochez la case. Vous serez ensuite invite a choisir la configuration reseau. Si vous voulez utiliser ce PLC comme systeme de securite autonome, ne cochez pas la case.",
    ["In nearly all cases, the automatic SCRAM will still prevent a meltdown if coolant was not lost."] = "Dans presque tous les cas, le SCRAM automatique evitera quand meme une fusion si le refroidissement n'a pas ete perdu.",
    ["Is Bundled?"] = "Mode groupe ?",
    ["Light Blue"] = "Bleu clair",
    ["Light Gray"] = "Gris clair",
    ["make sure your supervisor is running, listening on the wired interface, the wire is intact, and your channels are correct"] = "verifiez que le superviseur est lance, qu'il ecoute sur l'interface cablee, que le cable est intact et que les canaux sont corrects",
    ["make sure your supervisor is running, listening on the wireless interface, your channels are correct, trusted ranges are set properly (if enabled), facility keys match (if set), and if you are using wireless modems rather than ender modems, that your devices are close together in the same dimension"] = "verifiez que le superviseur est lance, qu'il ecoute sur l'interface sans fil, que les canaux sont corrects, que la portee de confiance est correctement reglee (si activee), que les cles installation correspondent (si definies), et si vous utilisez des modems sans fil (non Ender), que les appareils sont proches dans la meme dimension",
    ["Note: exact color varies by theme."] = "Note : la couleur exacte varie selon le theme.",
    ["Optionally, set the facility authentication key below. Do NOT use one of your passwords."] = "Optionnel : definissez ci-dessous la cle d'authentification de l'installation. N'utilisez PAS un de vos mots de passe.",
    ["please connect an ender or wireless modem for wireless comms"] = "connectez un modem Ender ou sans fil pour les communications sans fil",
    ["please connect the reactor PLC to the reactor's fission reactor logic adapter"] = "connectez le PLC reacteur a l'adaptateur logique du reacteur a fission",
    ["please connect the wired comms modem "] = "connectez le modem de communication cable ",
    ["reactor PLC comms version does not match supervisor comms version, make sure both devices are up-to-date (ccmsi update)"] = "la version de communication du PLC reacteur ne correspond pas a celle du superviseur ; assurez-vous que les deux appareils sont a jour (mise a jour ccmsi)",
    ["Setting this to a value larger than 0 prevents wireless connections with devices that many meters (blocks) away in any direction."] = "Regler cette valeur au-dessus de 0 empeche les connexions sans fil avec les appareils situes a cette distance (en metres/blocs) ou plus, dans n'importe quelle direction.",
    ["Slow ramping is always used up to 40 mB/t, which is ~5 mB/t per second. If you enable fast ramping, it will then hold at 40 mB/t until cooled coolant stabilizes (at least 2 seconds) then increase to a faster ramp rate, which is a percentage of the maximum burn rate."] = "La rampe lente est toujours utilisee jusqu'a 40 mB/t, soit environ 5 mB/t par seconde. Si vous activez la rampe rapide, la valeur reste a 40 mB/t jusqu'a stabilisation du refroidissement (au moins 2 secondes), puis augmente selon une rampe plus rapide (pourcentage du debit de combustion maximal).",
    ["Supervisor Channel"] = "Canal superviseur",
    ["The old config.lua file will now be deleted, then the configurator will exit."] = "L'ancien fichier config.lua va maintenant etre supprime, puis le configurateur va se fermer.",
    ["there MUST be no more than one reactor connected, as a PLC uses the first one it finds, which may not always be the same one"] = "il ne DOIT pas y avoir plus d'un reacteur connecte, car un PLC utilise le premier qu'il detecte, ce qui peut varier",
    ["This enables verifying that messages are authentic, so it is intended for wireless security on multiplayer servers. All devices on the same wireless network MUST use the same key if any device has a key. This does result in some extra computation (can slow things down)."] = "Cela permet de verifier l'authenticite des messages, pour la securite sans fil en multijoueur. Tous les appareils d'un meme reseau sans fil DOIVENT utiliser la meme cle si un appareil en utilise une. Cela ajoute un peu de calcul (peut ralentir).",
    ["This independent control can be used with or without a supervisor. To configure, you would next select the interface of the redstone output connected to one or more mekanism pipes."] = "Ce controle independant peut etre utilise avec ou sans superviseur. Pour le configurer, selectionnez ensuite l'interface de sortie redstone connectee a un ou plusieurs tuyaux Mekanism.",
    ["this one MUST ONLY connect to SCADA computers"] = "celui-ci DOIT ETRE connecte UNIQUEMENT a des ordinateurs SCADA",
    ["This results in much larger log files. It is best to only use this when there is a problem."] = "Cela produit des fichiers journaux beaucoup plus volumineux. A utiliser seulement en cas de probleme.",
    ["This system uses color heavily to distinguish ok and not, with some indicators using many colors. By selecting a mode below, indicators will change as shown. For non-standard modes, indicators with more than two colors will be split up."] = "Ce systeme s'appuie fortement sur les couleurs pour distinguer l'etat OK/non OK, avec certains indicateurs multicolores. En selectionnant un mode ci-dessous, les indicateurs changeront comme montre. En mode non standard, les indicateurs a plus de deux couleurs seront separes.",
    ["Tip: you can run a Self-Check from the configurator home screen to make sure everything is going to work right!"] = "Astuce : vous pouvez lancer un auto-test depuis l'ecran d'accueil du configurateur pour verifier que tout fonctionnera correctement !",
    ["When fast ramping is used, if the reactor drops below 80% cooled coolant, it will scale back the ramping proportionally as the coolant level drops."] = "Quand la rampe rapide est activee, si le reacteur passe sous 80% de refroidissement, la rampe est reduite proportionnellement a la baisse.",
    ["When networked, the supervisor takes care of emergency coolant via RTUs. However, you can configure independent emergency coolant via the PLC."] = "En mode reseau, le superviseur gere le refroidissement d'urgence via les RTU. Vous pouvez toutefois configurer un refroidissement d'urgence independant via le PLC.",
    ["You generally do not want or need to modify this. On slow servers, you can increase this to make the system wait longer before assuming a disconnection."] = "En general, vous n'avez pas besoin de modifier ceci. Sur un serveur lent, vous pouvez augmenter cette valeur pour que le systeme attende plus longtemps avant de supposer une deconnexion.",

    -- RTU/Supervisor configurator extended
    ["[RTU_CHANNEL]"] = "[CANAL_RTU]",
    ["[CRD_CHANNEL]"] = "[CANAL_CRD]",
    ["[PKT_CHANNEL]"] = "[CANAL_PKT]",
    ["(required for Pocket)"] = "(requis pour Pocket)",
    ["> check "] = "> verification ",
    ["> check gateway configuration..."] = "> verification configuration passerelle...",
    ["> check redstone "] = "> verification redstone ",
    ["> checking redstone @ "] = "> verification redstone @ ",
    ["> SELECT"] = "> SELECTION",
    [">ALL_WASTE"] = ">TOUS_DECHETS",
    ["bundle..."] = "groupe...",
    ["connected..."] = "connecte...",
    ["connections"] = "connexions",
    ["input..."] = "entree...",
    ["unique..."] = "unique...",
    ["valid..."] = "valide...",
    ["bundled, which will not work"] = "groupe, ce qui ne fonctionnera pas",
    ["bundled entry(s) but this entry is not"] = "entree(s) groupee(s) mais cette entree ne l'est pas",
    ["non-bundled entry(s) but this entry is"] = "entree(s) non groupee(s) mais cette entree l'est",
    ["for the facility."] = "pour l'installation.",
    ["for the facility"] = "pour l'installation",
    ["for unit "] = "pour l'unite ",
    ["a unit)."] = "une unite).",
    ["a Facility Tank"] = "un reservoir installation",
    ["must be a table."] = "doit etre une table.",
    ["will be connected to..."] = "sera connecte a...",
    ["Add +"] = "Ajouter +",
    ["New +"] = "Nouveau +",
    ["Manual +"] = "Manuel +",
    ["Editing "] = "Edition ",
    ["Configure this computer or a redstone relay."] = "Configurez cet ordinateur ou un relais redstone.",
    ["Configuring peripheral on '"] = "Configuration du peripherique sur '",
    ["Create all 4 waste entries"] = "Creer les 4 entrees de dechets",
    ["Input Side"] = "Cote d'entree",
    ["Output Side"] = "Cote de sortie",
    ["Peripheral Name"] = "Nom du peripherique",
    ["Is Connected"] = "Est connecte",
    ["inverted "] = "inverse ",
    ["analog input "] = "entree analogique ",
    ["analog output "] = "sortie analogique ",
    ["digital input "] = "entree numerique ",
    ["digital output "] = "sortie numerique ",
    ["Analog Input: 0-15 redstone power level input\nAnalog Output: 0-15 scaled redstone power level output"] = "Entree analogique : niveau de puissance redstone 0-15\nSortie analogique : niveau redstone mis a l'echelle 0-15",
    ["(Normal) Digital Input: On if there is a redstone signal, off otherwise\nInverted Digital Input: On without a redstone signal, off otherwise"] = "(Normal) Entree numerique : active s'il y a un signal redstone, inactive sinon\nEntree numerique inversee : active sans signal redstone, inactive sinon",
    ["(Normal) Digital Output: Redstone signal to 'turn it on', none to 'turn it off'\nInverted Digital Output: No redstone signal to 'turn it on', redstone signal to 'turn it off'"] = "(Normal) Sortie numerique : signal redstone pour activer, aucun signal pour desactiver\nSortie numerique inversee : aucun signal redstone pour activer, signal redstone pour desactiver",
    ["configuration invalid, please re-configure peripheral entry"] = "configuration invalide, reconfigurez l'entree peripherique",
    ["configuration invalid, please re-configure redstone entry"] = "configuration invalide, reconfigurez l'entree redstone",
    ["invalid peripheral type after type validation"] = "type de peripherique invalide apres validation",
    ["unrecognized device type"] = "type d'appareil non reconnu",
    ["Remember to configure any peripherals or redstone that you have connected to this RTU gateway if you have not already done so, or if you have added, removed, or modified any of them."] = "Pensez a configurer les peripheriques ou redstone relies a cette passerelle RTU si ce n'est pas deja fait, ou si vous en avez ajoute, retire ou modifies.",
    ["If it still does not show, it may not be compatible. Currently only Boilers, Turbines, Dynamic Tanks, SNAs, SPSs, Induction Matricies, and Environment Detectors are supported."] = "S'il n'apparait toujours pas, il est peut-etre incompatible. Actuellement, seuls les chaudieres, turbines, reservoirs dynamiques, SNA, SPS, matrices d'induction et detecteurs d'environnement sont pris en charge.",
    ["Index must be greater than 0."] = "L'index doit etre superieur a 0.",
    ["Index must be 1 or 2."] = "L'index doit etre 1 ou 2.",
    ["Index must be 1, 2, or 3."] = "L'index doit etre 1, 2 ou 3.",
    ["Index must be within 1 to 4."] = "L'index doit etre compris entre 1 et 4.",
    ["induction matrix"] = "matrice d'induction",
    ["Induction Matrix < "] = "Matrice d'induction < ",
    ["Induction Matrix > "] = "Matrice d'induction > ",
    ["Induction Matrix Charge %"] = "Charge matrice d'induction %",
    ["go through Configure Gateway and apply settings to set any missing settings and repair any corrupted ones"] = "passez par Configurer la passerelle et appliquez les parametres pour definir ceux manquants et reparer ceux corrompus",
    ["Facility Acknowledge"] = "Acquittement installation",
    ["Facility Alarm (any)"] = "Alarme installation (toute)",
    ["Facility Alarm (high prio)"] = "Alarme installation (haute priorite)",
    ["Facility SCRAM"] = "SCRAM installation",
    ["Unit Acknowledge"] = "Acquittement unite",
    ["Unit Alarm"] = "Alarme unite",
    ["Unit Auxiliary Cool. Valve"] = "Vanne refroid. auxiliaire unite",
    ["Unit Emergency Cool. Valve"] = "Vanne refroid. urgence unite",
    ["Reactor Active"] = "Reacteur actif",
    ["Reactor Enable"] = "Activation reacteur",
    ["Reactor in Auto Control"] = "Reacteur en controle auto",
    ["Reactor RPS Reset"] = "Reinit RPS reacteur",
    ["Reactor SCRAM"] = "SCRAM reacteur",
    ["RPS Auto SCRAM"] = "RPS SCRAM auto",
    ["RPS Excess Heated Coolant"] = "RPS excedent fluide chauffe",
    ["RPS Excess Waste"] = "RPS excedent dechets",
    ["RPS High Damage"] = "RPS degats eleves",
    ["RPS High Temperature"] = "RPS temperature elevee",
    ["RPS Insufficient Fuel"] = "RPS carburant insuffisant",
    ["RPS Low Coolant"] = "RPS refroidissement faible",
    ["RPS PLC Fault"] = "RPS defaut PLC",
    ["RPS Supervisor Timeout"] = "RPS delai superviseur depasse",
    ["RPS Tripped"] = "RPS declenche",
    ["RTU Gateway Channel"] = "Canal passerelle RTU",
    ["RTU Gateway Timeout"] = "Delai passerelle RTU",
    ["Redstone Relay"] = "Relais redstone",
    ["Speakers can be connected to this RTU gateway without RTU unit configuration entries."] = "Des haut-parleurs peuvent etre connectes a cette passerelle RTU sans entree de configuration d'unite RTU.",
    ["This allows remotely playing alarm sounds."] = "Cela permet de lire les sons d'alarme a distance.",
    ["This Computer"] = "Cet ordinateur",
    ["What's that?"] = "Qu'est-ce que c'est ?",
    ["With a wireless modem, configure Pocket access."] = "Avec un modem sans fil, configurez l'acces Pocket.",
    ["please connect this device via a wired modem or direct contact and ensure the configuration matches what it connects as"] = "connectez cet appareil via un modem cable ou un contact direct et verifiez que la configuration correspond au role connecte",
    ["Make sure your device is either touching the RTU or connected via wired modems. There should be a wired modem on a side of the RTU then one on the device, connected by a cable. The modem on the device needs to be right clicked to connect it (which will turn its border red), at which point the peripheral name will be shown in the chat."] = "Assurez-vous que l'appareil touche le RTU ou est relie via des modems cables. Il doit y avoir un modem cable sur un cote du RTU et un sur l'appareil, relies par un cable. Le modem de l'appareil doit etre clique droit pour se connecter (bordure rouge), puis le nom du peripherique apparait dans le chat.",
    ["Make sure your relay is either touching the RTU gateway or connected via wired modems. There should be a wired modem on a side of the RTU gateway then one on the device, connected by a cable. The modem on the device needs to be right clicked to connect it (which will turn its border red), at which point the peripheral name will be shown in the chat."] = "Assurez-vous que le relais touche la passerelle RTU ou est relie via des modems cables. Il doit y avoir un modem cable sur un cote de la passerelle RTU et un sur l'appareil, relies par un cable. Le modem de l'appareil doit etre clique droit pour se connecter (bordure rouge), puis le nom du peripherique apparait dans le chat.",
    ["only one port should be set to a side/color combination"] = "un seul port doit etre defini pour une combinaison cote/couleur",
    ["this side has "] = "ce cote a ",
    ["you cannot have multiple of the same input for a given unit or the facility ("] = "vous ne pouvez pas avoir plusieurs fois la meme entree pour une unite donnee ou l'installation (",
    ["You already configured this input for this facility/unit assignment. There can only be one entry for each input per each unit or the facility (for facility inputs).\n\nPlease select a different port."] = "Cette entree est deja configuree pour cette affectation installation/unite. Il ne peut y avoir qu'une seule entree par input et par unite (ou installation pour les inputs installation).\n\nSelectionnez un autre port.",
    ["Warning!\n\nSome of the devices in your old config file aren't currently connected. If the device isn't connected, the options can't be properly validated. Please either connect your devices and try again or complete the import without validation on those entry's settings."] = "Attention !\n\nCertains appareils de votre ancien fichier de config ne sont pas connectes actuellement. Si un appareil n'est pas connecte, les options ne peuvent pas etre validees correctement. Connectez les appareils et reessayez, ou terminez l'import sans validation pour ces entrees.",
    ["Warning: too many devices on one RTU Gateway can cause lag. Note that 10x the \"PEAK\x1a\" rate on the flow monitor gives you the mB/t of waste that the SNA(s) can process. Enough SNAs to provide 2x to 3x of that unit's max burn rate should be a good margin to catch up after night or cloudy weather."] = "Attention : trop d'appareils sur une passerelle RTU peuvent causer du lag. Notez que 10x le taux \"PEAK\x1a\" sur le moniteur de flux donne le mB/t de dechets que les SNA peuvent traiter. Prevoir assez de SNA pour 2x a 3x le debit de combustion max de l'unite offre une bonne marge apres la nuit ou un temps nuageux.",
    ["Waste Plutonium Valve"] = "Vanne de dechets plutonium",
    ["Waste Polonium Valve"] = "Vanne de dechets polonium",
    ["Waste Po Pellets Valve"] = "Vanne de dechets pellets Po",
    ["Waste Antimatter Valve"] = "Vanne de dechets antimatiere",
    ["The following peripherals will be imported:"] = "Les peripheriques suivants seront importes :",
    ["The following redstone entries will be imported:"] = "Les entrees redstone suivantes seront importees :",
    ["There is a problem with your config.lua file:"] = "Il y a un probleme avec votre fichier config.lua :",
    ["Re-organized peripheral configuration UI, resulting in some input fields being re-ordered"] = "Reorganisation de l'interface de configuration des peripheriques, avec reordonnancement de certains champs",
    ["Added advanced option to invert digital redstone signals"] = "Ajout d'une option avancee pour inverser les signaux redstone numeriques",
    ["Added support for redstone relays"] = "Ajout de la prise en charge des relais redstone",
    ["RTU gateway comms version does not match supervisor comms version, make sure both devices are up-to-date (ccmsi update)"] = "la version de communication de la passerelle RTU ne correspond pas a celle du superviseur ; assurez-vous que les deux appareils sont a jour (mise a jour ccmsi)",
    ["Reactor PLC\nRTU Gateway\nCoordinator"] = "PLC Reacteur\nPasserelle RTU\nCoordinateur",

    -- Supervisor facility configuration
    ["Added option for allowing Pocket connections"] = "Ajout d'une option autorisant les connexions Pocket",
    ["Added option for allowing Pocket test commands"] = "Ajout d'une option autorisant les commandes de test Pocket",
    ["Added sodium emergency coolant option"] = "Ajout d'une option de refroidissement d'urgence sodium",
    ["Alternatively, you can configure them as facility tanks to connect to multiple reactor units. These can intermingle with unit-specific tanks."] = "Vous pouvez aussi les configurer en reservoirs installation pour les relier a plusieurs unites reacteur. Ils peuvent etre combines avec des reservoirs specifiques a une unite.",
    ["Auxiliary Water Coolant"] = "Refroidissement auxiliaire a eau",
    ["Auxiliary water coolant can be enabled for units to provide extra water during turbine ramp-up. For water cooled reactors, this goes to the reactor. For sodium cooled reactors, water goes to the boiler."] = "Le refroidissement auxiliaire a eau peut etre active pour fournir de l'eau supplementaire pendant la montee en regime des turbines. Pour un reacteur refroidi a l'eau, l'eau va au reacteur. Pour un reacteur refroidi au sodium, l'eau va a la chaudiere.",
    ["Charge control provides automatic control to maintain an induction matrix charge level. In order to have smoother control, reactors that were activated will be held on at 0.01 mB/t for a short period before allowing them to turn off. This minimizes overshooting the charge target."] = "Le controle de charge maintient automatiquement le niveau de charge de la matrice d'induction. Pour lisser la regulation, les reacteurs actives sont maintenus a 0.01 mB/t pendant un court instant avant extinction. Cela limite le depassement de la cible.",
    ["connected to facility tank "] = "connecte au reservoir installation ",
    ["connected to its unit tank ("] = "connecte a son reservoir unite (",
    ["Connected to: "] = "Connecte a : ",
    ["Connected to: Unit "] = "Connecte a : Unite ",
    ["Cooling Configuration"] = "Configuration de refroidissement",
    ["Cooling configuration for unit "] = "Configuration de refroidissement pour l'unite ",
    ["Cooling configuration table length must match the number of units."] = "La longueur du tableau de configuration de refroidissement doit correspondre au nombre d'unites.",
    ["Coordinator Channel"] = "Canal coordinateur",
    ["Coordinator Timeout"] = "Delai coordinateur",
    ["Each of the 5 uniquely named channels must be the same for each device in this SCADA network. For multiplayer servers, it is recommended to not use the default channels."] = "Chacun des 5 canaux nommes de facon unique doit etre identique sur chaque appareil du reseau SCADA. En multijoueur, il est recommande de ne pas utiliser les canaux par defaut.",
    ["Enable Extended Idling"] = "Activer ralenti etendu",
    ["Enable Pocket Access"] = "Activer acces Pocket",
    ["Enable Pocket Remote System Testing"] = "Activer test systeme distant Pocket",
    ["Examples: A U2 tank should be configured on an RTU as the dynamic tank for unit #2. An F3 tank should be configured on an RTU as the #3 dynamic tank for the facility."] = "Exemples : un reservoir U2 doit etre configure sur un RTU comme reservoir dynamique de l'unite #2. Un reservoir F3 doit etre configure sur un RTU comme reservoir dynamique #3 de l'installation.",
    ["Extended Charge Idling"] = "Ralenti de charge etendu",
    ["Facility Tank "] = "Reservoir installation ",
    ["Facility Tank Connections"] = "Connexions reservoir installation",
    ["Facility Tank Definitions"] = "Definitions reservoir installation",
    ["Facility tank definitions table length must match the number of units when using facility tanks."] = "La longueur du tableau de definitions des reservoirs installation doit correspondre au nombre d'unites lors de leur utilisation.",
    ["Facility Tank List"] = "Liste des reservoirs installation",
    ["Facility Tank Mode"] = "Mode reservoir installation",
    ["Facility Tanks             Unit Tanks"] = "Reservoirs installation     Reservoirs unite",
    ["Has Auxiliary Coolant"] = "Refroidissement auxiliaire present",
    ["has tank conn"] = "a une connexion reservoir",
    ["If you already configured your coordinator, make sure you update the coordinator's configured unit count."] = "Si votre coordinateur est deja configure, mettez a jour son nombre d'unites configure.",
    ["Invalid tank mode present in config. FAC_TANK_MODE must be a number 0 through 8."] = "Mode de reservoir invalide dans la config. FAC_TANK_MODE doit etre un nombre de 0 a 8.",
    ["its own Unit Tank"] = "son propre reservoir unite",
    ["Mode 1"] = "Mode 1",
    ["Mode 2"] = "Mode 2",
    ["Mode 3"] = "Mode 3",
    ["Mode 4"] = "Mode 4",
    ["Mode 5"] = "Mode 5",
    ["Mode 6"] = "Mode 6",
    ["Mode 7"] = "Mode 7",
    ["Mode 8"] = "Mode 8",
    ["no auxiliary coolant"] = "pas de refroidissement auxiliaire",
    ["no emergency coolant tanks"] = "pas de reservoirs de refroidissement d'urgence",
    ["no facility tanks"] = "pas de reservoirs installation",
    ["no tank (as you set two steps ago)"] = "pas de reservoir (comme defini deux etapes plus tot)",
    ["no tank conn"] = "pas de connexion reservoir",
    ["not connected to a tank"] = "non connecte a un reservoir",
    ["Number of Reactors"] = "Nombre de reacteurs",
    ["PLC Timeout"] = "Delai PLC",
    ["Please assign device connection interfaces if you selected multiple network interfaces."] = "Veuillez affecter les interfaces de connexion des appareils si vous avez selectionne plusieurs interfaces reseau.",
    ["Please provide the reactor cooling configuration below. This includes the number of turbines, boilers, and if that reactor has a connection to a dynamic tank for emergency coolant."] = "Veuillez fournir ci-dessous la configuration de refroidissement du reacteur. Cela inclut le nombre de turbines, de chaudieres, et si ce reacteur est connecte a un reservoir dynamique pour le refroidissement d'urgence.",
    ["Please select your dynamic tank layout."] = "Veuillez selectionner votre agencement de reservoirs dynamiques.",
    ["Please set unit connections to dynamic tanks, selecting at least one facility tank. The layout for facility tanks will be configured next."] = "Veuillez definir les connexions des unites aux reservoirs dynamiques, en selectionnant au moins un reservoir installation. L'agencement des reservoirs installation sera configure ensuite.",
    ["seconds\nseconds\nseconds\nseconds"] = "secondes\nsecondes\nsecondes\nsecondes",
    ["Some modes may look the same if you are not using 4 total reactor units. The wiki has details. Modes that look the same will function the same."] = "Certains modes peuvent sembler identiques si vous n'utilisez pas 4 unites reacteur. Le wiki donne les details. Les modes visuellement identiques se comportent pareil.",
    ["Specify each tank's coolant type, for display use only. Water is the only option if one or more of the connected units is water cooled."] = "Indiquez le type de fluide de chaque reservoir, pour affichage uniquement. L'eau est la seule option si une ou plusieurs unites connectees sont refroidies a l'eau.",
    ["tank %s - %s"] = "reservoir %s - %s",
    ["Tank ?"] = "Reservoir ?",
    ["Tank F"] = "Reservoir F",
    ["Tank F1"] = "Reservoir F1",
    ["Tank Fluid Types"] = "Types de fluide des reservoirs",
    ["Tank U"] = "Reservoir U",
    ["Unit "] = "Unite ",
    ["unit %d"] = "unite %d",
    ["UNIT    TURBINES   BOILERS   HAS TANK CONNECTION?"] = "UNITE   TURBINES   CHAUDIERES   CONNEXION RESERVOIR ?",
    ["Unit 1\n\nUnit 2\n\nUnit 3\n\nUnit 4"] = "Unite 1\n\nUnite 2\n\nUnite 3\n\nUnite 4",
    ["Unit Tank "] = "Reservoir unite ",
    ["Use Facility Dynamic Tanks"] = "Utiliser des reservoirs dynamiques installation",
    ["Wired Only"] = "Cable uniquement",
    ["Wireless and Wired"] = "Sans fil et cable",
    ["Wireless Only"] = "Sans fil uniquement",
    ["Afterwards, either (a) edit then save entries for currently disconnected devices to properly configure or (b) delete those entries."] = "Ensuite, soit (a) modifiez puis enregistrez les entrees des appareils actuellement deconnectes pour les configurer correctement, soit (b) supprimez ces entrees.",
    ["Each reactor unit can have at most 1 tank and the facility can have at most 4. Each facility tank must have a unique # 1 through 4, regardless of where it is connected. Only a total of 4 tanks can be displayed on the flow monitor."] = "Chaque unite reacteur peut avoir au maximum 1 reservoir et l'installation au maximum 4. Chaque reservoir installation doit avoir un numero unique de 1 a 4, peu importe ou il est connecte. Un total de 4 reservoirs seulement peut etre affiche sur le moniteur de flux.",
    ["Each unit can have at most 2 boilers. Boiler #1 shows up first on the main display, followed by boiler #2 below it. The numberings are per unit (unit 1 and unit 2 would both have a boiler #1 if each had one boiler) and can be split amongst multiple RTUs (one has #1, another has #2)."] = "Chaque unite peut avoir au maximum 2 chaudieres. La chaudiere #1 apparait d'abord sur l'affichage principal, puis la chaudiere #2 en dessous. La numerotation est par unite (les unites 1 et 2 peuvent chacune avoir une chaudiere #1) et peut etre repartie entre plusieurs RTU (l'un a #1, l'autre #2).",
    ["Each unit can have at most 3 turbines. Turbine #1 shows up first on the main display, followed by #2 then #3 below it. The numberings are per unit (unit 1 and unit 2 would both have a turbine #1) and can be split amongst multiple RTUs (one has #1, another has #2)."] = "Chaque unite peut avoir au maximum 3 turbines. La turbine #1 apparait d'abord sur l'affichage principal, puis #2 et #3 en dessous. La numerotation est par unite (les unites 1 et 2 peuvent chacune avoir une turbine #1) et peut etre repartie entre plusieurs RTU (l'un a #1, l'autre #2).",
    ["Note: alarm sine waves are at half scale so that multiple will be required to reach full scale."] = "Note : les ondes sinus d'alarme sont a mi-echelle, il en faut donc plusieurs pour atteindre l'echelle complete.",
    ["reactor unit #"] = "unite reacteur #",
    ["the facility"] = "l'installation",
    ["the facility)."] = "l'installation).",
    ["for the facility. There must only be one of these across all the RTUs you have."] = "pour l'installation. Il ne doit y en avoir qu'un seul sur l'ensemble de vos RTU.",
    ["There can only be one of these devices per SCADA network, so it will be assigned as the sole "] = "Il ne peut y avoir qu'un seul de ces appareils par reseau SCADA, il sera donc affecte comme unique ",
    ["This feature is intended for advanced users. If you just can't see your device, click 'I don't see my device!' instead."] = "Cette fonction est destinee aux utilisateurs avances. Si vous ne voyez simplement pas votre appareil, cliquez plutot sur 'Je ne vois pas mon appareil !'.",
    ["This is reactor unit #    's #     boiler."] = "Ceci est la chaudiere #     de l'unite reacteur #    .",
    ["This is reactor unit #    's #     turbine."] = "Ceci est la turbine #     de l'unite reacteur #    .",
    ["This is the "] = "Ceci est le ",
    ["This is the below system's #     dynamic tank."] = "Ceci est le reservoir dynamique #     du systeme ci-dessous.",
    ["This is the below system's #     env. detector."] = "Ceci est le detecteur env. #     du systeme ci-dessous.",
    ["This shortcut will add entries for each of the 4 waste outputs. If you select bundled, 4 colors will be assigned to the selected side. Otherwise, 4 default sides will be used."] = "Ce raccourci ajoute des entrees pour chacune des 4 sorties de dechets. Si vous selectionnez le mode groupe, 4 couleurs seront affectees au cote choisi. Sinon, 4 cotes par defaut seront utilises.",
    ["This SNA is for reactor unit #    ."] = "Ce SNA est pour l'unite reacteur #    .",
    ["port          side/color       unit/facility"] = "port          cote/couleur      unite/installation",
    ["<disconnected> (connect to edit)"] = "<deconnecte> (connecter pour modifier)",
    ["This is optional. You can disable this functionality by setting the value to 0."] = "Ceci est optionnel. Vous pouvez desactiver cette fonctionnalite en definissant la valeur a 0.",
    ["This visualization tool shows the pipe connections required for a particular dynamic tank configuration you have selected."] = "Cet outil de visualisation montre les connexions de tuyaux requises pour la configuration de reservoir dynamique que vous avez selectionnee.",
    ["You can extend this to a full minute to minimize reactors flickering on/off, but there may be more overshoot of the target."] = "Vous pouvez monter jusqu'a une minute complete pour reduire les basculements marche/arret des reacteurs, mais le depassement de la cible peut augmenter.",
    ["You generally should not need to modify these. On slow servers, you can try to increase this to make the system wait longer before assuming a disconnection. The default for all is 5 seconds."] = "En general, vous ne devriez pas avoir besoin de modifier ces valeurs. Sur des serveurs lents, vous pouvez tenter de les augmenter pour que le systeme attende plus longtemps avant de supposer une deconnexion. La valeur par defaut est 5 secondes pour toutes.",
    ["You have set one or more of your units to use dynamic tanks for emergency coolant. You have two paths for configuration. The first is to assign dynamic tanks to reactor units; one tank per reactor, only connected to that reactor. RTU configurations must also assign it as such."] = "Vous avez configure une ou plusieurs unites pour utiliser des reservoirs dynamiques en refroidissement d'urgence. Deux options de configuration existent. La premiere consiste a affecter des reservoirs dynamiques aux unites reacteur ; un reservoir par reacteur, connecte uniquement a ce reacteur. Les configurations RTU doivent aussi le definir ainsi.",
    ["You selected no facility tanks."] = "Vous n'avez selectionne aucun reservoir installation.",
    [" tried to generate a summary without a phy set"] = " tentative de generation d'un resume sans phy defini",
    [" tried to save a redstone entry without a phy"] = " tentative de sauvegarde d'une entree redstone sans phy",
    ["tried to generate a summary without a phy set"] = "tentative de generation d'un resume sans phy defini",
    ["tried to save a redstone entry without a phy"] = "tentative de sauvegarde d'une entree redstone sans phy",
    ["unit "] = "unite ",
    ["Unit ID invalid."] = "ID d'unite invalide.",
    ["Unit ID must be within 1 to 4."] = "L'ID d'unite doit etre compris entre 1 et 4.",
    ["You can change the speaker audio volume from the default. The range is 0.0 to 3.0, where 1.0 is standard volume."] = "Vous pouvez modifier le volume audio du haut-parleur. La plage va de 0.0 a 3.0, avec 1.0 comme volume standard.",
    ["You can connect more than one environment detector for a particular unit or the facility. In that case, the maximum radiation reading from those assigned to that particular unit or the facility will be used for alarms and display."] = "Vous pouvez connecter plus d'un detecteur d'environnement pour une unite donnee ou l'installation. Dans ce cas, la lecture de radiation maximale des detecteurs affectes a cette unite (ou a l'installation) sera utilisee pour les alarmes et l'affichage.",
    ["You selected the "] = "Vous avez selectionne ",
    ["You selected the ALL_WASTE shortcut."] = "Vous avez selectionne le raccourci ALL_WASTE.",
    [" bundle..."] = " groupe...",
    [" bundled, which will not work"] = " groupe, ce qui ne fonctionnera pas",
    [" connected..."] = " connecte...",
    [" connections"] = " connexions",
    [" for the facility."] = " pour l'installation.",
    [" for the facility. There must only be one of these across all the RTUs you have."] = " pour l'installation. Il ne doit y en avoir qu'un seul sur l'ensemble de vos RTU.",
    [" input..."] = " entree...",
    [" port          side/color       unit/facility"] = " port          cote/couleur      unite/installation",
    [" unique..."] = " unique...",
    [" valid..."] = " valide...",
    ["@ local"] = "@ local",
    ["[in]"] = "[entree]",
    ["[out]"] = "[sortie]",
    ["[n/a]"] = "[n/d]",
    [" must be a table."] = " doit etre une table.",
    [" will be connected to..."] = " sera connecte a...",

    -- setting labels
    ["Unit ID"] = "ID unite",
    ["Fast Ramp"] = "Rampe rapide",
    ["Fast Ramp Confirmed"] = "Rampe rapide confirmee",
    ["Emergency Coolant"] = "Refroidissement d'urgence",
    ["Emergency Coolant Side"] = "Cote du refroidissement d'urgence",
    ["Emergency Coolant Color"] = "Couleur du refroidissement d'urgence",
    ["Emergency Coolant Invert"] = "Inversion refroidissement d'urgence",
    ["Wireless/Ender Comms Modem"] = "Modem com sans fil/Ender",
    ["Wireless/Ender Modem"] = "Modem sans fil/Ender",
    ["Wired Comms Modem"] = "Modem com cable",
    ["Wired Modem"] = "Modem cable",
    ["Prefer Wireless"] = "Preferer le sans fil",
    ["Prefer Wireless Modem"] = "Preferer le modem sans fil",
    ["SVR Channel"] = "Canal SVR",
    ["PLC Channel"] = "Canal PLC",
    ["RTU Channel"] = "Canal RTU",
    ["CRD Channel"] = "Canal CRD",
    ["PKT Channel"] = "Canal PKT",
    ["Log Mode"] = "Mode journal",
    ["Log Path"] = "Chemin journal",
    ["Log Debug Messages"] = "Messages debug",
    ["Front Panel Theme"] = "Theme panneau frontal",
    ["Color Mode"] = "Mode couleur",
    ["Speaker Volume"] = "Volume haut-parleur",
    ["Pocket Connectivity"] = "Connectivite Pocket",
    ["Pocket Testing Features"] = "Fonctions de test Pocket",
    ["Pocket Channel"] = "Canal Pocket",
    ["Pocket Timeout"] = "Delai Pocket",
    ["PLC Connection Timeout"] = "Delai connexion PLC",
    ["RTU Connection Timeout"] = "Delai connexion RTU",
    ["CRD Connection Timeout"] = "Delai connexion CRD",
    ["PKT Connection Timeout"] = "Delai connexion PKT",
    ["PLC Listen Mode"] = "Mode ecoute PLC",
    ["RTU Gateway Listen Mode"] = "Mode ecoute passerelle RTU",
    ["Coordinator Listen Mode"] = "Mode ecoute coordinateur",

    -- pocket/coordinator common UI text
    ["Loading..."] = "Chargement...",
    ["Status"] = "Statut",
    ["Online"] = "En ligne",
    ["Off-line"] = "Hors ligne",
    ["Computer"] = "Ordinateur",
    ["Firmware"] = "Micrologiciel",
    ["Facility"] = "Installation",
    ["Facility Commands"] = "Commandes installation",
    ["Facility Tanks"] = "Reservoirs installation",
    ["Annunciator"] = "Annonciateur",
    ["Total Online"] = "Total en ligne",
    ["Matrix Status"] = "Statut matrice",
    ["SPS Status"] = "Statut SPS",
    ["Unit Statuses"] = "Statuts des unites",
    ["Control State"] = "Etat de controle",
    ["Automatic SCRAM"] = "SCRAM automatique",
    ["ETA Unknown"] = "ETA inconnue",
    ["Units Online"] = "Unites en ligne",
    ["Induction Matrix"] = "Matrice d'induction",
    ["RTU Gateways"] = "Passerelles RTU",
    ["Reactor Unit #"] = "Unite reacteur #",
}

---@type {src:string,dst:string}[]
local FR_SUBSTR = {
    { "Welcome to the ", "Bienvenue dans " },
    { "Please select one of the following options.", "Selectionnez une option ci-dessous." },
    { "configurator", "configurateur" },
    { "Self-Check", "Auto-test" },
    { "Change Log", "Journal des changements" },
}

local function has_alpha(str)
    return type(str) == "string" and string.find(str, "%a") ~= nil
end

local function replace_plain(str, needle, repl)
    if needle == "" then return str end

    local pos = 1

    while true do
        local s, e = string.find(str, needle, pos, true)
        if s == nil then break end

        str = string.sub(str, 1, s - 1) .. repl .. string.sub(str, e + 1)
        pos = s + string.len(repl)
    end

    return str
end

local function translate_fr(str)
    local exact = FR_EXACT[str]
    if exact ~= nil then
        return exact
    end

    local out = str

    for _, repl in ipairs(FR_SUBSTR) do
        out = replace_plain(out, repl[1], repl[2])
    end

    return out
end

local function translate(str, cache)
    if locale ~= "fr" or not has_alpha(str) then
        return str
    end

    local memo = cache[str]
    if memo ~= nil then
        return memo
    end

    local out = translate_fr(str)
    cache[str] = out

    return out
end

---@param lang string
function i18n.set_locale(lang)
    local normalized = string.lower(tostring(lang or "fr"))
    if string.sub(normalized, 1, 2) == "fr" then
        locale = "fr"
    else
        locale = normalized
    end

    cache_ui = {}
    cache_console = {}
end

---@nodiscard
---@return string
function i18n.get_locale()
    return locale
end

---@nodiscard
---@param msg string
---@return string
function i18n.translate_ui(msg)
    return translate(msg, cache_ui)
end

---@nodiscard
---@param msg string
---@return string
function i18n.translate_console(msg)
    return translate(msg, cache_console)
end

return i18n
