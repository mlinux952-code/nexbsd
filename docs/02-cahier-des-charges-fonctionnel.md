# Cahier des charges fonctionnel

**Version :** 1.0 — 2026-10-23 (session S-007)
**Rôle :** livrable 2 du méga-prompt. Traduit les besoins exprimés en **exigences vérifiables**, avec un critère d'acceptation par exigence.
**Statut :** `[PROPOSITION]` — aucune exigence n'est satisfaite aujourd'hui ; aucune n'a été testée.
**Traçabilité :** chaque exigence renvoie à `matrices/functions.csv` (fonction), `tests/plan-tests.md` (test) et éventuellement une ADR.

---

## 1. Qui utilise NexBSD, et pour quoi faire

| Acteur | Besoin dominant | Ce qu'il ne fera jamais |
|---|---|---|
| **Particulier** avec un vieux PC | retrouver une machine utilisable, partager des fichiers à la maison | administrer un annuaire |
| **Association / école / petite structure** sans informaticien | un serveur de fichiers avec des comptes et des droits, installé une fois, oublié ensuite | intervenir en ligne de commande |
| **Administrateur occasionnel** du foyer ou de la structure | voir l'état, créer un compte, sauvegarder | maintenir un cluster |
| **Technicien / contributeur** | installer, diagnostiquer, reproduire | — |

**Conséquence de conception :** toute fonction doit être réalisable **sans terminal** pour les deux premiers acteurs, et **sans Internet** pour tous.

---

## 2. Exigences fonctionnelles — système (S)

| ID | Exigence | Critère d'acceptation | Priorité | Test |
|---|---|---|---|---|
| **EF-S-01** | Le système démarre sur matériel amd64 de 2011 sans intervention manuelle après installation | 3 démarrages consécutifs réussis, chronométrés | P0 | T-01, T-02 |
| **EF-S-02** | Le système identifie le matériel et l'affiche en langage compréhensible | écran « matériel » listant CPU, RAM, disques, réseau, avec au moins une alerte si RAM < 2 Go | P1 | T-02 |
| **EF-S-03** | Le système fonctionne sans connexion Internet | coupure réseau physique : toutes les fonctions locales restent opérationnelles | P0 | T-03 |
| **EF-S-04** | Le stockage par défaut est UFS ; l'installation ne touche jamais un disque non désigné explicitement | confirmation obligatoire par identifiant de disque ; refus si disque système détecté | P0 | T-02, T-08 |
| **EF-S-05** | Les comptes locaux se créent et se suppriment sans terminal | procédure graphique ou guidée, effet vérifié par connexion réelle | P1 | T-05 |
| **EF-S-06** | Tout événement notable est journalisé et consultable | journal lisible dans l'outil d'administration, rotation configurée | P1 | T-05 |
| **EF-S-07** | Les services réseau sont isolés (jail) et filtrés (refus par défaut) | scan externe : seuls les ports déclarés répondent | P0 | T-04 |
| **EF-S-08** | Une sauvegarde et une restauration complètes sont possibles hors ligne | restauration vérifiée en < 15 min sur un état de référence | P1 | T-06 |

## 3. Exigences fonctionnelles — réseau façon NetWare (N)

> C'est l'**axe d'identité** du projet (ADR-0017). Ces exigences sont classées par ordre de dépendance : N-01 avant N-02, etc.

| ID | Exigence | Critère d'acceptation | Priorité | Composant | Test |
|---|---|---|---|---|---|
| **EF-N-01** | Partager un répertoire sur le réseau local, accessible depuis Windows/Linux/macOS | un fichier écrit depuis un poste est lu depuis un autre, sans perte | P0 | Samba ≥ 4.23 | T-03 |
| **EF-N-02** | Appliquer des droits par utilisateur et par groupe, hérités dans les sous-répertoires | un utilisateur non autorisé reçoit un refus explicite, pas une erreur opaque | P0 | ACL + Samba | T-03 |
| **EF-N-03** | Centraliser les identités dans un annuaire unique | un compte créé dans l'annuaire se connecte au partage sans création locale | P1 | OpenLDAP ≥ 2.6 | T-04 |
| **EF-N-04** | L'annuaire est extensible et sauvegardable (structure hiérarchique) | export et réimport complets vérifiés | P2 | OpenLDAP | T-04 |
| **EF-N-05** | Un seul mot de passe pour les services NexBSD (esprit « login unique ») | changement de mot de passe : effet sur tous les services, sans redémarrage | P2 | LDAP + Kerberos / AD | — (non planifié) |
| **EF-N-06** | Les lecteurs réseau se connectent automatiquement selon l'utilisateur (esprit script de connexion) | un poste client voit ses lecteurs après connexion, sans action manuelle | P2 | Samba | — |
| **EF-N-07** | Impression partagée sur le réseau | un document imprimé depuis un poste client sort correctement | P2 | CUPS + Samba | — |
| **EF-N-08** | Une administration unique, en un seul endroit, sans terminal | créer un compte, voir l'état, voir les journaux depuis une seule interface | P1 | **à écrire** (NexBSD) | T-08 |
| **EF-N-09** | Les services réseau sont supervisés et leur état est visible | un service arrêté est signalé en moins d'une minute | P2 | syslog + moniteur léger | T-05 |
| **EF-N-10** | Les services se découvrent sur le réseau local (esprit SAP) | un client découvre le serveur sans saisir son adresse | P3 | mDNS/DNS-SD | T-15 |
| **EF-N-11** | **Un client NCP se connecte et utilise les fichiers** (différenciation) | NCP-1→NCP-3 réussis avec le client de référence sur le port 524 | P2 *(P0 en ambition)* | **à écrire** (NexBSD) | T-09, T-14 |

