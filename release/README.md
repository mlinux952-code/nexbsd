# Dossier `release/` — construction et publication des images

Exigé par la Partie XIII. **Aucune image n'a été produite.**

Contiendra :
- `release.conf` / scripts de construction (aujourd'hui : `fork/release.conf` + `build-nexbsd.sh`, non exécutés) ;
- notes de version par version publiée ;
- sommes de contrôle et signatures (porte G8 — mécanisme non choisi) ;
- procédure de vérification destinée au public ;
- journal des publications (vide).

## Conditions avant la première entrée

1. profil **L3** disponible (ADR-0010) ;
2. `buildworld` + `buildkernel` réussis au moins une fois ;
3. image démarrée dans une VM (T-01) ;
4. licence, nom et marques vérifiés (portes G1, G8) ;
5. `scripts/40-verifier-frontiere-licence.sh` passé sans erreur sur l'arborescence de l'image.
