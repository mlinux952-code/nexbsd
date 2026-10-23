# Procédure de mise à jour

**Version :** 0.1 — 2026-10-23 — **STATUT : SQUELETTE NON TESTÉ**
**Rôle :** livrable 17 du méga-prompt.

> ⚠️ **Ce document ne peut pas être validé aujourd'hui : aucun système NexBSD n'existe, et aucune mise à jour n'a été appliquée.** Il décrit la procédure *prévue*. Chaque étape devra être exécutée puis cochée, avec capture de sortie, avant que ce document porte un autre statut.

---

## 1. Les trois niveaux de mise à jour

| Niveau | Quoi | Mécanisme prévu | Statut réel |
|---|---|---|---|
| **N1 — paquets Plateforme** (Samba, OpenLDAP…) | binaires tiers | `pkg upgrade` dans la jail concernée | non testé |
| **N2 — base système** | noyau + userland FreeBSD | `freebsd-update` (aujourd'hui) → **pkgbase NexBSD** (après J8) | non testé |
| **N3 — version NexBSD** | passage d'une version du produit à la suivante | image signée + procédure de migration | inexistant (aucune image) |

## 2. Procédure N1 — paquets (prévue)

1. **Sauvegarder** l'état (voir §5) — obligatoire avant toute mise à jour.
2. Lire la note de version du paquet et les avis de sécurité le concernant.
3. Vérifier que la version cible est **maintenue** (ex. Samba ≥ 4.23).
4. `pkg upgrade` **dans la jail**, jamais sur l'hôte simultanément.
5. Redémarrer le service concerné, pas la machine.
6. Vérifier : service actif, journal sans erreur, test fonctionnel du service (T-03 pour Samba).
7. Consigner : date, version avant/après, résultat, anomalies.

## 3. Procédure N2 — base système (prévue)

1. Sauvegarde + instantané.
2. `freebsd-update fetch install` (ou `pkg upgrade` sur la base pkgbase, après J8).
3. **Redémarrer** (obligatoire pour un noyau).
4. Vérifier : `uname -a` cohérent, services remontés, aucune erreur au démarrage.
5. En cas d'échec : restauration de l'instantané (§5), **pas de réparation à l'aveugle**.

## 4. Règles non négociables

- **Jamais** de mise à jour sans sauvegarde préalable testée.
- **Jamais** de mise à jour simultanée de l'hôte et des jails.
- **Jamais** de mise à jour vers une version non maintenue (cf. R-07 : Samba 4.16).
- Une mise à jour qui échoue **se restaure**, elle ne se « bricole » pas.
- Toute mise à jour est consignée dans `CHANGELOG.md` et dans un compte rendu.

## 5. Retour arrière (prévu)

| Support | Méthode | Test associé |
|---|---|---|
| UFS (cible L1) | archive `tar` de l'état de référence sur support distinct | T-06 |
| ZFS (profils > 4 Go) | instantané + `zfs rollback` | T-06 |

**Critère de réussite : restauration en moins de 15 minutes, vérifiée au moins une fois.**

## 6. Points à trancher plus tard

- Signature des paquets et des images (porte G8) : mécanisme non choisi.
- Politique de support : combien de versions maintenues simultanément ? non décidé.
- Fréquence de suivi des avis de sécurité FreeBSD : à définir (au moins mensuelle, cf. R-17).
