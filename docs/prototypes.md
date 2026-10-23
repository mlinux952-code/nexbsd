# Étape D — Choix de la première preuve de faisabilité

**Date :** 2026-10-23
**Statut :** proposition — **à valider par le responsable du projet avant toute action**
**Contrainte rappelée :** aucune installation, aucun partitionnement, aucun formatage du disque principal.

---

## Méthode de comparaison

Cinq critères, notés de 1 (défavorable) à 5 (favorable) :

- **Utilité** : la preuve démontre-t-elle quelque chose de réellement structurant pour NexBSD ?
- **Risque** : sécurité, risque matériel, risque de fausse validation (5 = risque faible).
- **Complexité** : effort de mise en œuvre (5 = simple).
- **Coût matériel** : compatibilité avec 4 Go de RAM et un disque mécanique (5 = adapté).
- **Réutilisabilité** : ce qui est produit servira-t-il aux phases suivantes ?

---

## Option 1 — « NexBSD-Lab-0 » : nœud de services réseau sous FreeBSD

**Contenu.** Installer FreeBSD 15.1 (amd64) sur un support **externe** (clé USB ou disque USB), sans interface graphique, et y démontrer une chaîne de services isolés :

1. démarrage et inventaire matériel documenté ;
2. réseau local statique, pare-feu en refus par défaut ;
3. jail `files` avec **Samba ≥ 4.23** : un partage, deux utilisateurs, droits différenciés ;
4. journalisation centralisée + rotation ;
5. sauvegarde/restauration de l'état (snapshot ou archive) et exercice de retour arrière ;
6. mesures : RAM au repos, RAM par service, temps de démarrage, débit de copie.

**Ce que cela prouve.** Que la Couche A (FreeBSD) et une partie de la Couche D (services) sont maîtrisables, mesurables et documentables sur le matériel disponible — sans aucune modification du disque interne.

**Ce que cela ne prouve pas.** Rien sur le mobile, rien sur NetWare, rien sur l'annuaire (dans sa première version).

| Critère | Note | Commentaire |
|---|---|---|
| Utilité | 5 | fondation de tout le reste |
| Risque | 5 | tout se passe sur un support externe ; retour arrière = débrancher |
| Complexité | 4 | procédures documentées, paquets binaires |
| Coût matériel | 4 | sans interface graphique, 4 Go suffisent largement |
| Réutilisabilité | 5 | configurations, scripts, tests réutilisables |
| **Total** | **23/25** | |

---

## Option 2 — « NexBSD-MobileShell » : coquille d'interface à petit écran

**Contenu.** Sur FreeBSD + X11/Wayland minimal, afficher une interface « inspirée de KaiOS » : écran d'accueil en grille, navigation au pavé directionnel, lancement d'applications Web locales (horloge, notes, paramètres) sur un moteur WebKitGTK ou Firefox en mode kiosque. Mesurer la mémoire, la fluidité et le temps de démarrage des applications.

**Ce que cela prouve.** Qu'une expérience mobile crédible peut être construite en logiciel pur sur base BSD, sans téléphone.

**Ce que cela ne prouve pas.** Aucune fonction matérielle mobile (téléphonie, SMS, capteurs, énergie). Et sur un PC de 2011 sans GPU exploitable, la fluidité obtenue ne préjuge rien d'un téléphone.

| Critère | Note | Commentaire |
|---|---|---|
| Utilité | 3 | démontre l'UX, pas la faisabilité système |
| Risque | 4 | peu risqué, mais forte tentation de surinterpréter |
| Complexité | 3 | moteur Web + X11 + code d'interface à écrire |
| Coût matériel | 2 | WebKitGTK + X11 sur 4 Go, disque lent, GPU ancien : serré |
| Réutilisabilité | 3 | le code UI survivra, le montage non |
| **Total** | **15/25** | |

---

## Option 3 — « NexBSD-NetWareLab » : banc de comparaison NetWare

