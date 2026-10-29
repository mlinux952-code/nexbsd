# 62 — Les cinq affiches de sécurité du responsable : tri, refus, et la seule idée qui vaut

> **Message (2026-10-29, en déplacement) :** *« je trouve plusieurs pages sur Facebook et je mets
> quelques images, je ne sais pas trop mais bon voilà. »*
>
> **Réponse courte : sur cinq affiches, deux ne concernent pas NexBSD du tout, une répète une affiche
> déjà traitée, une est un catalogue d'outils offensifs qui n'ont rien à faire dans un système livré,
> et une seule contient une idée d'architecture réelle — les systèmes immuables.**
>
> Cette idée a produit ce soir **un script exécutable et une étape de CI** (`scripts/75`), et une
> **proposition d'ADR-0021** à trancher.

---

## 1. Le tri, affiche par affiche

| # | Affiche | Contenu | Verdict pour NexBSD |
|---|---|---|---|
| 1 | **12 Password Cracking Tools** | Hashcat, Hydra, Medusa, Brutus, Ncrack, Ophcrack, Wfuzz, L0phtCrack, RainbowCrack, Aircrack-ng, CrackMapExec, John the Ripper | ❌ **Aucun n'entre dans le produit.** Utile **hors** du produit, pour nous éprouver nous-mêmes |
| 2 | **Free Remote Desktop Tools** | déjà traité | ⚠️ **doublon** — même contenu que l'affiche du 29/10 19 h, déjà instruite (A-70 / C-47) |
| 3 | **Cybersecurity AI Tools** | Wazuh, Suricata, Velociraptor, Semgrep, ZAP, MISP, Rspamd, osquery | 🔜 **2 retenus pour N-09** (Suricata, osquery), 6 écartés |
| 4 | **Immutable Linux Distributions** | 15 distributions | ✅ **la seule idée d'architecture réelle** → ADR-0021 proposé |
| 5 | **Cybersecurity Tools** | Wireshark, Burp, Nmap, Metasploit, John, SQLMap, Aircrack, Hydra, Gobuster, theHarvester, Dirb, Nikto, BeEF, DroidHunter | ❌ **Aucun dans le produit** ; 2 sont nos **instruments de vérification** |

---

## 2. Affiche 1 — les casseurs de mots de passe : pourquoi aucun n'entre dans NexBSD

**Ce sont des outils offensifs.** Les installer dans un système qu'on livre à une entreprise serait
une faute : le jour où NexBSD contiendrait `hydra` ou `hashcat`, il serait **légitimement** signalé
comme suspect par tout antivirus, et personne ne pourrait plus le déployer. **Un serveur de fichiers
n'embarque pas d'outils pour casser les mots de passe des autres.**

Mais l'affiche apprend une chose utile — **en négatif** : elle montre **contre quoi** un serveur doit
résister. C'est exactement pour cela que j'ai écrit `scripts/75-verifier-durcissement.sh` aujourd'hui
(§5).

**Trois erreurs techniques dans l'affiche, qui montrent son âge :**

| Erreur | Correction |
|---|---|
| **Ophcrack** « cracks Windows password hashes » | il casse les **hashes LM**, un algorithme **mort depuis Windows Vista**. Sur un système de 2026, il ne casse **rien** |
| **RainbowCrack** « cracks hashes quickly » | les tables arc-en-ciel sont **inopérantes** contre tout hash **salé** (donc tous les hash modernes). Obsolète depuis 15 ans |
| **Brutus** présenté comme un outil majeur | c'est un outil Windows **quasi confidentiel** ; **Ncrack** (à côté) est le vrai outil de référence |

**Ce qu'il faut retenir :** la moitié de cette liste vise des technologies **abandonnées**. La vraie
menace aujourd'hui n'est pas le cassage de hash hors ligne, c'est le **bourrage d'identifiants** :
des mots de passe volés ailleurs, rejoués chez vous. **La défense n'est pas cryptographique, elle est
organisationnelle :** pas d'accès anonyme, pas de mot de passe vide, un nombre d'essais limité.

---

## 3. Affiche 3 — la cybersécurité « IA » : 2 retenus sur 8

