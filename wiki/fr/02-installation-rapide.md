# 02 - Installation Rapide

## Prerequis

- Minecraft + CC: Tweaked.
- Mekanism 10.1+.
- Recommande:
- Advanced Peripherals (telemetrie supplementaire, notamment environnement/radiation).
- Immersive Engineering ou equivalent pour redstone groupee.

## Installation via `ccmsi`

Sur un ordinateur ComputerCraft:

```lua
wget https://raw.githubusercontent.com/MikaylaFischler/cc-mek-scada/main/ccmsi.lua
ccmsi
```

Alternative:

```lua
pastebin get sqUN6VUb ccmsi.lua
ccmsi
```

## Installation depuis un clone local

Si le depot est copie tel quel sur le PC ComputerCraft:

- `ccmsi` detecte automatiquement `install_manifest.json`.
- Les fichiers locaux sont utilises comme source d'installation.

## Ordre recommande de deploiement

1. Installer et configurer `Supervisor`.
2. Installer `Coordinator`.
3. Installer/configurer `RTU` (fission/fusion/tanks/etc.).
4. Installer `PLC` reacteur sur chaque unite fission.
5. Installer `Pocket` (optionnel).

## Verification post-install

- Demarrer chaque composant.
- Verifier que les canaux reseau correspondent partout.
- Lancer les `Self-Check` des configurateurs.
- Controler les versions comms identiques (`ccmsi update` si besoin).
