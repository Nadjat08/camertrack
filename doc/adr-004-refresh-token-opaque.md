# ADR-004 — Refresh token opaque stocké en base

- **Date** : 2026-07-09
- **Statut** : Accepted

## Contexte

Le moteur CamerTrack a besoin de renouveler son `accessToken` quand celui-ci expire (après 24h), sans demander à l'utilisateur de re-scanner un QR Code. Deux approches ont été envisagées :

**Option A — Refresh token JWT (stateless) :** Le refresh token est lui-même un JWT signé avec une durée de vie longue. La vérification se fait en mémoire sans accès base de données.

**Option B — Refresh token opaque (stateful) :** Le refresh token est une chaîne aléatoire stockée en base. La vérification nécessite un `SELECT` mais permet la révocation immédiate.

## Décision

Choisir l'**Option B** : refresh token opaque généré via `crypto.randomBytes(40).toString('hex')`, stocké dans la colonne `refresh_token` de la table `bracelets`.

À chaque renouvellement (`POST /api/auth/refresh`), l'ancien token est **immédiatement remplacé** en base par un nouveau. C'est le mécanisme de **Refresh Token Rotation**.

## Conséquences

**Positives :**
- **Révocation possible** : Si un bracelet est volé ou compromis, il suffit de mettre à null la colonne `refresh_token` en base pour invalider toute la session.
- **Détection de réutilisation** : Si un ancien refresh token est présenté (car il a déjà été tourné), la requête échouera avec 401, signalant un possible incident de sécurité.
- Pratique standard recommandée par OAuth 2.0 pour les clients machines (RFC 6749).

**Négatives :**
- Nécessite un accès base de données à chaque renouvellement (contrairement au JWT stateless).
- Un seul refresh token actif à la fois par bracelet : si le moteur perd le token avant de le sauvegarder, il devra se re-provisionner. Ce risque est acceptable pour une montre connectée en continu.
