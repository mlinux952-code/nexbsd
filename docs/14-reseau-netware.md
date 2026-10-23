# Le réseau NexBSD — rôles des quatre composants (aucun abandonné)

**Version :** 1.0 — 2026-10-23
**Statut :** `[PROPOSITION]` — ADR-0017
**Origine :** inquiétude exprimée par le responsable du projet : *« NetWare, MARS_NWE, Samba et OpenLDAP sont les composants du réseau — ou tu vas abandonner notre projet ? »*

**Réponse :** non. **Le réseau façon NetWare est l'ADN de NexBSD et son axe d'identité prioritaire.** Ce qui change, pour chaque composant, c'est **son rôle** — pas sa présence.

---

## 1. Le tableau qui répond à la question

| Composant | Statut | Rôle exact dans NexBSD | Où il vit |
|---|---|---|---|
| **NetWare** | ✅ **conservé — c'est le modèle** | Le **cahier des charges fonctionnel** : identités, droits (trustees), partages, scripts de connexion, administration centralisée, découverte de services. NexBSD se définit par rapport à lui. | Documents + conception (c'est une référence, pas un logiciel) |
| **Samba** | ✅ **conservé — Plateforme** | Les **fonctions modernes** de fichiers et d'impression : SMB3, ACL, intégration clients modernes. C'est la mise en œuvre actuelle des idées NetWare. | `nexbsd-net`, jail dédiée, paquet épinglé ≥ 4.23 |
| **OpenLDAP** | ✅ **conservé — Plateforme** | L'**annuaire** : utilisateurs, groupes, politiques de mots de passe, base d'authentification commune à Samba et aux autres services. | `nexbsd-net`, jail dédiée, version ≥ 2.6 sous condition |
| **MARS_NWE** | ✅ **conservé — mais pas comme brique embarquée** | **Banc d'essai de référence** + **source de spécification** : c'est en le faisant tourner qu'on écrit noir sur blanc *ce que fait réellement un serveur NetWare*. Il nourrit la réimplémentation propre. | Laboratoire isolé (VM Linux, réseau sans passerelle, client DOS) |

**La nuance, et elle est importante :** on ne « colle » pas MARS_NWE dans NexBSD parce que **GPL-2** interdit de le mêler à notre base sous licence permissive, et parce qu'il **exige IPX**, absent de FreeBSD. Mais il reste **la meilleure source d'information disponible** sur le comportement d'un serveur NetWare — et c'est précisément ce dont on a besoin.

---

## 2. Découverte importante de cette session : IPX n'est plus un obstacle absolu

Ma position précédente était : « compatibilité NCP impossible sans IPX ». **C'est faux en partie**, et il faut le corriger.

| Fait vérifié | Source |
|---|---|
| **Depuis NetWare 5, NCP fonctionne nativement sur TCP/IP**, sur le port **524** (TCP et UDP), sans IPX | Wikipédia (IPX/SPX, NCP), HandWiki, doc Novell « NetWare Over TCP/IP » |
| IPX n'est donc **pas** indispensable au protocole applicatif : c'est un transport parmi deux | idem |
| MARS_NWE n'implémente **ni** NetWare/IP **ni** NCP sur IP natif — d'où son impasse | zx.net.nz, README MARS_NWE |
| Novell a **publié** une documentation des NCP (SDK « NetWare Core Protocols », liste des NCP par numéro) | novell.com/documentation/developer ; beta.novell.com/developer/ndk |
| **DOSBox émule IPX sur UDP** (`ipxnet startserver` / `ipxnet connect`, port 213) — un client DOS NetWare devient donc testable sans matériel réseau particulier | DOSBoxWiki, manuel DOSBox, DOSBox-X, DOSBox Staging |
| `ipxgw` permet de relier un réseau IPX réel à des DOSBox | github.com/ksalin/ipxgw |

**Conséquence majeure :** la réimplémentation propre (ADR-0014) doit viser **NCP sur UDP/TCP 524**, pas IPX. On supprime ainsi :
- la nécessité d'écrire une pile IPX noyau ;
- la dépendance à un protocole mort ;
- la contradiction avec ADR-0006 (pas de modification du noyau).

Et on garde IPX **uniquement dans le laboratoire**, via DOSBox, pour parler à MARS_NWE.

---

## 3. Les trois chemins du réseau, du plus sûr au plus ambitieux

