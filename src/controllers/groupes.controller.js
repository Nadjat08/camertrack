const pool = require('../config/db');

// POST /api/groupes — Créer un groupe
const creerGroupe = async (req, res) => {
  const { nom_grp } = req.body;
  const admin_id = req.user.user_id; // récupéré depuis le token JWT

  if (!nom_grp || nom_grp.trim() === '') {
    return res.status(400).json({ message: 'Le nom du groupe est obligatoire.' });
  }

  try {
    // Créer le groupe
    const result = await pool.query(
      `INSERT INTO groupes (nom_grp, admin_id)
       VALUES ($1, $2)
       RETURNING group_id, nom_grp, admin_id, date_creation`,
      [nom_grp.trim(), admin_id]
    );

    const groupe = result.rows[0];

    // Ajouter automatiquement le créateur comme membre admin
    await pool.query(
      `INSERT INTO membres_groupe (group_id, user_id, role)
       VALUES ($1, $2, 'admin')`,
      [groupe.group_id, admin_id]
    );

    res.status(201).json({
      message: 'Groupe cV/réé avec succès.',
      groupe
    });

  } catch (err) {
    console.error('Erreur creerGroupe :', err);
    res.status(500).json({ message: 'Erreur serveur.' });
  }
};

// GET /api/groupes — Lister les groupes de l'utilisateur connecté
const listerGroupes = async (req, res) => {
  const user_id = req.user.user_id;

  try {
    const result = await pool.query(
      `SELECT g.group_id, g.nom_grp, g.admin_id, g.date_creation,
              mg.role,
              COUNT(mg2.id) AS nombre_membres
       FROM groupes g
       INNER JOIN membres_groupe mg ON mg.group_id = g.group_id
                                   AND mg.user_id = $1
                                   AND mg.actif = true
       INNER JOIN membres_groupe mg2 ON mg2.group_id = g.group_id
                                    AND mg2.actif = true
       GROUP BY g.group_id, g.nom_grp, g.admin_id, g.date_creation, mg.role
       ORDER BY g.date_creation DESC`,
      [user_id]
    );

    res.status(200).json({
      groupes: result.rows
    });

  } catch (err) {
    console.error('Erreur listerGroupes :', err);
    res.status(500).json({ message: 'Erreur serveur.' });
  }
};

// GET /api/groupes/:id — Détail d'un groupe
const detailGroupe = async (req, res) => {
  const { id } = req.params;
  const user_id = req.user.user_id;

  try {
    // Vérifier que l'utilisateur est membre du groupe
    const membre = await pool.query(
      `SELECT id FROM membres_groupe
       WHERE group_id = $1 AND user_id = $2 AND actif = true`,
      [id, user_id]
    );

    if (membre.rows.length === 0) {
      return res.status(403).json({ message: 'Accès refusé.' });
    }

    // Récupérer les infos du groupe + membres
    const groupe = await pool.query(
      `SELECT g.group_id, g.nom_grp, g.admin_id, g.date_creation
       FROM groupes g WHERE g.group_id = $1`,
      [id]
    );

    const membres = await pool.query(
      `SELECT u.user_id, u.nom, u.prenom, u.telephone, mg.role, mg.date_ajout
       FROM membres_groupe mg
       INNER JOIN users u ON u.user_id = mg.user_id
       WHERE mg.group_id = $1 AND mg.actif = true
       ORDER BY mg.date_ajout ASC`,
      [id]
    );

    res.status(200).json({
      groupe: groupe.rows[0],
      membres: membres.rows
    });

  } catch (err) {
    console.error('Erreur detailGroupe :', err);
    res.status(500).json({ message: 'Erreur serveur.' });
  }
};

