# ADR-005 — Versioning des routes moteur sous /api/locations

- **Date** : 2026-07-09
- **Statut** : Accepted

## Contexte

Le backend expose des routes existantes pour l'application mobile parent (ex: `POST /api/positions`). Le moteur WearOS nécessite de nouveaux endpoints avec un format de payload différent (batch, DTO enrichi). Deux approches ont été considérées :

**Option A — Modifier les routes existantes** : Adapter `POST /api/positions` pour accepter à la fois le format single (utilisateur) et le format batch (moteur).

**Option B — Versionner les nouvelles routes** : Créer un préfixe séparé pour les routes exclusivement dédiées au moteur.

## Décision

Choisir l'**Option B** avec le préfixe `/api/locations/` pour les routes moteur, servi par un routeur dédié [`src/routes/location.routes.js`](../src/routes/location.routes.js) et un contrôleur dédié [`src/controllers/location.controller.js`](../src/controllers/location.controller.js).

Les routes historiques `/api/positions` restent **inchangées** pour l'application mobile.

| Client | Route | Middleware |
|---|---|---|
| Application mobile (parent) | `POST /api/positions` | `verifierUserToken` |
| Moteur WearOS (bracelet) | `POST /api/locations/location/sync` | `verifierBraceletToken` |
| Moteur WearOS (bracelet) | `POST /api/locations/sos/sync` | `verifierBraceletToken` |

## Conséquences

**Positives :**
- Aucune régression sur les routes existantes de l'application mobile.
- Séparation claire des responsabilités : chaque routeur a son propre middleware d'authentification.
- Cohérence terminologique avec le mémoire (`locations`, `sos`).
- Evolutivité : d'autres routes moteur pourront être ajoutées sous `/api/locations/` sans impact.

**Négatives :**
- Légère duplication de logique entre `envoyerPosition` et `syncPositions` (les deux insèrent dans la table `positions`). Acceptable car les DTOs et les sources (`user` vs `bracelet`) sont différents.
