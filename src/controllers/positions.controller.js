const pool = require('../config/db');
const logger = require('../utils/logger');

// POST /api/positions — Envoyer sa position (membre actif)
const envoyerPosition = async (req, res) => {
  const { latitude, longitude, precision } = req.body;
  const user_id = req.user.user_id;

  if (!latitude || !longitude) {
    logger.warn('Position submission rejected: missing coordinates', { userId: user_id });
    return res.status(400).json({ message: 'Latitude et longitude obligatoires.' });
  }

  try {
    // Enregistrer la position
    await pool.query(
      `INSERT INTO positions (source_type, source_id, latitude, longitude, precision_m)
       VALUES ('user', $1, $2, $3, $4)`,
      [user_id, latitude, longitude, precision || 10]
    );

    // Récupérer les groupes de l'utilisateur pour diffuser via Socket.io
    const groupesResult = await pool.query(
      `SELECT group_id FROM membres_groupe
       WHERE user_id = $1 AND actif = true`,
      [user_id]
    );

    // Récupérer les infos de l'utilisateur
    const userResult = await pool.query(
      `SELECT user_id, nom, prenom FROM users WHERE user_id = $1`,
      [user_id]
    );

    const user = userResult.rows[0];
    const groupes = groupesResult.rows;

    // Diffuser la position dans toutes les rooms des groupes
    // via l'objet io attaché à req
    if (req.io) {
      groupes.forEach(({ group_id }) => {
        req.io.to(`groupe_${group_id}`).emit('position_mise_a_jour', {
          user_id: user.user_id,
          nom: user.nom,
          prenom: user.prenom,
          latitude,
          longitude,
          precision_m: precision || 10,
          timestamp: new Date().toISOString(),
          source_type: 'user',
          group_id,
          role: 'membre'
        });
      });
    }

    logger.info('Position stored', { userId: user_id, latitude, longitude, precision: precision || 10 });
    res.status(200).json({ message: 'Position enregistrée.' });

  } catch (err) {
    logger.error('Position submission failed', { error: err.message, stack: err.stack, userId: user_id });
    res.status(500).json({ message: 'Erreur serveur.' });
  }
};

// GET /api/positions/membres — Dernières positions de tous les membres (humains + bracelets)
const getPositionsMembres = async (req, res) => {
  const user_id = req.user.user_id;

  try {
    // Dernières positions des membres humains des groupes de l'utilisateur
    const membresHumains = await pool.query(
      `SELECT DISTINCT ON (p.source_id, p.source_type)
              u.user_id, u.nom, u.prenom,
              p.latitude, p.longitude, p.precision_m, p.timestamp,
              mg.role, g.group_id, g.nom_grp,
              CASE
                WHEN p.timestamp > NOW() - INTERVAL '15 minutes' THEN true
                ELSE false
              END AS en_ligne
       FROM positions p
       INNER JOIN users u ON u.user_id = p.source_id
       INNER JOIN membres_groupe mg ON mg.user_id = u.user_id
       INNER JOIN groupes g ON g.group_id = mg.group_id
       INNER JOIN membres_groupe mg2 ON mg2.group_id = g.group_id
                                    AND mg2.user_id = $1
                                    AND mg2.actif = true
       WHERE p.source_type = 'user'
         AND p.source_id != $1
         AND mg.actif = true
       ORDER BY p.source_id, p.source_type, p.timestamp DESC`,
      [user_id]
    );

    // Dernières positions des bracelets rattachés aux groupes de l'utilisateur.
    // Rattachement via bracelets.group_id (pas via membres_groupe, voir choix de conception).
    // role = 'enfant' sert de marqueur pour que l'app distingue un bracelet d'un membre humain.
    const bracelets = await pool.query(
      `SELECT DISTINCT ON (p.source_id)
              b.id_bracelet AS user_id, b.nom_enfant AS nom, b.prenom_enfant AS prenom,
              p.latitude, p.longitude, p.precision_m, p.timestamp,
              'enfant' AS role, g.group_id, g.nom_grp,
              CASE
                WHEN p.timestamp > NOW() - INTERVAL '15 minutes' THEN true
                ELSE false
              END AS en_ligne
       FROM positions p
       INNER JOIN bracelets b ON b.id_bracelet = p.source_id AND p.source_type = 'bracelet'
       INNER JOIN groupes g ON g.group_id = b.group_id
       INNER JOIN membres_groupe mg2 ON mg2.group_id = b.group_id
                                     AND mg2.user_id = $1
                                     AND mg2.actif = true
       WHERE b.group_id IS NOT NULL
       ORDER BY p.source_id, p.timestamp DESC`,
      [user_id]
    );

    res.status(200).json({
      membres: [...membresHumains.rows, ...bracelets.rows]
    });

  } catch (err) {
    console.error('Erreur getPositionsMembres :', err);
    res.status(500).json({ message: 'Erreur serveur.' });
  }
};

module.exports = { envoyerPosition, getPositionsMembres };