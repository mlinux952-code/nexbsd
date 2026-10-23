# Étude de faisabilité — état et cadre

**Version :** 0.1 — 2026-10-23 — `[PROVISOIRE]`
**Rôle :** livrable 3 du méga-prompt.

> ⚠️ **Ce document n'est PAS une étude de faisabilité concluante.** C'est le cadre de l'étude, avec ce qui est déjà établi et ce qui manque pour conclure. Conclure ici serait une faute : les trois tests décisifs (absence de faits vérifiés, aucune exécution) n'ont pas été exécutés.

---

## 1. Les quatre axes de faisabilité

| Axe | Question | Réponse actuelle | Preuve |
|---|---|---|---|
| **Technique — base** | FreeBSD peut-il tourner sur le matériel cible ? | **probable, non vérifié** | T-01/T-02 non exécutés |
| **Technique — fork** | peut-on produire un système propre, à son nom ? | **oui dans le principe, coût élevé** | `docs/11-fork-pas-surcouche.md`, ADR-0011 |
| **Technique — réseau** | peut-on fournir fichiers/comptes/droits sans Internet ? | **oui, briques existantes** | Samba 4.25, OpenLDAP 2.7.1 (`research/`) |
| **Technique — NCP** | peut-on parler le protocole NetWare ? | **plausible, non démontré** | `research/ncp-ip/fiche.md` : V-1 résolu, V-2/V-3 en suspens |
| **Juridique** | peut-on publier ? | **probable avec précautions** | `matrices/licences.csv`, ADR-0012/0016 ; antériorité du nom non vérifiée |
| **Économique** | coût de développement ? | **non chiffré** | aucun devis, non demandé à ce stade |

## 2. Ce qui est déjà solide

1. **Aucune brique n'est à inventer** : FreeBSD, Samba, OpenLDAP existent, sont maintenus et licenciés de façon compatible avec une séparation base/plateforme.
2. **Le chemin protocolaire NCP n'est plus théorique** : un client réel, gratuit et maintenu existe (ADR-0019), et le protocole passe sur TCP/UDP 524 sans IPX (ADR-0018).
3. **Le précédent HardenedBSD** montre qu'un fork de FreeBSD tenu par très peu de personnes est possible — tout en montrant son coût (2 personnes, installateur fragile).

## 3. Ce qui manque pour conclure

| Manque | Test / action | Débloque |
|---|---|---|
| Matériel du PC de 2011 inconnu | `docs/hardware.md` §2 + §3 | tout |
| Aucun démarrage FreeBSD observé | T-01 (VM) puis T-02 (matériel, support externe) | faisabilité technique de base |
| Aucun partage Samba observé | T-03 | faisabilité du cœur fonctionnel |
| NCP jamais implémenté ni testé | T-09 (banc B) | faisabilité de la différenciation |
| Coût du fork non estimé | à chiffrer après J4 | viabilité à long terme |
| Antériorité du nom | recherche | publication |

## 4. Critères de conclusion (à remplir plus tard)

L'étude sera déclarée **concluante positivement** si, et seulement si :
- [ ] FreeBSD 15.x démarre sur le matériel cible avec ≤ 256 Mo de RAM au repos *(mesuré)*
- [ ] un partage Samba authentifié par l'annuaire fonctionne entre 2 machines *(mesuré)*
- [ ] au moins **NCP-1 → NCP-3** fonctionnent contre le client de référence *(mesuré)*
- [ ] une image NexBSD est construite par le projet et **démarre** *(mesuré)*
- [ ] aucune contrainte de licence bloquante n'est identifiée

**Score actuel : 0 / 5.** Ce n'est pas un échec : c'est le point de départ, trois semaines après le début de la conception.

## 5. Risque de l'étude elle-même

Le principal risque est **méthodologique** : transformer cette page en plaidoyer. La règle R-10 et le registre des problèmes (`docs/16-registre-problemes.md`) existent pour l'empêcher.
