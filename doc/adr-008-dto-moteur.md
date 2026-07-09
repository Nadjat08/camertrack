# ADR-008 — Respect strict du DTO du moteur

- **Date** : 2026-07-09
- **Statut** : Accepted

## Contexte

Le moteur CamerTrack envoie des payloads avec une structure de données précise (DTO — Data Transfer Object) définie du côté Android/WearOS. Lors de l'implémentation des endpoints de synchronisation, deux approches ont été envisagées :

**Option A — Redéfinir le format côté backend** : Le backend décrète quels champs il accepte (ex: `latitude`, `longitude`, `timestamp`, `precision` uniquement) et le moteur s'adapte.

**Option B — Respecter le DTO du moteur** : Le backend accepte exactement ce que le moteur envoie, et ignore les champs non nécessaires.

## Décision

Choisir l'**Option B** et documenter les DTOs exacts dans les commentaires du code :

**Location DTO** :
```
id, sessionId, latitude, longitude, accuracy, altitude, speed, bearing, timestamp, source
```

**SOS DTO** :
```
id, sessionId, latitude, longitude, accuracy, timestamp, severity
```

Le backend extrait les champs dont il a besoin (`latitude`, `longitude`, `accuracy`, `timestamp`, `severity`) et persiste les champs ignorés (`sessionId`, `altitude`, `speed`, `bearing`, `source`) sans erreur grâce à la déstructuration JavaScript.

## Conséquences

**Positives :**
- Le moteur n'a pas besoin d'être modifié pour s'adapter au backend : il envoie son DTO natif.
- Résilience : si le moteur ajoute un champ futur, le backend continue de fonctionner sans mise à jour.
- Source de vérité unique : le DTO est défini une fois côté moteur, le backend est un consommateur.

**Négatives :**
- Des données sont ignorées (ex: `altitude`, `speed`) et ne sont pas persistées pour l'instant. Si un besoin apparaît de les stocker (ex: détection de vitesse anormale), il faudra une migration de schéma.
- Nécessite une synchronisation documentaire entre l'équipe backend et l'équipe moteur pour s'assurer que le DTO n'évolue pas silencieusement.
