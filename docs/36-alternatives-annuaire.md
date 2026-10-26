# Alternatives à l'annuaire : 389 Directory Server, FreeIPA — et pourquoi on garde OpenLDAP

**Date :** 2026-10-26 · **Origine :** remarque du responsable — *« il y a des alternatives à MARS_NWE comme
FreeIPA et 389 Directory Server »*

---

## 1. Mise au point : ce ne sont pas des alternatives à MARS_NWE

| Logiciel | Ce qu'il fait | Famille |
|---|---|---|
| **MARS_NWE** | **serveur de fichiers** émulant NetWare : volumes, trustees, login, bindery — sur IPX | service de fichiers |
| **OpenLDAP** | **annuaire d'identités** (LDAP) : utilisateurs, groupes, attributs | annuaire |
| **389 Directory Server** | **annuaire d'identités** (LDAP), ex-Fedora DS, lignée Netscape DS | annuaire |
| **FreeIPA** | **suite d'identités intégrée** : 389 DS + Kerberos + autorité de certification + SSSD + outils | suite d'annuaire |

**Conclusion :** 389 DS et FreeIPA sont des alternatives à **OpenLDAP** (l'annuaire), **pas** à MARS_NWE
(le service de fichiers). MARS_NWE n'a aujourd'hui **aucun** équivalent moderne : c'est précisément pourquoi
ADR-0018 propose de réécrire un sous-ensemble de **NCP sur le port 524** nous-mêmes.

## 2. Les trois chemins possibles pour l'annuaire

| Critère | **OpenLDAP** (retenu) | **389 DS** | **FreeIPA** |
|---|---|---|---|
| Poids sur un PC faible | **léger** (un seul démon `slapd`) | moyen | **lourd** : Kerberos KDC + Dogtag CA + SSSD + DS |
| Présence sous FreeBSD | **paquet officiel**, éprouvé sur notre banc | **`389-ds-base-3.2.3` existe** dans les dépôts | **`freeipa-server-4.13.4` et `freeipa-client-4.13.1` existent** dans les dépôts |
| Intégration Samba | `ldapsam` — **déjà prouvée 11/11** sur notre banc | possible, non éprouvée ici | passerait par Samba AD DC, donc redondant |
| Licence | permissive (OpenLDAP Public License) | GPL-3 → **couche Platform uniquement** | GPL → Platform uniquement |
| Coût de changement | **zéro** : il tourne | élevé : revalider T-04 → T-04-G | très élevé |
| Gain attendu | — | interface d'administration web | confort « tout-en-un » |

## 3. Décision — et ses conditions de révision

**On garde OpenLDAP.** Raisons, dans l'ordre :

1. **Il fonctionne, et c'est prouvé** : annuaire, identités dérivées (NSS), droits par groupe, persistance
   après coupure (T-04-G, 11/11, deux fois, dont une sur notre noyau). Changer maintenant détruirait une
   preuve pour un gain non démontré.
2. **Poids** : ADR-0009 vise un PC faible ; FreeIPA ajoute un KDC, une AC, un service de cache.
3. **Portabilité** : FreeIPA **est** disponible sous FreeBSD (`freeipa-server-4.13.4`), je l'avais écrit à tort — mais il apporte un KDC Kerberos, une autorité de certification Dogtag et SSSD, soit trois services de plus à faire tourner sur un PC à 3,7 Go de RAM.
4. **Il n'y a pas de problème à résoudre.** Remplacer un composant n'a de sens que s'il échoue : ce n'est
   pas notre cas.

**Ce qui serait réexaminé, et quand :**
- si le besoin d'une **administration web** de l'annuaire devient réel → regarder 389 DS d'abord,
  mais **dans la couche Platform** (GPL) ;
- si OpenLDAP devient indisponible ou non maintenu sous FreeBSD ;
- si l'on visait un jour l'interopérabilité **Active Directory** → la bonne réponse serait alors
  **Samba AD DC** (déjà présent chez nous), pas FreeIPA.

## 4. Vérification à faire (preuve, pas opinion)

Sur la VM, sans rien installer :

```
pkg search -x "389|freeipa|samba4|openldap" ; pkg info | grep -Ei "samba|ldap"
```

Ce que l'on cherche : 389 DS et FreeIPA sont-ils **seulement disponibles** sous FreeBSD 15.1 ? La réponse
sera consignée ici avec la sortie verbatim, quelle qu'elle soit. Si `pkg search` ne trouve rien, la question
est close pour des raisons factuelles, pas par préférence.

---

## 5. Vérification faite le 2026-10-26 — sortie verbatim

```
root@nexbsd:/build/src # pkg search -x "389|freeipa|openldap" | head -20

389-ds-base-3.2.3              Enterprise-class LDAP directory server
ap24-freeipa-auth-gssapi-1.6.5 Apache mod_auth_gssapi built against MIT krb5 for FreeIPA
freeipa-client-4.13.1_2        FreeIPA Client tools
freeipa-server-4.13.4          FreeIPA server
intel-nvmupdate-e810-lenovo-4.90.1.3897.0 NVM update utility for Lenovo Intel E810 adapters
linux-c7-openldap-2.4.44_3     LDAP libraries (Linux CentOS 7.9.2009)
linux-rl9-openldap-2.6.8       LDAP libraries (Rocky Linux 9.8)
nagios-openldap-plugins-0.5_1  Nagios Plugins to monitor OpenLDAP
openldap25-client-2.5.20_3     Open source LDAP client implementation
openldap25-server-2.5.20_3     Open source LDAP server implementation
openldap26-client-2.6.15_1     Open source LDAP client implementation
openldap26-server-2.6.15_1     Open source LDAP server implementation
openldap27-client-2.7.1        Open source LDAP client implementation
openldap27-server-2.7.1        Open source LDAP server implementation
py312-lib389-3.2.3             Python library and administration tools for 389 Directory Server
```

### Rectification — mon affirmation précédente était fausse

J'avais écrit que FreeIPA n'avait « aucun support FreeBSD réaliste ». **C'est faux** : `freeipa-server-4.13.4`
et `freeipa-client-4.13.1_2` existent dans les dépôts FreeBSD 15.1, tout comme `389-ds-base-3.2.3` et
`py312-lib389`. La disponibilité n'est donc **pas** un argument — je le corrige ici, sans le noyer.

### La décision tient, mais sur d'autres fondements

| Argument | Valeur après vérification |
|---|---|
| ~~« indisponible sous FreeBSD »~~ | **retiré** — c'est faux, les paquets existent |
| « il fonctionne et c'est prouvé » | **le seul argument qui compte** : 11/11, deux fois, dont sur notre noyau |
| « poids » | **valable** : FreeIPA = DS + KDC + AC Dogtag + SSSD ; 3,7 Go de RAM au total |
| « pas de problème à résoudre » | **valable** : on ne remplace pas ce qui n'échoue pas |

### Ce qui devient possible, et à quelle condition

Puisque **389 DS et FreeIPA sont disponibles**, ils passent du statut « impossibles » à celui d'**options
réelles**. Règle appliquée : ce sont des composants **GPL** → couche **Platform** uniquement, jamais la base.
Et ils ne seront examinés que si un besoin apparaît :

1. besoin d'une **console d'administration** de l'annuaire → **389 DS** est le candidat le plus léger ;
2. besoin d'**authentification unique** (Kerberos/SSO) entre les postes → **FreeIPA** devient pertinent ;
3. besoin d'interopérabilité **Active Directory** → **Samba AD DC**, pas FreeIPA.

**Aucun de ces trois besoins n'existe aujourd'hui.** L'annuaire actuel sert des identités et des droits :
il fait le travail. La question reste donc **ouverte et documentée**, pas fermée.
