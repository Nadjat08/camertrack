# ADR-002 — Provisioning par UPSERT

- **Date** : 2026-07-09
- **Statut** : Accepted

## Contexte

L'endpoint `POST /api/bracelets/enregistrer` est appelé par la montre à chaque premier démarrage de l'application. Dans un contexte d'appareil embarqué (WearOS), les scénarios de retry sont courants :
- Timeout réseau lors du premier enregistrement.
- Réinstallation de l'application moteur.
- Crash de l'application avant la confirmation serveur.

Une implémentation naïve avec un `INSERT` pur créerait un nouveau bracelet en base à chaque retry, résultant en plusieurs entrées pour le même appareil physique et rendant le workflow de provisioning incohérent.

## Décision

Implémenter un **UPSERT logique** via `SELECT` puis `INSERT` conditionnel dans `enregistrerBracelet()` :

```javascript
const result = await pool.query(
  `SELECT id_bracelet FROM bracelets WHERE identifiant_unique = $1`,
  [identifiant_unique]
);

if (result.rows.length > 0) {
  return res.status(200).json({ bracelet_id: result.rows[0].id_bracelet });
} else {
  const insertResult = await pool.query(`INSERT INTO bracelets ...`);
  return res.status(201).json({ bracelet_id: insertResult.rows[0].id_bracelet });
}
```

La réponse est toujours `{ bracelet_id }`, que le bracelet soit nouveau ou déjà connu.

## Conséquences

**Positives :**
- Idempotence garantie : N appels avec le même `identifiant_unique` produisent toujours le même résultat.
- Compatibilité avec les retry automatiques du moteur (ex: `RegistrationManager`).
- Pas de doublons en base.

**Négatives :**
- Deux requêtes SQL au lieu d'une (SELECT + éventuel INSERT). L'impact est négligeable car cet endpoint n'est appelé qu'au démarrage.
- Alternative non retenue : `INSERT ... ON CONFLICT DO NOTHING RETURNING id_bracelet` — plus élégant en SQL pur mais moins lisible pour un développeur junior découvrant le code.
