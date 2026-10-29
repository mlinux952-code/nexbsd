# 61 — « Free Remote Desktop Tools » : ce que l'affiche mélange, et le seul choix qui convient à NexBSD

> **Message du responsable (2026-10-29, en déplacement) :** *« j'ai continué la recherche puisque je ne
> suis pas à la maison, j'ai laissé NexBSD télécharger et je suis sorti. »* — puis cette affiche.
> Compte tenu du téléchargement en cours, `docs/61` a été rédigé **sans lancer d'exécution**.
>
> **Réponse courte :** l'affiche liste **15 outils** mais **confond clients et serveurs**, et classe
> quatre d'entre eux dans la catégorie qui **ne convient pas à une entreprise** : ceux qui font
> passer votre session par le serveur d'un tiers. Pour un annuaire d'entreprise, c'est rédhibitoire.
>
> **Et une découverte utile :** `net/xrdp` **existe dans les ports FreeBSD**, et notre session
> `nexbsd-session` est déjà invocable par son nom. Les deux s'emboîtent — c'est la réponse à
> **N-08** (administrer sans terminal).

---

## 1. Le défaut principal de l'affiche : clients et serveurs dans le même sac

Un « outil de bureau à distance » est **deux choses** qui ne s'installent pas du même côté :

- le **serveur** : il tourne sur la machine qu'on veut voir (ici : NexBSD) ;
- le **client** : il tourne sur la machine d'où l'on regarde (le PC de l'administrateur).

L'affiche les range ensemble. Résultat, en regardant de près :

| Outil de l'affiche | Ce que c'est **réellement** |
|---|---|
| **FreeRDP** | un **client** RDP (il ne sert rien sur un serveur) |
| **Remmina** | un **client**, rien d'autre — et il apparaît **deux fois** (Self-Hosted *et* Enterprise) |
| **Guacamole** | une **passerelle serveur** (web), classée « General Access » comme s'il s'agissait d'un client |
| **Xpra** | un **outil de session détachée**, pas un bureau distant classique |
| **Windows App** | le **client** Microsoft (ex-« Remote Desktop ») |
| **AnyDesk, TeamViewer, RustDesk, HopToDesk** | client **+** passage par l'**infrastructure du fournisseur** |
| **TigerVNC, TightVNC, TurboVNC, UltraVNC** | **serveur + client** VNC |
| **xrdp** *(absent de l'affiche)* | le **serveur** RDP pour Unix — le seul qui manque et qui compte |

**Conséquence pratique :** sur les 15 lignes, **5 ne sont que des clients**. Les installer sur
NexBSD n'apporterait **strictement rien**.

---

## 2. Le tri qui compte : ce qui existe pour FreeBSD

C'est le seul critère qui décide, et l'affiche ne le donne pas.

| Outil | Existe pour FreeBSD ? | Verdict pour NexBSD |
|---|---|---|
| **xrdp** | ✅ `net/xrdp` | **RETENU** (voir §4) |
| **TigerVNC** | ✅ `net/tigervnc-server` | **RETENU** comme secours |
| **FreeRDP** | ✅ `net/freerdp` | client seulement — utile **hors** du produit |
| **Guacamole** | ⚠️ existe, mais impose **Java + Tomcat** | **ÉCARTÉ** : trop lourd pour le profil « PC faible » (`docs/09`) |
| **UltraVNC, TightVNC, TurboVNC** | ❌ Windows/Linux seulement | **ÉCARTÉS** : impossibles |
| **X2Go, Xpra** | ❌ pas dans les ports | **ÉCARTÉS** |
| **Remmina, Windows App** | ❌ clients | **ÉCARTÉS** |
| **AnyDesk, TeamViewer, RustDesk, HopToDesk** | ❌ / ⚠️ | **REFUSÉS** (voir §3) |

---

## 3. Pourquoi les quatre « pratiques » sont **refusés** — et c'est le point important

AnyDesk, TeamViewer, RustDesk et HopToDesk ont une chose en commun : **la session passe par un
serveur qui ne vous appartient pas.** Vous vous connectez, et vos images d'écran, vos frappes de
clavier — **y compris le mot de passe root saisi à l'écran** — traversent l'infrastructure d'une
société tierce, dans un pays que vous ne choisissez pas.

Pour un serveur de fichiers d'entreprise qui détient **l'annuaire des identités** (OpenLDAP), c'est
une faute de conception, pas un détail :

| Motif | Détail |
|---|---|
| **Souveraineté** | les données d'authentification sortent de l'entreprise |
| **Traçabilité** | impossible de prouver *qui* a relayé quoi |
| **Disponibilité** | si le fournisseur tombe, votre administration tombe avec lui |
| **Licence** | AnyDesk et TeamViewer sont **propriétaires** ; **RustDesk est en GPL-3.0** — donc **interdit dans notre dépôt** (règle du projet : aucune GPL tierce dans le dépôt) |
| **Coût caché** | un usage professionnel est facturé |

**Décision : aucun relais tiers, jamais.** L'administrateur de NexBSD se connecte **directement à
la machine**, sur son réseau. Comme avec NetWare : on est sur le réseau, ou on n'est pas.

---

## 4. Ce que NexBSD retient : **xrdp**, et il s'emboîte déjà dans ce qui existe

`net/xrdp` est le serveur RDP libre pour Unix. Pourquoi c'est le bon choix, et pas un autre :

1. **Zéro installation côté Windows.** Toute machine Windows a déjà un client RDP (`mstsc`).
   L'administrateur n'installe rien. C'est exactement l'esprit de NetWare : *on s'assoit, ça marche*.
2. **Il parle RDP, donc il chiffre** (TLS), contrairement à VNC.
3. **Il existe dans les ports FreeBSD** — vérifié : `cd /usr/ports/net/xrdp && make install clean`.
4. **Et surtout : il démarre la session de notre choix.** xrdp lance `startwm.sh` ; notre session
   est **déjà** déclarée comme un bureau X :

```
fork/overlay/usr-local-share-xsessions/nexbsd.desktop
  Name=NexBSD
  Exec=/usr/local/bin/nexbsd-session
```

**Donc : `startwm.sh` → `exec /usr/local/bin/nexbsd-session` → openbox + notre bureau.**

Un administrateur sous Windows ouvre « Connexion Bureau à distance », tape l'adresse de NexBSD, et
voit **le bureau NexBSD** — celui de la couche C, avec son écran d'ouverture de session qui exige
un mot de passe (`nexbsd-authentifier.sh`), son contrôle de vulnérabilités (`A-67`) et, à terme, les
lecteurs réseau (`A-68`).

**C'est la réponse à N-08 :** administrer NexBSD sans terminal, depuis n'importe quel poste, **sans
rien installer sur le poste**. Et cela **réutilise** quatre pièces déjà écrites et testées, au lieu
d'ajouter un composant.

---

## 5. Les trois règles de sécurité, non négociables

| Règle | Pourquoi |
|---|---|
| **Ne jamais exposer 3389 ni 5900 en direct** | un RDP ouvert sur Internet est scanné **en quelques minutes**, puis attaqué en force brute. C'est la première cause de rançongiciels sur les serveurs |
| **Passer par un tunnel SSH** | `ssh -L 3389:localhost:3389 admin@nexbsd` : il faut déjà avoir une clé SSH (A-14) pour atteindre RDP. **Deux serrures au lieu d'une** |
| **VNC = jamais sans tunnel** | VNC ne chiffre pas, et son mot de passe est **tronqué à 8 caractères** : ce n'est pas une authentification, c'est une formalité |

**Concrètement pour NexBSD :** `xrdp.ini` doit écouter sur `tcp://127.0.0.1:3389`, et non sur `0.0.0.0`.
Notre `pf.conf` n'ouvre **déjà** ni 3389 ni 5900 — et c'est bien ainsi.

---

## 6. Ce que je **n'ai pas** fait, et pourquoi

**Je n'ai ajouté aucune règle à `pf.conf`, aucun fichier `xrdp.ini`, aucun script.** Raison, et
c'est votre propre règle :

> **« Ce qui n'est pas dans l'image n'est pas dans le produit ; une configuration que rien
> n'applique n'y est pas non plus. »**

Écrire maintenant un `xrdp.ini` que **ni l'exécution #18 ni aucune autre** n'installe reproduirait
exactement la faute dénoncée dans `docs/57` : de la documentation déguisée en produit. Ce document
est donc une **décision écrite**, pas une livraison.

**Ce que la livraison demandera, le moment venu :**
1. `pkg install xrdp` dans `fork/80-installer-nexbsd.sh` ;
2. `xrdp_enable="YES"` et `xrdp_sesman_enable="YES"` dans `rc.conf` ;
3. `startwm.sh` → `exec /usr/local/bin/nexbsd-session` ;
4. `xrdp.ini` : `port=tcp://127.0.0.1:3389` ;
5. une entrée `rc.conf.defaults` et un test T-23 « RDP ouvre le bureau NexBSD ».

**Et rien avant que l'image ne démarre.** L'ordre est : **allumer d'abord, ajouter ensuite.**

---

## 7. Le trou nommé : **C-47**

Aujourd'hui, NexBSD n'offre **aucun moyen d'administration à distance autre que SSH en ligne de
commande**. `docs/54` le classe **N-08**, non commencé. L'affiche du responsable ne l'a pas créé,
mais elle a rendu le trou visible — et elle a fourni la pièce qui le bouchera.

**Acquis : A-70.**

---

## 8. Ce que l'affiche nous apprend, en une phrase

> **Cinq des quinze outils ne sont que des clients, quatre font passer votre session chez un tiers,
> et celui qui manque — xrdp — est précisément celui qui s'emboîte dans ce que nous avons déjà écrit.**
