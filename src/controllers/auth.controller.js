const pool = require('../config/db');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');

// POST /api/auth/register
const register = async (req, res) => {
  const { nom, prenom, email, telephone, password } = req.body;

  // Validation des champs obligatoires
  if (!nom || !email || !telephone || !password) {
    return res.status(400).json({ message: 'Tous les champs sont obligatoires.' });
  }

  try {
    // Vérifier si email ou téléphone déjà utilisé
    const exist = await pool.query(
      'SELECT user_id FROM users WHERE email = $1 OR telephone = $2',
      [email, telephone]
    );
    if (exist.rows.length > 0) {
      return res.status(409).json({ message: 'Email ou téléphone déjà utilisé.' });
    }

    // Hasher le mot de passe
    const hashedPassword = await bcrypt.hash(password, 10);

    // Insérer l'utilisateur
    const result = await pool.query(
      `INSERT INTO users (nom, prenom, email, telephone, password)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING user_id, nom, prenom, email, telephone, date_inscription`,
      [nom, prenom, email, telephone, hashedPassword]
    );

    res.status(201).json({
      message: 'Compte créé avec succès.',
      user: result.rows[0]
    });

  } catch (err) {
    console.error('Erreur register :', err);
    res.status(500).json({ message: 'Erreur serveur.' });
  }
};

// POST /api/auth/login
const login = async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ message: 'Email et mot de passe obligatoires.' });
  }

  try {
    // Chercher l'utilisateur
    const result = await pool.query(
      'SELECT * FROM users WHERE email = $1 AND statut = true',
      [email]
    );

    if (result.rows.length === 0) {
      return res.status(401).json({ message: 'Identifiants incorrects.' });
    }

    const user = result.rows[0];

    // Vérifier le mot de passe
    const validPassword = await bcrypt.compare(password, user.password);
    if (!validPassword) {
      return res.status(401).json({ message: 'Identifiants incorrects.' });
    }

    // Générer le token JWT
    const token = jwt.sign(
      { user_id: user.user_id, email: user.email },
      process.env.JWT_SECRET,
      { expiresIn: '24h' }
    );

    res.status(200).json({
      message: 'Connexion réussie.',
      token,
      user: {
        user_id: user.user_id,
        nom: user.nom,
        prenom: user.prenom,
        email: user.email,
        telephone: user.telephone
      }
    });

  } catch (err) {
    console.error('Erreur login :', err);
    res.status(500).json({ message: 'Erreur serveur.' });
  }
};

// POST /api/auth/refresh — Renouvellement du token du bracelet
// Le refreshToken opaque est cherché puis remplacé (rotation) dans la colonne
// token_auth de la table bracelets, au lieu d'une colonne refresh_token séparée.
const refreshToken = async (req, res) => {
  const { refreshToken: token } = req.body;

  if (!token) {
    return res.status(400).json({ message: 'Refresh token obligatoire.' });
  }

  try {
    const result = await pool.query(
      `SELECT id_bracelet, identifiant_unique, group_id 
       FROM bracelets WHERE token_auth = $1`,
      [token]
    );

    if (result.rows.length === 0) {
      return res.status(401).json({ message: 'Refresh token invalide.' });
    }

    const bracelet = result.rows[0];

    const newAccessToken = jwt.sign(
      {
        bracelet_id: bracelet.id_bracelet,
        identifiant_unique: bracelet.identifiant_unique,
        group_id: bracelet.group_id,
        role: 'bracelet'
      },
      process.env.JWT_SECRET,
      { expiresIn: '24h' }
    );

    const newRefreshToken = crypto.randomBytes(40).toString('hex');

    await pool.query(
      `UPDATE bracelets
       SET token_auth = $1
       WHERE id_bracelet = $2`,
      [newRefreshToken, bracelet.id_bracelet]
    );

    res.status(200).json({
      accessToken: newAccessToken,
      refreshToken: newRefreshToken
    });
  } catch (err) {
    console.error('Erreur refreshToken :', err);
    res.status(500).json({ message: 'Erreur serveur.' });
  }
};

module.exports = { register, login, refreshToken };