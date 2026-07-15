const pool = require('../config/db');
const logger = require('../utils/logger');

const syncLocation = async (req, res) => {
  try {
    const items = req.body;

    if (!Array.isArray(items) || items.length === 0) {
      return res.status(400).json({ message: 'Payload invalide.' });
    }

    const first = items[0];
    const latitude = first.latitude;
    const longitude = first.longitude;
    const precision = first.accuracy ?? first.precision ?? 10;
    const sourceType = req.bracelet ? 'bracelet' : 'user';
    const sourceId = req.bracelet ? req.bracelet.bracelet_id : req.user?.user_id;

    if (!sourceId || latitude == null || longitude == null) {
      logger.warn('Location sync rejected: incomplete data', { sourceType, sourceId });
      return res.status(400).json({ message: 'Données de position incomplètes.' });
    }

    let groupId = null;
    let enfantNom = null;
    let enfantPrenom = null;

    if (sourceType === 'bracelet' && sourceId) {
      const braceletResult = await pool.query(
        `SELECT group_id, nom_enfant, prenom_enfant
         FROM bracelets WHERE id_bracelet = $1`,
        [sourceId]
      );

      if (braceletResult.rows.length > 0) {
        const bracelet = braceletResult.rows[0];
        groupId = bracelet.group_id;
        enfantNom = bracelet.nom_enfant;
        enfantPrenom = bracelet.prenom_enfant;
      }
    }

    await pool.query(
      `INSERT INTO positions (source_type, source_id, latitude, longitude, precision_m)
       VALUES ($1, $2, $3, $4, $5)`,
      [sourceType, sourceId, latitude, longitude, precision]
    );

    if (req.io && groupId) {
      req.io.to(`groupe_${groupId}`).emit('position_mise_a_jour', {
        user_id: sourceId,
        nom: enfantNom || 'Bracelet',
        prenom: enfantPrenom || '',
        latitude,
        longitude,
        precision_m: precision,
        timestamp: new Date().toISOString(),
        source_type: 'bracelet',
        group_id: groupId,
        role: 'enfant'
      });
    }

    logger.info('Location synced', { sourceType, sourceId, latitude, longitude, groupId, precision });
    res.status(200).json({ message: 'Position synchronisée.' });
  } catch (err) {
    logger.error('Location sync failed', { error: err.message, stack: err.stack, sourceType: req.bracelet ? 'bracelet' : 'user' });
    res.status(500).json({ message: 'Erreur serveur.' });
  }
};

const syncSos = async (req, res) => {
  try {
    const items = req.body;

    if (!Array.isArray(items) || items.length === 0) {
      return res.status(400).json({ message: 'Payload invalide.' });
    }

    const first = items[0];
    const latitude = first.latitude;
    const longitude = first.longitude;
    const precision = first.accuracy ?? first.precision ?? 10;
    const severity = first.severity || 'HIGH';
    const sourceType = req.bracelet ? 'bracelet' : 'user';
    const sourceId = req.bracelet ? req.bracelet.bracelet_id : req.user?.user_id;

    if (!sourceId || latitude == null || longitude == null) {
      logger.warn('SOS sync rejected: incomplete data', { sourceType, sourceId });
      return res.status(400).json({ message: 'Données SOS incomplètes.' });
    }

    let groupId = null;
    let enfantNom = null;
    let enfantPrenom = null;

    if (sourceType === 'bracelet' && sourceId) {
      const braceletResult = await pool.query(
        `SELECT group_id, nom_enfant, prenom_enfant
         FROM bracelets WHERE id_bracelet = $1`,
        [sourceId]
      );

      if (braceletResult.rows.length > 0) {
        const bracelet = braceletResult.rows[0];
        groupId = bracelet.group_id;
        enfantNom = bracelet.nom_enfant;
        enfantPrenom = bracelet.prenom_enfant;
      }
    }

    await pool.query(
      `INSERT INTO positions (source_type, source_id, latitude, longitude, precision_m)
       VALUES ($1, $2, $3, $4, $5)`,
      [sourceType, sourceId, latitude, longitude, precision]
    );

    if (req.io && groupId) {
      const horodatage = new Date().toISOString();

      // 1) Met à jour la position du bracelet sur la carte des parents
      req.io.to(`groupe_${groupId}`).emit('position_mise_a_jour', {
        user_id: sourceId,
        nom: enfantNom || 'Bracelet',
        prenom: enfantPrenom || '',
        latitude,
        longitude,
        precision_m: precision,
        timestamp: horodatage,
        source_type: 'bracelet',
        group_id: groupId,
        role: 'enfant'
      });

      // 2) Déclenche l'alerte SOS chez les parents (bannière + snackbar).
      //    C'est l'événement que l'app parent écoute (SocketService.ecouterSos).
      req.io.to(`groupe_${groupId}`).emit('sos_declenche', {
        bracelet_id: sourceId,
        nom: enfantNom || 'Bracelet',
        prenom: enfantPrenom || '',
        latitude,
        longitude,
        severity,
        group_id: groupId,
        timestamp: horodatage,
        role: 'enfant'
      });
    }

    logger.warn('SOS synced', { sourceType, sourceId, latitude, longitude, groupId, precision, severity });
    res.status(200).json({ message: 'SOS synchronisé.' });
  } catch (err) {
    logger.error('SOS sync failed', { error: err.message, stack: err.stack, sourceType: req.bracelet ? 'bracelet' : 'user' });
    res.status(500).json({ message: 'Erreur serveur.' });
  }
};

module.exports = { syncLocation, syncSos };