| Outil | Ce que c'est | Décision |
|---|---|---|
| **Suricata** | détection d'intrusion réseau (IDS) | ✅ **CANDIDAT pour N-09** — présent dans les ports FreeBSD (`security/suricata`) |
| **osquery** | visibilité de l'état de la machine (interroger le système comme une base SQL) | ✅ **CANDIDAT pour N-09** — compile sous FreeBSD |
| **Wazuh** | détection d'intrusion sur l'hôte | ❌ **écarté** : architecture **Linux + Java + agent** ; à contre-emploi sur un « PC faible » |
| **Velociraptor** | investigation de poste | ❌ écarté : outil d'enquête, pas de service |
| **Semgrep / ZAP** | analyse de code / test web | ⏸ **plus tard, pour nous tester** : ZAP deviendra pertinent **quand la console web N-08 existera** |
| **MISP** | partage de renseignement sur les menaces | ❌ hors périmètre : suppose une communauté d'échange |
| **Rspamd** | filtrage de courriel | ❌ **hors périmètre** : NexBSD n'est pas un serveur de messagerie |

**Point à ne pas manquer :** ces huit outils sont des **outils de surveillance**, pas des fonctions
du système. Les intégrer à l'image ajouterait des dizaines de mégaoctets et une surface d'attaque
nouvelle. **N-09 doit d'abord être écrite avec ce que le système fournit** (`syslog`, `pflog`, état
des services), et **Suricata seulement si un besoin réel est démontré**.

---

## 4. Affiche 5 — les outils « Kali » : deux sont nos instruments de mesure

Aucun n'entre dans le produit. Mais **deux sont déjà, dans les faits, nos instruments de preuve** :

| Outil | Notre usage **réel** |
|---|---|
| **Nmap** | c'est **T-05a** : prouver **depuis une autre machine** que NexBSD refuse les ports non déclarés. La règle `block in log all` n'est crue que parce qu'elle a été **mesurée de l'extérieur** |
| **Wireshark / tcpdump** | constater ce qui circule réellement quand un client SMB se connecte |
| les autres (Metasploit, SQLMap, Burp, Aircrack, BeEF, DroidHunter, Social-Engineer Toolkit…) | ❌ **aucun usage** : ils supposent un site web, un réseau Wi-Fi, ou un téléphone — NexBSD n'est rien de tout ça |

**La règle que je m'applique :** un outil offensif a le droit d'exister **sur la machine d'où l'on
mesure** (MINT), **jamais sur la machine mesurée** (NexBSD).

---

## 5. Ce qui a été **construit** aujourd'hui à partir de ces affiches

Une affiche ne vaut que si elle change quelque chose. Affiche 1 nous a donné la question :
**« de quoi aurait besoin quelqu'un qui voudrait nous casser ? »** Retournée, elle devient un
contrôle du produit.

### `scripts/75-verifier-durcissement.sh` — 21 contrôles, exécuté

```
--- 1. SSH — la porte d'administration ---
  [OK]     connexion root par SSH interdite
  [OK]     authentification par mot de passe refusée (clé seulement)
  [OK]     authentification interactive (PAM) refusée
  [ABSENT] aucune liste blanche AllowUsers/AllowGroups

--- 2. Pare-feu — ce qui entre ---
  [OK]     refus par défaut en entrée présent
  [OK]     les refus sont journalisés
  [OK]     boucle locale non filtrée (nécessaire, voir C-46)

--- 3. Services activés au démarrage ---
  [OK]     aucun service non chiffré activé (telnet, ftp, rlogin, rsh, tftp)
  [OK]     SSH désactivé au démarrage (R-13)
  [OK]     NTP activé (indispensable à N-05)

--- 4. Samba ---
  [OK]     aucun partage n'accepte d'invité
  [OK]     map to guest désactivé
  [OK]     mots de passe vides refusés
  [ABSENT] server min protocol non fixé : SMB1 risque d'être accepté
  [OK]     ldap ssl = off mais l'annuaire est sur la boucle locale

--- 5. Authentification et mots de passe ---
  [OK]     pam.d/su restreint
  [ABSENT] aucune politique de mot de passe (login.conf absent)
  [ABSENT] aucun sysctl.conf : pas de durcissement du noyau

--- 6. Hygiène du dépôt (public) ---
  [OK]     aucun mot de passe de laboratoire dans le produit
  [OK]     garde-fou de licence présent

  protections correctes : 17   faiblesses réelles : 0   éléments absents : 4
VERDICT : DURCISSEMENT CONFORME
```

### Le garde-fou a d'abord **crié à tort** — et c'est l'épisode instructif

Premier passage : **2 « faiblesses »**, toutes les deux **fausses** :