**Contenu.** Monter, dans une **VM Linux isolée** (sans passerelle), un serveur MARS_NWE avec le module IPX hors arbre, puis un client DOS dans un émulateur (86Box/DOSBox), afin de documenter précisément le comportement réel d'un serveur NetWare : bindery, trustees, scripts de login, arborescence `SYS:PUBLIC`. Produire une fiche de spécification fonctionnelle comparée à Samba/OpenLDAP.

**Ce que cela prouve.** Ce que NetWare *faisait*, avec des preuves observées — et à quel point Samba/OpenLDAP s'en écartent.

**Ce que cela ne prouve pas.** Aucune voie d'intégration dans NexBSD : MARS_NWE reste inutilisable sous FreeBSD (absence d'IPX).

| Critère | Note | Commentaire |
|---|---|---|
| Utilité | 2 | culture technique utile, valeur produit faible |
| Risque | 2 | code dangereux, protocole non authentifié, à isoler strictement |
| Complexité | 2 | module noyau hors arbre, client DOS, émulateur |
| Coût matériel | 2 | VM + émulateur sur 4 Go |
| Réutilisabilité | 2 | surtout de la documentation |
| **Total** | **10/25** | |

---

## Comparaison synthétique

| Option | Utilité | Risque | Complexité | Matériel | Réutilisabilité | Total |
|---|---|---|---|---|---|---|
| 1 — Lab-0 (services réseau) | 5 | 5 | 4 | 4 | 5 | **23** |
| 2 — MobileShell (interface) | 3 | 4 | 3 | 2 | 3 | **15** |
| 3 — NetWareLab (compatibilité) | 2 | 2 | 2 | 2 | 2 | **10** |

---

## Recommandation argumentée

**Démarrer par l'option 1 (« NexBSD-Lab-0 »).**

Raisons :

1. **C'est la seule option dont le résultat est un fait mesurable**, pas une impression : un partage accessible avec des droits vérifiés, une mémoire mesurée, un retour arrière exercé.
2. **Risque matériel quasi nul** : tout se passe sur un support externe ; le disque interne reste intact par construction, ce qui respecte la contrainte absolue.
3. **Elle valide les hypothèses les plus solides du projet** (FreeBSD + Samba) et lève immédiatement les deux inconnues bloquantes : version réelle d'OpenLDAP disponible et version réelle de Samba.
4. **Elle produit des artefacts réutilisables** : procédures, fichiers de configuration, tests T-01 à T-06.
5. Les options 2 et 3 restent pertinentes **ensuite** : l'option 2 en phase 5 (mobile), l'option 3 uniquement si le responsable du projet veut une étude historique documentée — jamais en parallèle sur la même machine de 4 Go.

### Ordre proposé

```
Option 1 (Lab-0)  →  mesures  →  décision Go/No-Go sur la suite
        ↓
Option 2 (MobileShell)  ← si et seulement si Lab-0 est stable et mesuré
        ↓
Option 3 (NetWareLab)   ← optionnel, isolé, sans impact sur NexBSD
```

### Critères de sortie de l'option 1 (Go/No-Go)

- T-01 démarrage : réussi, sortie `uname -a` archivée.
- T-02 inventaire : CPU (64 bits confirmé), firmware, disque, réseau, tous documentés.
- T-03 partage : un client lit/écrit selon ses droits, un accès non autorisé est **refusé** (preuve).
- T-05 isolation : les services tournent en jail, `pf` bloque par défaut.
- T-06 restauration : après suppression volontaire d'un fichier de configuration, le retour à l'état connu est réussi et chronométré.
- Mesures consignées : RAM au repos, RAM avec Samba, temps de démarrage.

Si T-02 échoue (CPU 32 bits), **arrêt immédiat** et réorientation (autre machine ou VM).

---

## Ce qui n'est pas décidé

- Le support de démarrage exact (clé USB vs disque USB externe) : dépend de ce que le firmware du PC accepte — inconnu.
- UFS ou ZFS : à trancher après l'inventaire matériel (ZFS consomme de la RAM ; UFS est plus économe).
- La version de Samba retenue : à confirmer au moment de l'installation.
