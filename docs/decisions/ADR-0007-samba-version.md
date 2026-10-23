# ADR-0007 — Épingler Samba à une version maintenue (≥ 4.23)

- **Date :** 2026-10-23
- **Statut :** proposition
- **Référence :** `research/samba/fiche.md`

## Problème
Le port FreeBSD par défaut est encore `samba416`, alors que Samba 4.16 n'est plus maintenu en amont ; `samba419` et `samba420` sont explicitement dépréciés. Installer « samba » sans préciser revient à installer une version vulnérable.

## Décision proposée
- Installer explicitement `net/samba423` (ou une version supérieure disponible au moment de l'installation, ≥ 4.23).
- Consigner la version exacte dans `matrices/components.csv` et dans le rapport de prototype.
- Interdire toute installation par défaut du métapaquet `samba`.

## Justification
Les séries 4.23 et 4.24 sont maintenues (octobre 2026), la 4.22 est en fin de vie ; les CVE récentes (4.23.11, 4.23.13) montrent que les mises à jour sont fréquentes et nécessaires.

## Conséquences
- Dépendances supplémentaires à compiler/installer explicitement.
- Vérification de version à chaque mise à jour du système.

## Conditions de révision
Si un port `samba425` (ou LTS équivalent) devient disponible et validé.
