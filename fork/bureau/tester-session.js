#!/usr/bin/env node
// NexBSD — test de la logique de session du bureau. 2026-10-28.
//
// POURQUOI CE FICHIER EXISTE
//   La logique « qui peut entrer » est la partie la plus dangereuse du bureau : si elle se trompe,
//   le bureau s'ouvre sans authentification. On ne peut pas la tester en ouvrant un navigateur à la
//   main. Ce fichier extrait les FONCTIONS PURES du HTML (entre les marqueurs DEBUT/FIN-FONCTIONS-
//   TESTABLES), les exécute dans Node, et vérifie 12 cas — y compris les cas hostiles.
//
// USAGE : node fork/bureau/tester-session.js
// SORTIE : une ligne par cas, puis un verdict. Code de sortie 0 = tout passe, 1 = échec.

"use strict";

const fs = require("fs");
const path = require("path");

const HTML = path.join(__dirname, "nexbsd-bureau.html");
const source = fs.readFileSync(HTML, "utf8");

const iDebut = source.indexOf("DEBUT-FONCTIONS-TESTABLES");
const iFin = source.indexOf("FIN-FONCTIONS-TESTABLES");
if (iDebut < 0 || iFin < 0) {
  console.error("[ECHEC] marqueurs DEBUT/FIN-FONCTIONS-TESTABLES introuvables dans le HTML.");
  process.exit(1);
}
// Les marqueurs vivent DANS des commentaires /* … */ : on coupe donc au commentaire fermant
// qui suit le marqueur de début, et au début de la ligne du marqueur de fin. Premier essai raté
// (2026-10-28) : couper au marqueur lui-même laissait « DEBUT-FONCTIONS-TESTABLES ===== » dans le
// code extrait, donc une erreur de syntaxe. On vérifie donc que l'extrait est plausible.
const fermeture = source.indexOf("*/", iDebut);
if (fermeture < 0 || fermeture > iFin) {
  console.error("[ECHEC] le bloc de commentaire du marqueur de début n'est pas fermé avant la fin.");
  process.exit(1);
}
const debutLigneFin = source.lastIndexOf("\n", iFin);
const extrait = source.slice(fermeture + 2, debutLigneFin);
if (extrait.indexOf("function lireSession") < 0 || extrait.indexOf("function utilisateurValide") < 0) {
  console.error("[ECHEC] l'extrait ne contient pas les deux fonctions attendues.");
  process.exit(1);
}

// On rend les fonctions accessibles hors du fichier.
const fabrique = new Function(extrait + "\nreturn { lireSession: lireSession, utilisateurValide: utilisateurValide };");
const { lireSession, utilisateurValide } = fabrique();

let echecs = 0;
let total = 0;

function cas(intitule, obtenu, attendu) {
  total++;
  const ok = JSON.stringify(obtenu) === JSON.stringify(attendu);
  if (!ok) {
    echecs++;
    console.log(`  [ECHEC] ${intitule}`);
    console.log(`          attendu : ${JSON.stringify(attendu)}`);
    console.log(`          obtenu  : ${JSON.stringify(obtenu)}`);
  } else {
    console.log(`  [OK]    ${intitule}`);
  }
}

console.log("########## NexBSD — logique de session du bureau ##########");
console.log("");
console.log("----- 1. sans information de session : le bureau doit rester VERROUILLE -----");
cas("chaîne vide", lireSession(""), { mode: "verrou", utilisateur: "" });
cas("null", lireSession(null), { mode: "verrou", utilisateur: "" });
cas("undefined", lireSession(undefined), { mode: "verrou", utilisateur: "" });
cas("paramètre inconnu", lireSession("?autre=chose"), { mode: "verrou", utilisateur: "" });

console.log("");
console.log("----- 2. session ouverte par la session (mot de passe déjà vérifié par PAM) -----");
cas("utilisateur simple", lireSession("?utilisateur=omrane"), { mode: "session", utilisateur: "omrane" });
cas("utilisateur avec tiret", lireSession("?utilisateur=jean-marc"), { mode: "session", utilisateur: "jean-marc" });
cas("utilisateur avec souligné", lireSession("?utilisateur=_systeme"), { mode: "session", utilisateur: "_systeme" });

console.log("");
console.log("----- 3. mode démonstration : explicite, et clairement distinct d'une session -----");
cas("demo=1", lireSession("?demo=1"), { mode: "demo", utilisateur: "démonstration" });
cas("demo=0 n'est PAS une session", lireSession("?demo=0"), { mode: "verrou", utilisateur: "" });

console.log("");
console.log("----- 4. cas hostiles : un nom bricolé ne doit jamais ouvrir la session -----");
cas("balise HTML dans le nom", utilisateurValide("<script>"), false);
cas("nom avec espace", utilisateurValide("om rane"), false);
cas("nom avec point-virgule", utilisateurValide("omrane;reboot"), false);
cas("nom trop long (40)", utilisateurValide("a".repeat(40)), false);
cas("nom commençant par un chiffre", utilisateurValide("1omrane"), false);
cas("nom valide", utilisateurValide("omrane"), true);

console.log("");
console.log("----- 5. chaîne de requête bricolée : décodage sans surprise -----");
cas("paramètre encodé", lireSession("?utilisateur=omrane%2Dlab"), { mode: "session", utilisateur: "omrane-lab" });
cas("deux paramètres, demo prioritaire", lireSession("?utilisateur=omrane&demo=1"), { mode: "demo", utilisateur: "démonstration" });

console.log("");
if (echecs === 0) {
  console.log(`VERDICT : ${total} cas, 0 échec. La logique de session se comporte comme décrit.`);
  console.log("LIMITE : ceci teste la DÉCISION, pas la vérification du mot de passe —");
  console.log("         celle-ci appartient à PAM, dans la session, et n'a jamais été exécutée.");
  process.exit(0);
} else {
  console.log(`VERDICT : ÉCHEC — ${echecs} cas en échec sur ${total}.`);
  process.exit(1);
}