// PUT /api/groupes/:id — Modifier le nom du groupe
const modifierGroupe = async (req, res) => {
  const { id } = req.params;
  const { nom_grp } = req.body;
  const user_id = req.user.user_id;

  if (!nom_grp || nom_grp.trim() === '') {
    return res.status(400).json({ message: 'Le nom est obligatoire.' });
  }

  try {
    // Vérifier que l'utilisateur est admin
    const check = await pool.query(
      `SELECT id FROM membres_groupe
       WHERE group_id = $1 AND user_id = $2 AND role = 'admin' AND actif = true`,
      [id, user_id]
    );

    if (check.rows.length === 0) {
      return res.status(403).json({ message: 'Seul l\'administrateur peut modifier le groupe.' });
    }

    await pool.query(
      `UPDATE groupes SET nom_grp = $1 WHERE group_id = $2`,
      [nom_grp.trim(), id]
    );

    res.status(200).json({ message: 'Groupe modifié avec succès.' });

  } catch (err) {
    console.error('Erreur modifierGroupe :', err);
    res.status(500).json({ message: 'Erreur serveur.' });
  }
};

// DELETE /api/groupes/:id — Supprimer un groupe
const supprimerGroupe = async (req, res) => {
  const { id } = req.params;
  const user_id = req.user.user_id;

  try {
    // Vérifier que l'utilisateur est admin
    const check = await pool.query(
      `SELECT id FROM membres_groupe
       WHERE group_id = $1 AND user_id = $2 AND role = 'admin' AND actif = true`,
      [id, user_id]
    );

    if (check.rows.length === 0) {
      return res.status(403).json({ message: 'Seul l\'administrateur peut supprimer le groupe.' });
    }

    // Désactiver tous les membres
    await pool.query(
      `UPDATE membres_groupe SET actif = false WHERE group_id = $1`,
      [id]
    );

    // Supprimer le groupe
    await pool.query(
      `DELETE FROM groupes WHERE group_id = $1`,
      [id]
    );

    res.status(200).json({ message: 'Groupe supprimé avec succès.' });

  } catch (err) {
    console.error('Erreur supprimerGroupe :', err);
    res.status(500).json({ message: 'Erreur serveur.' });
  }
};

// DELETE /api/groupes/:id/membres/:userId — Retirer un membre
const retirerMembre = async (req, res) => {
  const { id, userId } = req.params;
  const admin_id = req.user.user_id;

  try {
    // Vérifier que c'est bien l'admin
    const check = await pool.query(
      `SELECT id FROM membres_groupe
       WHERE group_id = $1 AND user_id = $2 AND role = 'admin' AND actif = true`,
      [id, admin_id]
    );

    if (check.rows.length === 0) {
      return res.status(403).json({ message: 'Seul l\'administrateur peut retirer un membre.' });
    }

    // Ne pas permettre à l'admin de se retirer lui-même
    if (parseInt(userId) === admin_id) {
      return res.status(400).json({ message: 'L\'administrateur ne peut pas se retirer lui-même.' });
    }

    await pool.query(
      `UPDATE membres_groupe SET actif = false
       WHERE group_id = $1 AND user_id = $2`,
      [id, userId]
    );

    res.status(200).json({ message: 'Membre retiré avec succès.' });

  } catch (err) {
    console.error('Erreur retirerMembre :', err);
    res.status(500).json({ message: 'Erreur serveur.' });
  }
};

// DELETE /api/groupes/:id/quitter — Quitter un groupe
const quitterGroupe = async (req, res) => {
  const { id } = req.params;
  const user_id = req.user.user_id;

  try {
    // Vérifier que l'utilisateur est membre
    const membre = await pool.query(
      `SELECT role FROM membres_groupe
       WHERE group_id = $1 AND user_id = $2 AND actif = true`,
      [id, user_id]
    );

    if (membre.rows.length === 0) {
      return res.status(404).json({ message: 'Vous n\'êtes pas membre de ce groupe.' });
    }

    // L'admin ne peut pas quitter sans transférer l'admin
    if (membre.rows[0].role === 'admin') {
      return res.status(400).json({
        message: 'Vous êtes administrateur. Transférez le rôle avant de quitter.'
      });
    }

    await pool.query(
      `UPDATE membres_groupe SET actif = false
       WHERE group_id = $1 AND user_id = $2`,
      [id, user_id]
    );

    res.status(200).json({ message: 'Vous avez quitté le groupe.' });

  } catch (err) {
    console.error('Erreur quitterGroupe :', err);
    res.status(500).json({ message: 'Erreur serveur.' });
  }
};

module.exports = {
  creerGroupe,
  listerGroupes,
  detailGroupe,
  modifierGroupe,
  supprimerGroupe,
  retirerMembre,
  quitterGroupe
};