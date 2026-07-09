# ADR-007 — Diffusion Socket.IO après sync batch

- **Date** : 2026-07-09
- **Statut** : Accepted

## Contexte

Le backend disposait déjà d'une infrastructure Socket.IO pour diffuser les positions des utilisateurs en temps réel aux autres membres du groupe (via `envoyerPosition()`). Avec l'introduction de la synchronisation batch (`syncPositions`, `syncSos`), la question s'est posée : faut-il également émettre des événements Socket.IO après chaque insertion batch ?

Sans cela, les parents connectés à l'application mobile ne verraient jamais la montre se déplacer sur la carte, car les données arriveraient uniquement en base de données sans notification temps réel.

## Décision

Après chaque insertion réussie dans la boucle batch, émettre un événement Socket.IO vers la room du groupe concerné :

- Après `syncPositions` : `emit('position_mise_a_jour', { bracelet_id, latitude, longitude, ... })`
- Après `syncSos` : `emit('sos_declenche', { bracelet_id, latitude, longitude, severity, ... })`

L'objet `io` est disponible via `req.io` (attaché à chaque requête dans `server.js`).

La diffusion est conditionnelle (`if (req.io && group_id)`) pour ne pas provoquer d'erreur si Socket.IO n'est pas initialisé (ex: tests unitaires).

## Conséquences

**Positives :**
- Les parents voient la montre se déplacer en temps réel sur la carte, même si les données arrivent en batch.
- Réutilisation du même canal Socket.IO et des mêmes événements que l'application existante : aucun changement côté client Flutter.
- Gestion des SOS en urgence : l'émission `sos_declenche` peut déclencher une alerte push immédiate côté app.

**Négatives :**
- Si un batch contient 100 positions, 100 événements Socket.IO sont émis en rafale. Cela pourrait saturer les connexions WebSocket en cas de très gros backlogs hors-ligne. Mitigation future : n'émettre que la dernière position du batch.
