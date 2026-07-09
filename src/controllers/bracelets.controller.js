const pool = require('../config/db');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');

// POST /api/groupes/:id/bracelets — Associer un bracelet au groupe
const ajouterBracelet = async (req, res) => {
  const { id } = req.params; // group_id
  const { identifiant_unique, nom_enfant, prenom_enfant, date_naissance } = req.body;
  const admin_id = req.user.user_id;

  if (!identifiant_unique || !nom_enfant || !prenom_enfant) {
    return res.status(400).json({ message: 'Identifiant, nom et prénom obligatoires.' });
  }

  try {
    // Vérifier que l'utilisateur est admin du groupe
    const adminCheck = await pool.query(
      `SELECT id FROM membres_groupe
       WHERE group_id = $1 AND user_id = $2 AND role = 'admin' AND actif = true`,
      [id, admin_id]
    );

    if (adminCheck.rows.length === 0) {
      return res.status(403).json({ message: 'Seul l\'administrateur peut ajouter un bracelet.' });
    }

    // Vérifier que le bracelet existe (créé à la fabrication)
    const braceletResult = await pool.query(
      `SELECT * FROM bracelets WHERE identifiant_unique = $1`,
      [identifiant_unique]
    );

    if (braceletResult.rows.length === 0) {
      return res.status(404).json({ message: 'Bracelet introuvable. Vérifiez l\'identifiant.' });
    }

    const bracelet = braceletResult.rows[0];

    if (bracelet.group_id !== null) {
      return res.status(409).json({ message: 'Ce bracelet est déjà associé à un groupe.' });
    }

    // Associer le bracelet au groupe et mettre à jour le profil enfant
    const result = await pool.query(
      `UPDATE bracelets
       SET group_id = $1, nom_enfant = $2, prenom_enfant = $3,
           date_naissance = $4, statut = true
       WHERE identifiant_unique = $5
       RETURNING id_bracelet, identifiant_unique, nom_enfant, prenom_enfant, date_naissance`,
      [id, nom_enfant, prenom_enfant, date_naissance, identifiant_unique]
    );

    // Ajouter le bracelet comme membre passif du groupe
    await pool.query(
      `INSERT INTO membres_groupe (group_id, bracelet_id, role)
       VALUES ($1, $2, 'membre_passif')`,
      [id, result.rows[0].id_bracelet]
    );

    res.status(201).json({
      message: `${prenom_enfant} a été ajouté au groupe avec succès.`,
      bracelet: result.rows[0]
    });

  } catch (err) {
    console.error('Erreur ajouterBracelet :', err);
    res.status(500).json({ message: 'Erreur serveur.' });
  }
};

// GET /api/bracelets/:identifiant — Vérifier qu'un bracelet existe et est libre
const verifierBracelet = async (req, res) => {
  const { identifiant } = req.params;

  try {
    const result = await pool.query(
      `SELECT id_bracelet, identifiant_unique, group_id, nom_enfant, prenom_enfant
       FROM bracelets WHERE identifiant_unique = $1`,
      [identifiant]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ message: 'Bracelet introuvable.', disponible: false });
    }

    const bracelet = result.rows[0];

    if (bracelet.group_id !== null) {
      return res.status(409).json({
        message: 'Ce bracelet est déjà associé à un groupe.',
        disponible: false
      });
    }

    res.status(200).json({
      message: 'Bracelet disponible.',
      disponible: true,
      bracelet
    });

  } catch (err) {
    console.error('Erreur verifierBracelet :', err);
    res.status(500).json({ message: 'Erreur serveur.' });
  }
};

// POST /api/bracelets/enregistrer — Provisioning de la montre
const enregistrerBracelet = async (req, res) => {
  const { identifiant_unique, deviceType, platform } = req.body;

  if (!identifiant_unique) {
    return res.status(400).json({ message: 'Identifiant unique obligatoire.' });
  }

  try {
    const result = await pool.query(
      `SELECT id_bracelet FROM bracelets WHERE identifiant_unique = $1`,
      [identifiant_unique]
    );

    if (result.rows.length > 0) {
      return res.status(200).json({ bracelet_id: result.rows[0].id_bracelet });
    } else {
      const insertResult = await pool.query(
        `INSERT INTO bracelets (identifiant_unique, device_type, platform)
         VALUES ($1, $2, $3) RETURNING id_bracelet`,
        [identifiant_unique, deviceType, platform]
      );
      return res.status(201).json({ bracelet_id: insertResult.rows[0].id_bracelet });
    }
  } catch (err) {
    console.error('Erreur enregistrerBracelet :', err);
    res.status(500).json({ message: 'Erreur serveur.' });
  }
};

// GET /api/bracelets/status/:identifiant — Polling de la montre
const statutBracelet = async (req, res) => {
  const { identifiant } = req.params;

  try {
    const result = await pool.query(
      `SELECT id_bracelet, identifiant_unique, group_id, provisioned
       FROM bracelets WHERE identifiant_unique = $1`,
      [identifiant]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ message: 'Bracelet introuvable.' });
    }

    const bracelet = result.rows[0];

    if (!bracelet.group_id) {
      return res.status(200).json({ status: 'WAITING' });
    }

    if (bracelet.provisioned) {
      return res.status(200).json({ status: 'PROVISIONED' });
    }

    const accessToken = jwt.sign(
      {
        bracelet_id: bracelet.id_bracelet,
        identifiant_unique: bracelet.identifiant_unique,
        group_id: bracelet.group_id,
        role: 'bracelet'
      },
      process.env.JWT_SECRET,
      { expiresIn: '24h' }
    );

    const refreshToken = crypto.randomBytes(40).toString('hex');

    await pool.query(
      `UPDATE bracelets
       SET provisioned = true, refresh_token = $1
       WHERE id_bracelet = $2`,
      [refreshToken, bracelet.id_bracelet]
    );

    return res.status(200).json({
      status: 'ASSOCIATED',
      accessToken,
      refreshToken
    });
  } catch (err) {
    console.error('Erreur statutBracelet :', err);
    res.status(500).json({ message: 'Erreur serveur.' });
  }
};

module.exports = { ajouterBracelet, verifierBracelet, enregistrerBracelet, statutBracelet };