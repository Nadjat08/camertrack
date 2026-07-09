# ADR-001 — Séparation des tokens utilisateur et bracelet

- **Date** : 2026-07-09
- **Statut** : Accepted

## Contexte

Le backend gérait initialement un seul type d'authentification : un **JWT utilisateur** (`{ user_id, email }`) vérifié par un middleware unique `verifierToken`. Avec l'introduction du moteur CamerTrack (WearOS), un deuxième type de client fait des requêtes HTTP vers le backend : le **bracelet**, qui est une machine et non un humain.

Ces deux clients n'ont pas les mêmes permissions :
- Un **utilisateur** peut créer des groupes, envoyer des invitations, gérer des bracelets.
- Un **bracelet** peut uniquement synchroniser ses positions et ses alertes SOS pour son groupe d'appartenance.

Utiliser le même middleware et le même type de token pour les deux aurait permis à un utilisateur malveillant de se faire passer pour un bracelet, ou à un bracelet compromis d'accéder à des opérations sensibles.

## Décision

Créer deux middlewares distincts dans `src/middleware/auth.js` :
- `verifierUserToken` : vérifie que le JWT contient `role !== 'bracelet'`. Injecte `req.user`.
- `verifierBraceletToken` : vérifie que le JWT contient `role === 'bracelet'`. Injecte `req.bracelet = { bracelet_id, identifiant_unique, group_id, role }`.

Le champ `role` est encodé directement dans le payload JWT au moment de sa génération dans `statutBracelet()`.

## Conséquences

**Positives :**
- Isolation claire des permissions : une route protégée par `verifierBraceletToken` est inaccessible à un token utilisateur et vice-versa.
- Les controllers n'ont pas besoin de vérifier le type de client : `req.bracelet` et `req.user` sont des objets distincts.
- Cohérence avec le mémoire (mentionne explicitement `bracelet` comme entité à part).

**Négatives :**
- La vérification du rôle repose sur un champ `role` dans le JWT, qui est encodé mais non chiffré. Si la clé `JWT_SECRET` est compromise, un attaquant peut forger un token avec `role: 'bracelet'`.
- Mitigation : rotation régulière du `JWT_SECRET` et utilisation d'une valeur forte en production.