| Faux positif | Pourquoi c'était faux |
|---|---|
| « `ldap ssl = off` : mot de passe en clair » | la connexion va à **`ldap://127.0.0.1`** — elle **ne quitte pas la machine**. Crier faiblesse était abusif |
| « un mot de passe de laboratoire subsiste (R-15) » | l'occurrence était dans **`docs/16`, où le problème est raconté**, et dans le motif de recherche du script lui-même. **La documentation a le droit de citer un secret pour expliquer qu'il a été retiré** |

C'est la leçon **M-10** appliquée à moi-même : *un garde-fou qui crie à tort sera ignoré, et alors il
ne protégera plus rien.* Corrigé : le contrôle LDAP distingue **annuaire local** et **annuaire
distant** ; la recherche de secret **exclut la documentation** et **se limite** au produit, aux
scripts et aux preuves.

### Et il est **branché dans la chaîne**, pas seulement écrit

Le travail « CONTRÔLES » du workflow passe de 3 à 4 étapes :

```
1/4 — delta du fork intact        (script 70)
2/4 — registre des acquis conforme (script 72)
3/4 — production simulable         (script 74 --simulation)
4/4 — produit durci                (script 75)   ← NOUVEAU
```

**En mode normal**, les 4 `[ABSENT]` (login.conf, sysctl.conf, AllowGroups, min protocol) **ne font
pas échouer** l'étape : ce sont des travaux à faire, pas des fautes. En mode `--strict`, ils
compteront. C'est la distinction qui rend le contrôle utilisable **pendant** la construction du
produit au lieu de le bloquer.

---

## 6. Affiche 4 — la seule idée d'architecture, et elle est bonne

Les **systèmes immuables** : la racine du système ne peut pas être modifiée. Quinze distributions
citées — **toutes Linux**, donc **aucune ne peut héberger NexBSD**. Ce n'est pas la liste qui
compte, c'est **le principe**.

**Pourquoi ce principe intéresse un remplacement de NetWare :** un serveur de fichiers change
**très rarement**. Sa configuration est posée à l'installation. Si la racine est **en lecture
seule**, alors un Samba compromis **ne peut pas** :
- remplacer un binaire par une porte dérobée **persistante** ;
- modifier `pf.conf` pour ouvrir un port ;
- ajouter un compte dans `/etc/master.passwd`.

**Et FreeBSD possède déjà toutes les pièces** — ce qui est décisif, parce que nous n'avons pas à
inventer :

| Pièce FreeBSD | Ce qu'elle donne |
|---|---|
| **racine en lecture seule** (`zfs set readonly=on`) | rien ne peut écrire dans le système |
| **environnements de démarrage** (`bectl`) | mise à jour = nouveau jeu de données, **retour arrière atomique** si elle échoue |
| **`kern.securelevel`** | interdit de charger un module noyau ou de modifier les règles de pare-feu après le démarrage |
| **jails** | isoler un service compromis |
| **`/etc` sur un jeu de données séparé et petit** | la configuration est versionnée et inspectable |

**Ce que cela donnerait, concrètement :** un NexBSD dont le système est **une photo** — reproductible,
vérifiable par empreinte, et **restaurable en une commande** en cas de doute. C'est aussi la réponse
la plus honnête à la question « comment un administrateur répare un serveur qu'il ne peut plus
modifier ? » : avec `bectl`, il **remplace** la photo au lieu de la rafistoler.

**Je ne décide pas seul.** Ce changement touche l'architecture : il fait l'objet d'**ADR-0021**, au
statut **proposition**, à trancher par le responsable (règles R-10/R-11).

**Et une limite à dire tout de suite :** une racine en lecture seule **ne remplace pas** un durcissement.
Elle empêche la **persistance**, pas l'**exécution** : un Samba compromis tourne quand même. C'est une
couche, pas un rempart.

---

## 7. Récapitulatif des décisions

| Affiche | Décision |
|---|---|
| 1 — casseurs de mots de passe | ❌ **jamais dans le produit** ; a servi à écrire `scripts/75` |
| 2 — bureau à distance | ⚠️ doublon ; décision déjà prise (A-70 : **xrdp**) |
| 3 — cybersécurité IA | ✅ **Suricata** et **osquery** candidats pour N-09 ; 6 écartés |
| 4 — immuables | ✅ **principe retenu**, mise en œuvre proposée en **ADR-0021** |
| 5 — outils Kali | ❌ dans le produit ; **Nmap et tcpdump** restent nos instruments de mesure, sur MINT seulement |

**Acquis : A-71** (`scripts/75` + étape CI 4/4) · **A-72** (tri des cinq affiches) · **C-48**
(nouveau, voir registre : quatre éléments absents dont l'absence de politique de mot de passe).
