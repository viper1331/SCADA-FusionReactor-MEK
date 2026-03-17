# Guide de Contribution

>[!NOTE]
Tant que le systeme reste en beta, les contributions sont limitees pendant la finalisation des fonctionnalites de release.

Ce projet est complexe pour une application Lua ComputerCraft.
Les contributions doivent suivre les conventions de style et le niveau de qualite du projet.
Les modifications doivent etre testees, avec resultats de test fournis.

Le logiciel est structure en niveaux de robustesse :
1. **Critique : Impact eleve** -
   Le Reactor-PLC est pense comme "incassable" et doit le rester.
   Chaque modification doit respecter ce niveau d'exigence.
   Un code simple est souvent plus stable : moins de code, mieux c'est.
   Verifiez toujours les parametres et testez en profondeur les fonctions de thread critiques.
2. **Important : Impact modere** -
   Le Supervisor et la passerelle RTU ne doivent presque jamais planter.
   Certaines zones sont moins strictes que le niveau critique, mais le code doit prendre en compte les entrees possibles et les impacts globaux.
3. **Utile : Impact faible** -
   Coordinator et Pocket sont surtout des applications UI.
   Elles echangent beaucoup de donnees ; verifier absolument chaque valeur entrante augmenterait le cout CPU et la taille du programme.
   En cas de panne, l'utilisateur peut les redemarrer.
   N'introduisez pas de bugs evitables, mais certaines hypotheses sur l'integrite des donnees entrantes sont acceptables.

## Contributions utiles

Les pull requests ne doivent pas contenir uniquement :
- des changements de whitespace,
- des changements de commentaires,
- ou d'autres changements triviaux.

Une PR doit viser une fonctionnalite, une correction de bug, ou une amelioration fonctionnelle concrete.
Je me reserve le droit de refuser les PR qui ne respectent pas ce cadre.

## Gestion du projet

Toute contribution devrait etre reliee a une issue GitHub ouverte.
Les issues servent a suivre l'avancement et discuter les changements.
Les modifications "surprise" peuvent entrer en conflit avec la roadmap, donc il est preferable de se coordonner avant.

## Regles de developpement

Ces regles peuvent evoluer.
Regle generale : gardez un style coherent avec le code voisin et le reste du projet.

### Guide de style

Les PR ne sont acceptees que si elles respectent le style du projet et passent l'analyse manuelle + automatisee.

1. **Pas de commentaires bloc (`--[[ ... ]]`).**
   Ils perturbent la minification utilisee pour les bundles d'installation.
   Le pipeline de minification est volontairement simple pour minimiser le risque de regression.
2. **Commentez votre code.**
   Incluez egalement les hints de type, comme dans le reste du projet.
   Les commentaires doivent clarifier les zones complexes et decouper les sections de travail (`--#region`).
   - Les hints de type sont prevus pour l'extension VSCode `sumneko.lua`.
3. **Usage des espaces.**
   Utilisez des espaces autour des parametres et des operateurs.
   Exception : certains patterns visuels propres au moteur graphique.
   - Indentation : 4 espaces.
   - Essayez d'aligner les `=` comme ailleurs dans le projet.
   - Utilisez des lignes vides pour separer les etapes ou groupes d'operations.
   - Dans les boucles/conditions, gardez une structure lisible (certaines lignes compactes sont acceptees quand c'est pertinent).
4. **Variables et classes.**
   - Variables, fonctions et tables type "classe" : `snake_case`.
   - Objets graphiques et settings de configuration : `PascalCase`.
   - Constantes : `SNAKE_CASE` en majuscules.
5. **Pas de `goto`.**
   Cela reduit la lisibilite.
6. **Retours multiples (`return`).**
   Autorises pour reduire la taille du code, mais evitez-les si une alternative simple existe.
7. **Classes et objets.**
   Regardez les implementations existantes.
   Le projet n'utilise pas l'operateur `:` de Lua pour les objets ; il utilise des tables objet explicites.
   Certaines classes singleton globales n'ont pas de `new()` (ex : [PPM](https://github.com/MikaylaFischler/cc-mek-scada/blob/main/scada-common/ppm.lua)).
   Les classes multi-instances en ont un (ex : [unit](https://github.com/MikaylaFischler/cc-mek-scada/blob/main/supervisor/unit.lua) du Supervisor).

### Pas d'IA

Le code doit respecter le style guide, etre clair, et vous devez pouvoir expliquer precisement son fonctionnement.
Des changements aleatoires dans de nombreux fichiers, des commentaires pauvres, ou un code incoherent seront consideres comme suspects.
Utilisez vos contributions pour pratiquer et progresser ; n'automatisez pas la reflexion.
