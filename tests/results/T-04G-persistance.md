# T-04-G — Le banc revient seul après redémarrage — **À EXÉCUTER**

**Protocole exécutable :** `scripts/64-banc-T04G-persistance.sh`, en **deux phases** (`avant` puis `apres`).
**Prérequis :** T-04 (annuaire), T-04-E (authentification par l'annuaire) et T-04-F (droits par groupes) réussis — acquis le 2026-10-24.
**Banc :** VM `nexbsd-test`, FreeBSD 15.1-RELEASE, Samba `samba423-4.23.11_3`, OpenLDAP + `samba.schema`.

## 1. Pourquoi ce test maintenant

Tout ce que le banc sait faire depuis T-04 a été obtenu par des **commandes tapées à la main**, service par
service. Or un serveur — et *a fortiori* un système d'exploitation — doit **revenir seul** après une coupure
de courant. Un banc qui exige trois scripts et un redémarrage manuel n'est pas encore une brique du produit :
c'est une démonstration.

T-04-G est donc la charnière entre « ça marche quand je le lance » et « ça marche tout le temps ». Il ne
fabrique rien de nouveau : il **contrôle** que l'existant survit de lui-même.

## 2. Ce que le test doit démontrer — 11 contrôles

| # | Contrôle | Pourquoi il compte |
|---|---|---|
| R0 | la machine a **réellement redémarré** (instant de démarrage différent) | sans redémarrage, le test ne prouve rien |
| R1 | `slapd` tourne sans commande manuelle | l'annuaire est un service du système, pas une session |
| R2 | `smbd` **écoute** sur `:445` sans commande manuelle | idem pour le service de fichiers |
| R3 | aucun entrée LDAP perdue (comptage avant/après) | les données sont sur disque, pas en mémoire |
| R4 | `sara` garde son `sambaSID` | l'identité est persistante |
| R5 | l'appartenance `omrane → bureau` est conservée | les droits reposent sur elle |
| R6 | le fichier témoin écrit avant redémarrage est retrouvé | les partages écrivent bien sur le disque |
| R7 | les droits POSIX des partages sont inchangés | la configuration est reproductible |
| R8 | `omrane` **écrit** toujours dans `[commun]` | le service est réellement utilisable |
| R9 | `sara` est **toujours refusée** dans `[commun]` | les droits survivent au redémarrage |
| R10 | `sara` lit le témoin par le réseau | le partage n'est pas seulement « démarré », il fonctionne |

## 3. Mode opératoire (deux temps, un redémarrage)

```
sh /tmp/t04g.sh avant      # relève l'état, arme les services, écrit /root/nexbsd-t04g-etat.txt
cp /tmp/t04g.sh /root/t04g.sh
reboot
sh /root/t04g.sh apres     # contrôle et verdict
```

L'état de référence est écrit dans `/root/nexbsd-t04g-etat.txt` : il survit au redémarrage, contrairement
à `/tmp` qui peut être vidé.

**Point de méthode :** la phase `avant` **arme** les services si nécessaire (`sysrc … =YES`) — c'est un
prérequis du test, pas son résultat. Le test porte sur ce qui se passe **après** le redémarrage, sans
intervention.

## 4. Journal d'exécution

### Essai 1 — à exécuter

_(vide)_

## 5. Verdict

**NON EXÉCUTÉ** — protocole écrit et vérifié syntaxiquement le 2026-10-24, jamais passé sur le banc.
