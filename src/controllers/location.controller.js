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
      
      // Diffusion temps réel
      if (req.io && group_id) {
        req.io.to(`groupe_${group_id}`).emit('position_mise_a_jour', {
          bracelet_id,
          identifiant_unique: req.bracelet.identifiant_unique,
          latitude,
          longitude,
          precision_m: accuracy || 10,
          timestamp: ts.toISOString(),
          source_type: 'bracelet',
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

      await pool.query(
        `INSERT INTO sos_alerts (bracelet_id, latitude, longitude, timestamp, severity)
         VALUES ($1, $2, $3, $4, $5)`,
        [bracelet_id, latitude, longitude, ts, severity || 'HIGH']
      );
      synced.push(id);

      // Diffusion temps réel
      if (req.io && group_id) {
        req.io.to(`groupe_${group_id}`).emit('sos_declenche', {
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
