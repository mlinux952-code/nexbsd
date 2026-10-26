# Sécurité de NexBSD — défense en profondeur, couche par couche

**Date :** 2026-10-26 · **Origine :** demande du responsable — *« je veux la sécurité la plus puissante,
puisqu'il est engagé pour les manipulations réseau »*

**Mise au point d'entrée :** « la sécurité la plus puissante » n'est pas un réglage, c'est un **empilement
de barrières indépendantes**. Une seule barrière parfaite n'existe pas ; quatre barrières imparfaites rendent
l'intrusion très coûteuse. Ce document dit **ce qui est fait**, **ce qui est possible**, et **ce qui manque**.

---

## 1. Les huit couches, et où nous en sommes

| # | Couche | Rôle | État au 2026-10-26 |
|---|---|---|---|
| **L1** | **Pare-feu `pf`** — refus par défaut | ferme tout, ouvre le strict nécessaire | **FAIT ce soir** (`scripts/71`) |
| **L2** | **Services minimaux** | n'installer/armer que ce qui sert | **PARTIEL** : `slapd` + `smbd` seulement, mais aucune revue formelle |
| **L3** | **Isolation en jail** | chaque service dans sa prison ; une faille Samba ne donne pas root | **ABSENT** — ADR-0005 le prévoit, jamais réalisé |
| **L4** | **Durcissement noyau (sysctl)** | désactiver ce qui ne sert pas (redirections ICMP, `sysctl` sensibles) | **ABSENT** |
| **L5** | **Moindre privilège utilisateur** | services non-root quand c'est possible ; droits minimaux | **PARTIEL** — Samba/OpenLDAP tournent en root par défaut |
| **L6** | **Journalisation et audit** | savoir qui a fait quoi, et le prouver | **PARTIEL** — `syslog` + journaux, aucune revue régulière |
| **L7** | **Mises à jour et correctifs** | fermer les trous connus | **ABSENT** — aucune procédure écrite |
| **L8** | **Sauvegarde et retour arrière** | si tout tombe, revenir en 15 min | **ABSENT** — T-06 non exécuté |

**Traduction franche :** ce soir, NexBSD passe de « tout ouvert » à **« tout fermé sauf ce qui est prouvé
nécessaire »**. C'est la couche la plus rentable. Les sept autres restent à faire, et deux d'entre elles
(jails, sauvegarde) sont **plus importantes** que `pf` pour un vrai serveur de fichiers.

---

## 2. L1 — le pare-feu, décidé par la preuve, pas par l'habitude

Le harnais `T-18` (24/24) a établi **exactement** ce qui doit rester ouvert :

| Port | Service | Pourquoi il reste ouvert |
|---|---|---|
| **445/tcp** | SMB (fichiers) | c'est le service du banc ; `omrane` écrit, `sara` est refusée |
| **139/tcp**, **137-138/udp** | NetBIOS | résolution de nom historique — **indispensable pour un client Windows réel** (T-15/T-09 à venir) |
| **389/tcp** | LDAP | l'annuaire ; **restreint au réseau de laboratoire** |
| **22/tcp** | SSH | administration (à durcir en L4) |
| **ICMP echo** | diagnostic | limité en débit, sinon on ne peut même pas savoir si la machine est vivante |

**Tout le reste est fermé et journalisé.** Les connexions **sortantes** restent autorisées (mises à jour,
`fetch`), mais **aucune connexion entrante non sollicitée** n'est acceptée.

**Trois précautions prises, qui comptent plus que le contenu des règles :**

1. **La console est série (`ttyu0`)** : une erreur de pare-feu **ne peut pas nous couper l'accès**. C'est un
   luxe rare — sur une machine distante, une règle fausse vous enferme dehors.
2. **Validation à blanc avant activation** (`pfctl -n -f`) : on vérifie la syntaxe **sans** appliquer.
3. **Rejeu du harnais juste après** : si une règle a coupé quelque chose, le harnais le dit (24/24 attendu).
   Le contrôle est **automatique**, pas déclaratif.