```
CHEMIN 1 — FONCTIONS (P0/P1, réalisable maintenant)
  Samba + OpenLDAP + outil d'administration NexBSD
  → « se comporte comme un serveur de fichiers/annuaire NetWare, en moderne »
  → aucun risque juridique, aucun pilote exotique

CHEMIN 2 — RÉFÉRENCE (P2, réalisable sans L3)
  Laboratoire MARS_NWE isolé + client DOS dans DOSBox (IPX sur UDP)
  → produit un document : « spécification de comportement NetWare observée »
  → nourrit CHEMIN 1 et CHEMIN 3

CHEMIN 3 — PROTOCOLE (P3, recherche)
  Réimplémentation NCP sur UDP/TCP 524, en code NexBSD, en espace utilisateur
  → parler NCP à un client réel, sans IPX
  → c'est ce qui rendra NexBSD unique : personne ne fait cela aujourd'hui
```

**Les trois chemins coexistent.** Aucun n'annule les autres. Le chemin 3 ne bloque rien : s'il n'aboutit pas, NexBSD reste cohérent.

---

## 4. Ce que le réseau doit fournir — cahier des charges

| # | Fonction (héritée de NetWare) | Chemin | Priorité | Candidat |
|---|---|---|---|---|
| N-1 | Volumes et partages hiérarchiques | 1 | **P0** | Samba |
| N-2 | Droits par fichier/répertoire, avec héritage lisible | 1 | **P0** | ACL + outil NexBSD |
| N-3 | Utilisateurs, groupes, objets | 1 | **P1** | OpenLDAP |
| N-4 | Annuaire hiérarchique et réplication | 1 | P2 | OpenLDAP syncrepl |
| N-5 | Authentification unique au réseau | 1 | P2 | LDAP + Kerberos / Samba AD |
| N-6 | Scripts de connexion (mapping de lecteurs, imprimantes) | 1 | P1 | logon scripts Samba |
| N-7 | Impression partagée | 1 | P2 | CUPS + Samba |
| N-8 | **Administration centralisée (l'esprit de SYSCON)** | 1 | **P1** | **outil NexBSD à écrire** — c'est notre identité |
| N-9 | Supervision et journaux | 1 | P1 | syslog + moniteur |
| N-10 | Découverte de services (esprit SAP) | 1 | P3 | mDNS/DNS-SD |
| N-11 | **Compatibilité protocolaire NCP** | 3 | P3 (recherche) | réimplémentation NexBSD |

**N-8 est le cœur de l'identité** : SYSCON était l'outil unique d'administration d'un serveur NetWare. Personne n'a d'équivalent simple aujourd'hui. C'est là que NexBSD peut être *meilleur*, pas seulement différent.

---

## 5. Ce que le laboratoire MARS_NWE doit produire (livrable concret)

Montage : une VM Linux isolée (sans passerelle), MARS_NWE + module IPX, un ou deux DOSBox en clients via `ipxnet`.

**Livrable attendu : `docs/spec-netware-observee.md`** contenant, observé et non supposé :
1. La séquence exacte d'une connexion (`login`) et ce qui est échangé.
2. Le modèle de trustees : comment un droit est accordé, hérité, refusé.
3. La structure d'un script de connexion et son effet réel sur le poste client.
4. L'arborescence `SYS:PUBLIC` et ce qu'un client attend d'y trouver.
5. Les différences mesurées avec l'équivalent Samba + OpenLDAP.

**Ce document est le vrai bénéfice du laboratoire** : il transforme MARS_NWE d'un composant impossible en une **source de connaissance exploitable**.

**Règles de sécurité du laboratoire (non négociables) :** réseau sans passerelle, aucune donnée réelle, aucune exposition Internet, instantané de VM jetable après usage.

---

## 6. Ce qui reste à vérifier

| # | Point | Impact |
|---|---|---|
| V-1 | Existence d'un **client** parlant NCP sur port 524 utilisable aujourd'hui (Novell Client historique, client tiers) | conditionne le chemin 3 |
| V-2 | Complétude de la documentation publique des NCP (numéros, structures) | conditionne la réimplémentation |
| V-3 | Faisabilité pratique du montage MARS_NWE + module IPX + DOSBox | conditionne le chemin 2 |
| V-4 | Version OpenLDAP ≥ 2.6 packagée sous FreeBSD | conditionne N-3 |

## 7. Décision proposée (ADR-0017)

1. **Le réseau est l'axe prioritaire du projet**, pas une annexe : les fonctions N-1, N-2, N-6, N-8 sont **P0/P1**.
2. **Samba et OpenLDAP sont les composants retenus** pour les fonctions modernes.
3. **MARS_NWE est conservé comme banc de référence et source de spécification**, jamais comme brique embarquée.
4. **La cible protocolaire est NCP sur UDP/TCP 524**, ce qui supprime la dépendance à IPX (révision d'ADR-0014).
5. **Aucun des quatre composants n'est abandonné** — leurs rôles sont distincts et complémentaires.
