const pool = require('../config/db');

// POST /api/locations/location/sync
const syncPositions = async (req, res) => {
  const bracelet_id = req.bracelet.bracelet_id;
  const group_id = req.bracelet.group_id;

  let locations = req.body;
  if (!Array.isArray(locations) && locations && Array.isArray(locations.locations)) {
    locations = locations.locations;
  }

  if (!Array.isArray(locations)) {
    return res.status(400).json({ message: 'Tableau de positions attendu.' });
  }

  // Récupéré une seule fois : nécessaire pour que le payload Socket.io soit
  // compatible avec ce que l'app Flutter attend déjà pour un membre humain
  // (user_id, nom, prenom) — voir ecouterPositions dans home_screen.dart.
  let nomEnfant = null;
  let prenomEnfant = null;
  try {
    const braceletInfo = await pool.query(
      `SELECT nom_enfant, prenom_enfant FROM bracelets WHERE id_bracelet = $1`,
      [bracelet_id]
    );
    if (braceletInfo.rows.length > 0) {
      nomEnfant = braceletInfo.rows[0].nom_enfant;
      prenomEnfant = braceletInfo.rows[0].prenom_enfant;
    }
  } catch (err) {
    console.error('Erreur récupération infos bracelet pour diffusion :', err);
  }

  const synced = [];
  const failed = [];

  for (const loc of locations) {
    try {
      // DTO: id, sessionId, latitude, longitude, accuracy, altitude, speed, bearing, timestamp, source
      const { id, latitude, longitude, accuracy, timestamp } = loc;

      if (latitude === undefined || longitude === undefined) {
        failed.push({ id, reason: 'Latitude ou longitude manquante' });
        continue;
      }

      const ts = timestamp ? new Date(timestamp) : new Date();

      await pool.query(
        `INSERT INTO positions (source_type, source_id, latitude, longitude, precision_m, timestamp)
         VALUES ('bracelet', $1, $2, $3, $4, $5)`,
        [bracelet_id, latitude, longitude, accuracy || 10, ts]
      );
      synced.push(id);

      // Diffusion temps réel — mêmes noms de champs que pour un membre humain
      // (user_id, nom, prenom) pour rester compatible avec ecouterPositions
      // côté Flutter, sans avoir à modifier le modèle MembrePosition.
      if (req.io && group_id) {
        req.io.to(`groupe_${group_id}`).emit('position_mise_a_jour', {
          user_id: bracelet_id,
          nom: nomEnfant,
          prenom: prenomEnfant,
          latitude,
          longitude,
          precision_m: accuracy || 10,
          timestamp: ts.toISOString(),
          role: 'enfant',
          group_id
        });
      }
    } catch (err) {
      console.error('Erreur insert location:', err);
      failed.push({ id: loc.id, reason: 'Erreur insertion DB' });
    }
  }

  res.status(200).json({ synced, failed });
};

// POST /api/locations/sos/sync
// Insère dans la table "alertes" existante (source_type = 'bracelet', type = 'sos'),
// au lieu de la table "sos_alerts" — et notifie chaque membre actif du groupe
// via "alertes_destinataires", comme le fait déjà le reste de l'application.
const syncSos = async (req, res) => {
  const bracelet_id = req.bracelet.bracelet_id;
  const group_id = req.bracelet.group_id;

  let sosAlerts = req.body;
  if (!Array.isArray(sosAlerts) && sosAlerts && Array.isArray(sosAlerts.alerts)) {
    sosAlerts = sosAlerts.alerts;
  }

  if (!Array.isArray(sosAlerts)) {
    return res.status(400).json({ message: 'Tableau d\'alertes attendu.' });
  }

  const synced = [];
  const failed = [];

  for (const sos of sosAlerts) {
    try {
      // DTO: id, sessionId, latitude, longitude, accuracy, timestamp, severity
      const { id, latitude, longitude, severity, timestamp } = sos;

      if (latitude === undefined || longitude === undefined) {
        failed.push({ id, reason: 'Latitude ou longitude manquante' });
        continue;
      }

      const ts = timestamp ? new Date(timestamp) : new Date();

      // 1. Enregistrer l'alerte dans la table générique "alertes"
      const alertResult = await pool.query(
        `INSERT INTO alertes (group_id, source_id, source_type, type, timestamp, lat, lng, severity)
         VALUES ($1, $2, 'bracelet', 'sos', $3, $4, $5, $6)
         RETURNING id_alert`,
        [group_id, bracelet_id, ts, latitude, longitude, severity || 'HIGH']
      );
      const id_alert = alertResult.rows[0].id_alert;

      // 2. Notifier chaque membre actif du groupe (uniquement les users, pas le bracelet lui-même)
      const membres = await pool.query(
        `SELECT user_id FROM membres_groupe
         WHERE group_id = $1 AND actif = true AND user_id IS NOT NULL`,
        [group_id]
      );

      for (const membre of membres.rows) {
        await pool.query(
          `INSERT INTO alertes_destinataires (alerte_id, user_id, lue)
           VALUES ($1, $2, false)`,
          [id_alert, membre.user_id]
        );
      }

      synced.push(id);

      // 3. Diffusion temps réel
      if (req.io && group_id) {
        req.io.to(`groupe_${group_id}`).emit('sos_declenche', {
          id_alert,
          bracelet_id,
          identifiant_unique: req.bracelet.identifiant_unique,
          latitude,
          longitude,
          severity: severity || 'HIGH',
          timestamp: ts.toISOString(),
          group_id
        });
      }
    } catch (err) {
      console.error('Erreur insert SOS:', err);
      failed.push({ id: sos.id, reason: 'Erreur insertion DB' });
    }
  }

  res.status(200).json({ status: 'SUCCESS', message: 'SOS alerts processed', synced, failed });
};

module.exports = { syncPositions, syncSos };