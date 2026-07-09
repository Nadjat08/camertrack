# ADR-006 — Table dédiée sos_alerts

- **Date** : 2026-07-09
- **Statut** : Accepted

## Contexte

Le moteur CamerTrack implémente une fonctionnalité Offline-First : il sauvegarde les alertes SOS localement en cas d'absence de réseau, puis les synchronise en batch dès que la connectivité est rétablie.

Deux options ont été étudiées pour persister ces alertes côté backend :
- **Option A** : Réutiliser la table `positions` avec un type particulier (ex: `source_type = 'sos'`).
- **Option B** : Créer une table dédiée `sos_alerts`.

## Décision

Choisir l'**Option B** avec la création de la table `sos_alerts` :

```sql
CREATE TABLE sos_alerts (
  id_sos      SERIAL PRIMARY KEY,
  bracelet_id INT REFERENCES bracelets(id_bracelet),
  latitude    FLOAT NOT NULL,
  longitude   FLOAT NOT NULL,
  timestamp   TIMESTAMP NOT NULL,
  severity    VARCHAR(50) NOT NULL,
  created_at  TIMESTAMP DEFAULT NOW()
);
```

## Conséquences

**Positives :**
- **Séparation sémantique** : Une alerte SOS n'est pas une position ordinaire. Les requêtes de monitoring (ex: "combien de SOS ce mois-ci ?") sont plus simples et plus rapides.
- Le champ `severity` est spécifique aux SOS et n'a pas de sens dans une table de positions GPS.
- Facilite les futures fonctionnalités d'historique SOS (tableau de bord parent, export, statistiques).
- Alignement avec le mémoire qui traite le SOS comme une entité à part entière.

**Négatives :**
- Une table supplémentaire à maintenir.
- Les jointures pour afficher positions + SOS sur une carte nécessiteront un `UNION` ou deux requêtes séparées.
