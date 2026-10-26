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
| Présence sous FreeBSD | **paquet officiel**, éprouvé sur notre banc | à vérifier (`pkg search`) — projet centré Linux | **aucun support FreeBSD réaliste** |
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
3. **Portabilité** : FreeIPA n'a pas de voie FreeBSD réaliste ; l'introduire contredirait ADR-0001.
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
