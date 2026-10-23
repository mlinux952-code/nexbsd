# Fiche de recherche — FreeBSD (fondation système)

**Date de vérification :** 2026-10-23
**Statut :** candidat `En étude` → proposition de statut `Candidat retenu pour prototype`
**Rôle visé :** Couche A (base système) — noyau, pilotes, réseau, FS, utilisateurs, sécurité

---

## 1. Faits vérifiés

| Point | Fait | Source |
|---|---|---|
| Version courante | **FreeBSD 15.1-RELEASE**, publiée le 16 juin 2026 | freebsd.org/releases/15.1R/announce |
| Support 15.1 | jusqu'au **31 mars 2027** | idem |
| Support branche | stable/15 jusqu'au **31 décembre 2029** ; stable/14 jusqu'au 30 novembre 2028 | freebsd.org/security |
| Versions également supportées | 14.5-RELEASE (8 sept. 2026, EOL 30 juin 2027) ; 14.4 (EOL 31 déc. 2026) | freebsd.org/security |
| 15.0 | EOL depuis le 30 septembre 2026 — **ne pas déployer** | freebsd.org/releases |
| Architectures 15.x | amd64, aarch64, armv7, powerpc64/le, riscv64 ; **i386, armv6 et powerpc 32 bits retirés** | annonce 15.0-RELEASE |
| IPX | **retiré depuis FreeBSD 11.0** (« Support for the IPX network transport protocol has been removed ») | FreeBSD 11.0 release notes, § Network Protocols |
| SMBv1 noyau | smbfs/SMB1 obsolète, voué à disparaître ; usage de `filesystems/smbnetfs` conseillé | man smbfs(5) |
| Paquets | `pkg` ; base système packagée (pkgbase) en *tech preview* depuis 15.0 | release notes 15.x |
| Ports utiles confirmés | `net/samba416` (défaut, mais **plus maintenu en amont**), `net/samba419`, `net/samba420` (dépréciés), `net/samba422`, `net/samba423`, `net/openldap25-server`, `www/webkit2-gtk` 2.46.6, `www/firefox` (suivi actif) | FreshPorts (pages de ports) |
| Documentation | FreeBSD Handbook : docs.freebsd.org/en/books/handbook | — |

## 2. Points favorables

- Base mûre, licence **BSD 2-clause** permissive : pas d'obligation de copyleft sur le code dérivé — atout majeur pour un projet qui veut rester maître de ses choix de licences.
- Réseau TCP/IP mature, `pf`, `if_bridge`, VLAN, jails (isolation légère), bhyve (virtualisation).
- Outils de compilation et de développement complets, ports bien fournis pour les besoins serveur.
- Cycle de support long et documenté (4 ans par branche stable depuis 15).
- Très bonne documentation officielle en anglais, structurée.

## 3. Points de vigilance (vérifiés)

1. **IPX absent** : toute fonction NetWare historique en IPX natif est impossible sans travail noyau ou implémentation en espace utilisateur. Impact direct sur l'hypothèse H-5.
2. **Wi-Fi** : le support s'améliore (FreeBSD 15.x : « better WiFi support ») mais reste dépendant du jeu de puces ; sur un PC de 2011, un adaptateur Ethernet est le chemin sûr. `[À VÉRIFIER]` sur le matériel réel.
3. **Pilotes graphiques anciens** : accélération 3D incertaine ; il faut prévoir un repli en framebuffer (`scfb`) ou pilote `modesetting`. `[À VÉRIFIER]`
4. **Gestion de l'énergie** : FreeBSD n'a pas d'infrastructure équivalente à celle de Linux pour un appareil sur batterie (suspend/resume, gestion fine des capteurs). C'est un frein structurel au profil mobile.
5. **Compilation lourde** : Samba, WebKitGTK, Firefox sur un disque mécanique et 4 Go de RAM sont des builds très longs. Préférer `pkg`.
6. **Version par défaut de Samba dans les ports** : `samba416` est encore le défaut alors que Samba 4.16 n'est plus maintenu en amont → risque de sécurité si on ne fixe pas explicitement une version récente.

## 4. Ce que FreeBSD ne fournit pas

- Aucun environnement mobile, aucune interface tactile, aucun framework d'applications Web embarqué.
- Aucune pile IPX/NCP.
- Aucun client NetWare.

## 5. Incertitudes restantes

- La version exacte de Samba disponible dans le dépôt de paquets 2026Q4 pour FreeBSD 15.x `[À VÉRIFIER au moment de l'installation]`.
- La présence d'un port OpenLDAP 2.6/2.7 `[À VÉRIFIER]` ; `net/openldap25-server` existe (2.5.20) mais OpenLDAP 2.5 est en fin de vie (cf. fiche OpenLDAP).
- Le comportement de FreeBSD 15.1 sur le PC de 2011 : dépend entièrement de l'identification matérielle non encore réalisée.

## 6. Recommandation

**Retenir FreeBSD 15.1-RELEASE (amd64) comme base du prototype expérimental**, avec :

- une **version figée** dans la documentation à chaque étape ;
- l'usage de **paquets binaires** et non de compilations locales ;
- l'usage de **jails** pour isoler les services réseau (surface d'attaque réduite, cohérent avec la Couche B) ;
- l'acceptation explicite de renoncer à IPX natif.

Ne pas modifier le noyau à ce stade : aucune fonction identifiée à ce jour ne l'exige.

## 7. Sources

| # | Source | URL | Consultée le |
|---|---|---|---|
| 1 | FreeBSD Release Information | https://www.freebsd.org/releases/ | 2026-10-23 |
| 2 | Annonce 15.1-RELEASE | https://www.freebsd.org/releases/15.1R/announce/ | 2026-10-23 |
| 3 | FreeBSD Security Information (EOL) | https://www.freebsd.org/security/ | 2026-10-23 |
| 4 | FreeBSD 11.0 Release Notes (retrait IPX) | https://www.freebsd.org/releases/11.0R/relnotes/ | 2026-10-23 |
| 5 | FreeBSD Handbook | https://docs.freebsd.org/en/books/handbook/ | 2026-10-23 |
| 6 | FreeBSD Platforms (tiers) | https://www.freebsd.org/platforms/ | 2026-10-23 |
| 7 | FreshPorts — net/samba419, net/samba420, www/webkit2-gtk | https://www.freshports.org/net/samba419 / net/samba420 / www/webkit2-gtk | 2026-10-23 |
| 8 | man smbfs(5) | https://man.freebsd.org/cgi/man.cgi?query=smbfs&sektion=5 | 2026-10-23 |