---

## 3. L3 — pourquoi les jails sont la vraie barrière (et pourquoi ce n'est pas pour ce soir)

`pf` protège du **réseau**. Les jails protègent **d'un service compromis**.

Scénario concret : une faille dans Samba permet à un attaquant d'exécuter du code. Sans jail, ce code tourne
en **root sur tout le système** : il lit `/etc/master.passwd`, l'annuaire, les sauvegardes, et il peut
réécrire le noyau sur disque. Avec une jail, il tourne **enfermé** : il voit un système de fichiers
restreint, ses propres processus, et **rien d'autre**. Il faut alors une **seconde** faille pour s'évader.

**Pourquoi pas ce soir :** monter les jails proprement, c'est changer l'emplacement des données, refaire
l'annuaire dans la jail, revérifier NSS et les droits — donc **refaire T-04 → T-04-G** dans un nouvel
environnement. C'est une étape à part entière, pas un ajout. Elle figure déjà dans l'architecture
(ADR-0005) et elle est **prioritaire après l'image**.

---

## 4. L4 à L8 — ce qu'il faudra faire, dans l'ordre de rentabilité

| Ordre | Action | Gain | Coût | Quand |
|---|---|---|---|---|
| 1 | **`pf` refus par défaut** | énorme | 30 min | **ce soir** |
| 2 | **Durcissement `sysctl` + SSH** (pas de root direct, clés seulement) | fort | 1 h | après `pf` |
| 3 | **Revue des services armés** (`sockstat -l`, `service -e`) | fort | 30 min | idem |
| 4 | **Journalisation vérifiée** (`pflog`, journaux Samba/LDAP, rotation) | moyen | 1 h | idem |
| 5 | **Procédure de mise à jour** écrite et testée | fort | 1 h | avant toute exposition réseau |
| 6 | **Jails** (L3) | **très fort** | 1 à 2 jours | après l'image |
| 7 | **Sauvegarde/restauration exercée** (T-06) | **très fort** | 1 jour | après l'image |
| 8 | Séparation physique / réseau de labo isolé | dépend du déploiement | — | au déploiement |

**Règle de priorité appliquée :** une barrière **exercée et vérifiée** vaut mieux que trois barrières
activées sans preuve. C'est pourquoi chaque couche devra passer le harnais.

---

## 5. Ce que « sécurité puissante » ne veut pas dire — les points sur les i

| Affirmation | Réalité |
|---|---|
| « Avec `pf`, le système est sécurisé » | **faux** : `pf` protège du réseau, pas d'un service compromis (L3), ni d'une faille connue non corrigée (L7) |
| « OpenLDAP et Samba sont sûrs » | ce sont des logiciels **tiers**, complexes, exposés : ils reçoivent des CVE régulièrement. La parade est **jail + mises à jour**, pas la confiance |
| « Personne ne trouvera la VM » | l'obscurité n'est pas une barrière ; le refus par défaut, oui |
| « On pourra toujours se reconnecter » | **vrai ici seulement** parce que la console est série. Sur un vrai serveur, une règle `pf` fausse = perte d'accès |
| « Le banc est un produit » | **non** : c'est un banc. Le produit exigera L3, L7 et L8 **avant** d'être branché quelque part |

---

## 6. Décision de la session

1. **L1 est appliqué ce soir** : `scripts/71-pare-feu-pf.sh`, refus par défaut, ouverture prouvée par T-18.
2. **Le harnais est rejoué immédiatement après** : si le pare-feu casse quelque chose, c'est su dans la minute.
3. **L2, L4, L6 sont les prochaines étapes** de sécurité, avant toute exposition réseau réelle.
4. **L3 (jails) et L8 (restauration) sont inscrites comme prioritaires après l'image** — ce sont elles qui
   feront la différence entre un banc et un serveur.
