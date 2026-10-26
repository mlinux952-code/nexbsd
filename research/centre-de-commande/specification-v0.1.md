# Centre de commande NexBSD — spécification v0.1 (recherche)

**Date :** 2026-10-26 · **Statut :** proposition de recherche, **non implémentée**, **non planifiée**
**Source :** apport extérieur n° 2 (`docs/37`) + demande du responsable d'y consacrer un couloir de recherche.
**Rattachement produit :** Couche **D-4** (administration) et Couche **E** (outil d'administration unique).

---

## 1. Le besoin, formulé une seule fois

> Administrer des machines **hétérogènes** — PC, serveurs, équipements réseau, appareils embarqués — depuis
> **un seul point**, avec **les identités et les droits de l'annuaire NexBSD**, et sans introduire de
> composant lourd sur le PC faible (ADR-0009).

C'est l'**esprit NetWare** généralisé : un serveur qui connaît les gens et décide qui peut quoi ; des postes
qui ne demandent qu'à obéir ; un administrateur qui n'a pas dix consoles différentes.

## 2. La règle d'or (empruntée à l'apport extérieur, adoptée)

> **Une commande commune ne signifie pas que toutes les machines utilisent le même système.**

Corollaires, non négociables :

1. **Aucun noyau ne pilote directement un appareil d'une autre famille.** On passe par un protocole.
2. Une capacité absente sur la cible est **annoncée absente**, avec la raison. **Jamais simulée.**
3. Toute action est **attribuée** à une identité de l'annuaire et **journalisée**.
4. Le hub est une couche **haute** : jamais dans la base, jamais dans le noyau.

## 3. Modèle en quatre étages

```
4. EXPERIENCE      une seule grammaire de commandes, en texte (clavier, pas de souris)
3. HUB             inventaire · planification · exécution · journal d'audit
2. ADAPTATEURS     un par famille de cible : SSH · HTTP/API · MQTT · série · protocoles documentés
1. CIBLES          PC (FreeBSD/Windows/Linux) · serveurs · routeurs · imprimantes · embarqué
```

**L'étage 2 est le cœur du coût.** Un adaptateur mal écrit est une porte dérobée ; un adaptateur absent
n'est pas un échec, c'est un périmètre.

## 4. Grammaire de commandes (esquisse, non figée)

```
nex cible lister
nex cible inspecter <nom>
nex reseau etat <nom>
nex fichiers sauver <nom> --quoi=<chemin>
nex tache lancer <nom-de-tache>
nex audit --depuis=<date> --par=<identite>
```

**Règles de la grammaire :**
- un verbe, une cible, des options explicites — pas de raccourcis implicites ;
- toute commande destructive exige un **drapeau explicite** (`--confirmer`) ;
- la sortie est lisible par un humain **et** par un script (`--json`) ;
- le **code de retour** reflète la réalité (0 = fait, non nul = refusé/impossible/échoué), jamais 0 par politesse.

## 5. Identité et droits — le lien avec ce qui existe déjà

C'est ici que NexBSD a un avantage réel : **l'annuaire existe et fonctionne** (T-04-G, 11/11).

| Élément | Source | État |
|---|---|---|
| Qui peut exécuter quoi | groupes de l'annuaire (`bureau`, `stagiaires`) | **existe** |
| Sur quelle cible | à définir (attribut de machine / groupe de machines) | **à concevoir** |
| Traçabilité | journal d'audit, identité + horodatage UTC | **à concevoir** |
| Refus explicite | message + raison + code de retour | **à concevoir** |

**Décision de recherche :** les droits du hub doivent être **les mêmes identités** que celles de Samba et de
NSS — un seul annuaire, pas deux. Sinon on crée la complexité qu'on prétend supprimer.

## 6. Ce que le hub **ne fait pas** (périmètre négatif)

- il ne remplace pas un hyperviseur ;
- il ne promet pas de piloter un appareil sans protocole documenté (ni « par miracle ») ;
- il n'exécute pas de commandes arbitraires en root sans politique explicite ;
- il ne collecte pas de télémétrie à l'insu de l'utilisateur ;
- il ne devient **pas** la priorité avant que NexBSD s'installe sur un PC nu.

## 7. Le prototype minimal qui aurait de la valeur (quand ce sera le moment)

> **Une seule cible, une seule commande, un vrai journal.**
> Exemple : `nex cible inspecter nexbsd` → lit l'état réel de la machine (version noyau, services,
> espace disque) et l'écrit dans le journal d'audit avec l'identité de l'appelant.

Pourquoi ce prototype et pas un autre : il **utilise l'existant** (SSH local, annuaire, journal), il ne
demande **aucun** nouveau composant, et il prouve la chaîne complète *identité → autorisation → action →
trace*. Si cette chaîne ne tient pas, tout le reste est décoratif.

## 8. Estimation honnête

| Élément | Effort | Verdict |
|---|---|---|
| Prototype « une cible, une commande, un journal » | 1 à 2 jours | réalisable sans risque |
| Adaptateurs SSH (PC/serveurs) | 1 semaine | raisonnable |
| Adaptateurs réseau (selon équipement) | très variable | **à borner par équipement** |
| Adaptateurs embarqués (MQTT) | 1 semaine pour un cas | à ne pas ouvrir avant un besoin réel |
| Console clavier complète | plusieurs semaines | **après** le système installable |

**Conclusion :** la partie qui apporte de la valeur coûte **jours**, pas mois. La partie qui coûte des mois
est celle qui **ne prouve rien** (la console complète). C'est cette disproportion qu'il faut retenir.
