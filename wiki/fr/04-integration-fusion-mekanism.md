# 04 - Integration Fusion Mekanism

## Objectif

Piloter un reacteur a fusion Mekanism depuis l'IHM SCADA en envoyant une consigne d'injection (`mB/t`) via la chaine:

- Pocket/Coordinator -> Supervisor -> session RTU fusion -> registre Modbus d'ecriture.

## Prerequis terrain

- Reacteur fusion Mekanism forme et operationnel.
- RTU configure en type `FUSION` avec index valide.
- Liaison modem/peripherique stable.
- Unite Supervisor associee a ce RTU fusion.

## Chemin de commande (resume technique)

1. IHM envoie `UNIT_COMMAND.SET_FUSION_INJ`.
2. Supervisor valide l'option numerique.
3. `unit.set_fusion_injection(rate)` pousse dans la queue RTU fusion.
4. Session RTU fusion ecrit `WRITE_SINGLE_HOLD_REG` registre `1`.
5. Le statut fusion remonte periodiquement et met a jour les ecrans.

## UI operateur

### Coordinator

- Vue detail fusion: champ injection + bouton `SET`.
- Champ bloque si le reacteur fusion n'est pas `formed`.

### Pocket

- Page fusion unite: `Set Inject` + bouton `SET`.
- Valeur synchronisee avec la telemetrie `injection_rate`.

## Validation fonctionnelle

- Changer la consigne depuis Coordinator.
- Verifier evolution `injection_rate` retour telemetrie.
- Refaire depuis Pocket.
- Verifier absence d'erreur session/timeout cote Supervisor.

## Limites et comportements attendus

- Si aucune session fusion n'est connectee: commande ignoree cote Supervisor.
- Valeurs negatives: bornees a `0`.
- En cas `device busy` Modbus: re-emission differee automatique.
