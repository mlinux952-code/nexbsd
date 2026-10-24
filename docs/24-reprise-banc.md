# Reprise du banc — mode opératoire en 5 étapes

**Version :** 1.0 — 2026-10-24 (session S-014)
**But :** repartir d'un état propre sans dépendre de la conversation, et arriver à **T-04** sans copier-coller dans la fenêtre graphique.

> **Règle de méthode adoptée le 2026-10-24 :** toute instruction destinée au banc de test doit être **courte, vérifiable et rejouable**. Une commande = une sortie attendue. Si une étape produit autre chose que l'attendu, on s'arrête et on lit l'erreur.

---

## Étape 0 — état de départ (à vérifier, 30 secondes)

| Élément | Attendu |
|---|---|
| VM `nexbsd-test` dans virt-manager | présente (éventuellement arrêtée) |
| Image | `~/nexbsd-vm/FreeBSD-15.1-RELEASE-amd64-ufs.qcow2` (décompressée) |
| Disque de travail | `~/nexbsd-vm/disque-test.qcow2` (overlay) |
| Dépôt local | `~/Projets/nexbsd` |

Si la VM est arrêtée : la démarrer depuis virt-manager (double-clic sur `nexbsd-test`).

## Étape 1 — mettre le dépôt à jour (bloc unique, côté Mint)

Le dépôt local s'arrête au commit `392541f` ; il en manque une vingtaine. Télécharger d'abord
`nexbsd-depot-2026-10-24-s014.bundle` depuis le dossier Drive « NexBSD », dans `~/Téléchargements`,
puis coller ce bloc dans un terminal Mint :

```bash
cd ~/Projets/nexbsd
sha256sum ~/Téléchargements/nexbsd-depot-2026-10-24-s014.bundle
git remote remove bundle 2>/dev/null
git remote add bundle ~/Téléchargements/nexbsd-depot-2026-10-24-s014.bundle
git fetch bundle main
git merge --ff-only bundle/main
git push
git remote remove bundle
git log --oneline -3
```

**Sortie attendue :** l'empreinte `2aeb18d1…`, puis `Fast-forward`, puis les commits `S-014`, `S-013`.

**Si `fatal: … does not appear to be a git repository`** → le bundle n'est pas là : retélécharger depuis Drive.

## Étape 2 — ouvrir la console dans le terminal (règle le copier-coller)

```bash
virsh --connect qemu:///session list --all
```
Attendu : une ligne avec `nexbsd-test` et son état (`running` ou `shut off`).

```bash
virsh --connect qemu:///session console nexbsd-test
```

- Si la console s'ouvre (invite `login:`) : **c'est gagné**, le copier-coller fonctionne ici.
- Si erreur « no console device » : ajouter le port série — fenêtre de la VM → *Afficher → Détails* →
  **Ajouter du matériel → Périphérique série (pty)** → redémarrer la VM.
- Sortie de la console : **`Ctrl-]`**

## Étape 3 — démarrer le service de fichiers (côté Mint, autre terminal)

```bash
cd ~/Projets/nexbsd
sh scripts/61-servir-vers-vm.sh
```

Il affiche les commandes à taper dans la VM. Laisser tourner.

## Étape 4 — T-04 dans la VM (trois lignes)

Dans la console de la VM (étape 2), en `root` :

```
ifconfig vtnet0 inet
fetch -o /tmp/t04.sh http://10.0.2.2:8000/60-banc-T04-ldap.sh
sh /tmp/t04.sh
```

**Sortie attendue à la fin :** `T-04 : REUSSI - OpenLDAP operationnel, annuaire peuple et interrogeable.`
Sinon : `T-04 : ECHEC PARTIEL` avec les lignes `[ECHEC]` qui disent quoi corriger.

## Étape 5 — consigner le résultat

```bash
cat /tmp/ldapsearch.out
```
Coller cette sortie dans `tests/results/T-04-ldap-annuaire.md` §3 (tableau du journal).

---

## Ce qui ne doit pas arriver

- **Ne jamais** copier un long script dans la fenêtre graphique de virt-manager (tabulations perdues).
- **Ne jamais** taper une commande sans lire la sortie de la précédente.
- **Ne pas** toucher au PC de 2011 : il reste intact jusqu'au test par clé USB (T-02).
- **Ne pas** réutiliser les mots de passe de laboratoire (`adminsecret`) ailleurs.

## Après la session

```bash
cd ~/Projets/nexbsd && git add -A && git commit -m "tests: résultats T-04" && git push
```