**Périmètre NCP volontairement borné** (`research/ncp-ip/fiche.md`) : login/attach · map volume · lecture/écriture · listing · droits/trustees · bindery simple. **Hors périmètre :** impression NCP, NDS/eDirectory, Burst Mode complet, chiffrement NCP. Règle R-20 : si NCP-1→NCP-3 échouent, on **suspend et on documente**, on n'étend pas.

## 4. Exigences fonctionnelles — interface (C)

| ID | Exigence | Critère d'acceptation | Priorité | Test |
|---|---|---|---|---|
| **EF-C-17** | L'interface est lisible sur un écran de 10 pouces et sur un 1024×768 | aucune coupure de texte, aucune zone cliquable < 8 mm | P2 | T-10 |
| **EF-C-18** | Tout se fait au clavier / pavé directionnel, sans souris | parcours complet réalisé sans souris, documenté | P2 | T-10 |
| **EF-C-19** | Lancer et quitter des applications sans terminal | 3 applications lancées et fermées proprement | P3 | T-10 |
| **EF-C-20** | Notifier l'utilisateur d'un événement (sauvegarde, erreur de service) | notification visible et non bloquante | P3 | — |
| **EF-C-21** | Tenir sur batterie (portables) | autonomie mesurée, pas de surchauffe | P3 | — |
| **EF-C-22** | Téléphonie / SMS | **ABANDONNÉ** : aucun pilote, aucun appareil cible (ADR-0008) | — | — |

## 5. Exigences fonctionnelles — construction et distribution (F)

| ID | Exigence | Critère d'acceptation | Priorité | Test |
|---|---|---|---|---|
| **EF-F-23** | Le projet construit sa **propre** image, avec son nom | `buildworld` + `buildkernel` + `release.sh` produisent une image qui **démarre** | P0 (bloqué par L3) | T-12 |
| **EF-F-24** | Une image de test/installation est produite et vérifiable | image + empreinte publiée, écriture sur clé testée | P1 | T-07 |
| **EF-F-25** | La construction est reproductible | reconstruction depuis un état propre, écarts expliqués | P2 | T-11 |
| **EF-F-26** | Aucun code copyleft n'entre dans la base | contrôle automatisé sans occurrence non justifiée | P0 | T-13 |

## 6. Exigences non fonctionnelles (opposables)

| ID | Exigence | Objectif | Mesure |
|---|---|---|---|
| **ENF-01** | RAM au repos | ≤ 128 Mo | `vmstat`/`top` |
| **ENF-02** | RAM avec services réseau actifs | ≤ 256 Mo | idem |
| **ENF-03** | Empreinte disque | ≤ 2 Go (base) / ≤ 4 Go (avec services) | `df -h` |
| **ENF-04** | Démarrage sur disque mécanique | ≤ 60 s jusqu'à l'invite | chronomètre |
| **ENF-05** | Surface réseau exposée | ports déclarés uniquement, refus par défaut | scan |
| **ENF-06** | Aucune dépendance à Internet | coupure réseau : rien ne casse | test manuel |
| **ENF-07** | Installation réalisable par un non-technicien | ≤ 6 étapes, aucune commande à taper | observation |
| **ENF-08** | Tout est administrable sans terminal pour les fonctions P0/P1 | parcours complet sans console | observation |

**Ces objectifs sont des cibles de conception, aucun n'a été mesuré.** Ils sont opposables : une fonctionnalité qui les casse est refusée ou isolée (ADR-0009).

## 7. Contraintes

| Contrainte | Origine |
|---|---|
| Aucune modification du disque principal du PC de test | méga-prompt Partie X |
| Support externe uniquement pour toute écriture | idem |
| Pas de compilation lourde sur la station Mint | ADR-0010 |
| Base en licences permissives ; copyleft isolé en Plateforme | ADR-0012 |
| Le nom « FreeBSD » n'apparaît pas comme nom de produit | marque déposée |
| Dépôt non public par défaut | `docs/13-publication-grand-public.md` |

## 8. Ce qui est explicitement hors périmètre (v1)

Téléphonie, serveur de messagerie, cloud/synchronisation, virtualisation intégrée, haute disponibilité, support 32 bits (non tranché — Q2), NDS/eDirectory, compatibilité NetWare complète.

## 9. Priorisation — ce qui doit marcher d'abord

1. **EF-S-01/03/04/07** + **EF-N-01/02** : « un serveur de fichiers qui démarre et partage ». Sans cela, il n'y a pas de produit.
2. **EF-F-23/26** : « un système à notre nom, sans piège de licence ». Sans cela, il n'y a pas de NexBSD.
3. **EF-N-08** : l'administration unique — c'est la promesse d'usage.
4. **EF-N-11** : la différenciation NCP — précieuse, mais **après** que le reste tienne debout.
5. Le reste : confort.

## 10. Hypothèse à valider par le responsable (Q9)

Ce cahier des charges suppose que **la cible première est la petite structure avec comptes et droits**, pas le simple usage domestique. Si l'inverse est vrai, les priorités de N-03 à N-09 baissent et EF-S-05/EF-N-08 deviennent prioritaires différemment.
