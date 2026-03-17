# 01 - Architecture SCADA

## Vue d'ensemble

Le systeme est compose de 5 briques principales:

- `PLC Reactor` : securite locale et commande reacteur fission.
- `RTU Gateway` : passerelle I/O Modbus vers machines Mekanism.
- `Supervisor` : coeur de supervision, logique centrale, alarmes.
- `Coordinator` : IHM principale (moniteurs), configuration process.
- `Pocket` : IHM mobile distante (lecture + commandes ciblees).

## Flux de donnees

1. Les RTU lisent l'etat des peripheriques Mekanism.
2. Le Supervisor consolide les etats et publie les statuts.
3. Le Coordinator affiche et envoie les commandes operateur.
4. Le Supervisor applique les commandes vers PLC/RTU.
5. Les acks et nouveaux etats reviennent vers l'IHM.

## Types de controle

- Controle fission: via PLC (burn rate, SCRAM, RPS, alarms).
- Controle fusion: via RTU fusion (etat, fluides, injection).
- Controle installation: modes process, dechets, auto-groups.

## Communications

- Protocole SCADA interne (management + commandes).
- Trame Modbus inspiree pour RTU.
- Option de securite HMAC pour liaisons reseau.
- Canaux dedies: `SVR`, `PLC`, `RTU`, `CRD`, `PKT`.

## Principes de robustesse

- Session watchdog sur tous les liens.
- Re-emission periodique des builds/statuts.
- Ack explicite sur commandes critiques.
- Degradation explicite en cas de perte partielle d'un equipement.
