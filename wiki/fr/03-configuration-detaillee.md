# 03 - Configuration Detaillee

## 1) Configuration reseau commune

Sur chaque role (`Supervisor`, `Coordinator`, `RTU`, `PLC`, `Pocket`):

- Definir les memes canaux logiques de l'installation.
- Verifier le mode modem (`Wired`, `Wireless`, `Wireless and Wired`).
- Configurer les timeouts avant mise en service.

Canaux a verifier:

- `SVR_Channel`
- `PLC_Channel`
- `RTU_Channel`
- `CRD_Channel`
- `PKT_Channel`

## 2) Supervisor

Configurer:

- Nombre d'unites reacteur.
- Mode de refroidissement (unites/tanks installation).
- Mapping turbines/boilers/tanks par unite.
- Activation Pocket et options de test distantes.

Points critiques:

- Les IDs d'unites doivent etre coherents partout.
- Les layouts de tanks doivent correspondre au piping reel.
- Les timeouts trop faibles creent de faux positifs de deconnexion.

## 3) Coordinator

Configurer:

- Moniteurs (main/flow/unit).
- Theme, mode couleur, logs.
- Parametres process auto (charge/range/generation).
- Auth key si liaison sans fil securisee.

## 4) RTU Gateway

Configurer pour chaque entree:

- Type d'equipement (`boilerValve`, `turbineValve`, `dynamicValve`, `fusion`, etc.).
- Index logique (ex: turbine #1, fusion #1).
- Unite ou installation cible.
- Mapping redstone/peripherique.

Bonnes pratiques:

- Eviter les doublons d'index.
- Nommer clairement les peripheriques cote monde.
- Tester chaque port en mode configurateur avant prod.

## 5) PLC Reactor

Configurer:

- `Unit ID`
- Mode reseau ou autonome
- I/O d'urgence (refroidissement)
- Parametres ramping et securite

Le PLC doit rester strictement aligne a l'unite fission physique.
