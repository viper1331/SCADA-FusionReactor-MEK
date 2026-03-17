# 06 - Tests, Validation et Depannage

## Checklist de mise en service

1. Tous les composants demarrent sans crash.
2. Canaux reseau coherents sur tous les noeuds.
3. `Self-Check` valide sur Supervisor/RTU/PLC/Coordinator.
4. Telemetrie fission visible sur Coordinator.
5. Telemetrie fusion visible (`formed`, `injection_rate`, tanks).
6. Commande `SET_FUSION_INJ` effective depuis Coordinator et Pocket.

## Cas de test recommandes

- Test commande burn rate en mode manuel.
- Test SCRAM + reset + reprise.
- Test perte lien modem puis reprise.
- Test `device busy` RTU (observer re-emission sans plantage).
- Test alarmes et acquittement.

## Pannes frequentes

### Aucune telemetrie fusion

- Verifier type RTU `FUSION`.
- Verifier index et unit ID.
- Verifier modem/peripherique (nom peripherique visible).

### Commande injection sans effet

- Verifier que le reacteur est `formed`.
- Verifier session fusion presente cote Supervisor.
- Verifier logs modbus (adresse registre / busy / timeout).

### Version mismatch

- Lancer `ccmsi update` sur tous les noeuds.
- Redemarrer les services apres update.

### Faux timeouts reseau

- Augmenter les timeouts.
- Preferer modem cable pour liaisons critiques.
- Verifier distance/trusted range en sans-fil.

## Strategie de rollback

- Conserver snapshot des settings avant modif.
- Appliquer changements par lot reduit.
- Si regression: revenir au commit precedent stable, puis redemarrer.
