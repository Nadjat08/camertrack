const pool = require('../config/db');

// POST /api/invitations — Envoyer une invitation
const envoyerInvitation = async (req, res) => {
  const { group_id, telephone } = req.body;
  const inviteur_id = req.user.user_id;

  if (!group_id || !telephone) {
    return res.status(400).json({ message: 'group_id et téléphone sont obligatoires.' });
  }

  try {
    // Vérifier que l'inviteur est admin du groupe
    const adminCheck = await pool.query(
      `SELECT id FROM membres_groupe
       WHERE group_id = $1 AND user_id = $2 AND role = 'admin' AND actif = true`,
      [group_id, inviteur_id]
    );

    if (adminCheck.rows.length === 0) {
      return res.status(403).json({ message: 'Seul l\'administrateur peut inviter.' });
    }

    // Chercher l'utilisateur par téléphone
    const userResult = await pool.query(
      `SELECT user_id, nom, prenom, telephone
       FROM users WHERE telephone = $1 AND statut = true`,
      [telephone]
    );

    if (userResult.rows.length === 0) {
      return res.status(404).json({
        message: 'Aucun utilisateur trouvé avec ce numéro de téléphone.'
      });
    }

    const invite = userResult.rows[0];

    // Vérifier que l'invité n'est pas déjà membre
    const dejaMembreCheck = await pool.query(
      `SELECT id FROM membres_groupe
       WHERE group_id = $1 AND user_id = $2 AND actif = true`,
      [group_id, invite.user_id]
    );

    if (dejaMembreCheck.rows.length > 0) {
      return res.status(409).json({ message: 'Cet utilisateur est déjà membre du groupe.' });
    }

    // Vérifier qu'il n'y a pas déjà une invitation en attente
    const invitExistante = await pool.query(
      `SELECT id_invit FROM invitations
       WHERE group_id = $1 AND invite_id = $2 AND statut = 'en_attente'`,
      [group_id, invite.user_id]
    );

    if (invitExistante.rows.length > 0) {
      return res.status(409).json({ message: 'Une invitation est déjà en attente pour cet utilisateur.' });
    }

    // Créer l'invitation — expire dans 48h
    const expiration = new Date();
    expiration.setHours(expiration.getHours() + 48);

    const result = await pool.query(
      `INSERT INTO invitations (group_id, inviteur_id, invite_id, statut, expire_le)
       VALUES ($1, $2, $3, 'en_attente', $4)
       RETURNING id_invit, group_id, statut, date_creation, expire_le`,
      [group_id, inviteur_id, invite.user_id, expiration]
    );

    res.status(201).json({
      message: `Invitation envoyée à ${invite.prenom} ${invite.nom}.`,
      invitation: result.rows[0],
      invite: {
        user_id: invite.user_id,
        nom: invite.nom,
        prenom: invite.prenom,
        telephone: invite.telephone
      }
    });

  } catch (err) {
    console.error('Erreur envoyerInvitation :', err);
    res.status(500).json({ message: 'Erreur serveur.' });
  }
};

// GET /api/invitations — Lister les invitations reçues
const listerInvitationsRecues = async (req, res) => {
  const user_id = req.user.user_id;

  try {
    const result = await pool.query(
      `SELECT i.id_invit, i.statut, i.date_creation, i.expire_le,
              g.nom_grp, g.group_id,
              u.nom AS inviteur_nom, u.prenom AS inviteur_prenom,
              u.telephone AS inviteur_telephone
       FROM invitations i
       INNER JOIN groupes g ON g.group_id = i.group_id
       INNER JOIN users u ON u.user_id = i.inviteur_id
       WHERE i.invite_id = $1
       ORDER BY i.date_creation DESC`,
      [user_id]
    );

    res.status(200).json({ invitations: result.rows });

  } catch (err) {
    console.error('Erreur listerInvitationsRecues :', err);
    res.status(500).json({ message: 'Erreur serveur.' });
  }
};

// PUT /api/invitations/:id/accepter — Accepter une invitation
const accepterInvitation = async (req, res) => {
  const { id } = req.params;
  const user_id = req.user.user_id;

  try {
    // Récupérer l'invitation
    const invitResult = await pool.query(
      `SELECT * FROM invitations
       WHERE id_invit = $1 AND invite_id = $2`,
      [id, user_id]
    );

    if (invitResult.rows.length === 0) {
      return res.status(404).json({ message: 'Invitation introuvable.' });
    }

    const invitation = invitResult.rows[0];

    // Vérifier le statut
    if (invitation.statut !== 'en_attente') {
      return res.status(400).json({
        message: `Cette invitation a déjà été ${invitation.statut}.`
      });
    }

    // Vérifier l'expiration
    if (new Date() > new Date(invitation.expire_le)) {
      await pool.query(
        `UPDATE invitations SET statut = 'expiree' WHERE id_invit = $1`,
        [id]
      );
      return res.status(400).json({ message: 'Cette invitation a expiré.' });
    }

    // Ajouter l'utilisateur comme membre du groupe
    await pool.query(
      `INSERT INTO membres_groupe (group_id, user_id, role)
       VALUES ($1, $2, 'membre')
       ON CONFLICT DO NOTHING`,
      [invitation.group_id, user_id]
    );

    // Mettre à jour le statut de l'invitation
    await pool.query(
      `UPDATE invitations SET statut = 'acceptee' WHERE id_invit = $1`,
      [id]
    );

    res.status(200).json({ message: 'Invitation acceptée. Vous êtes maintenant membre du groupe.' });

  } catch (err) {
    console.error('Erreur accepterInvitation :', err);
    res.status(500).json({ message: 'Erreur serveur.' });
  }
};

// PUT /api/invitations/:id/refuser — Refuser une invitation
const refuserInvitation = async (req, res) => {
  const { id } = req.params;
  const user_id = req.user.user_id;

  try {
    const invitResult = await pool.query(
      `SELECT * FROM invitations
       WHERE id_invit = $1 AND invite_id = $2 AND statut = 'en_attente'`,
      [id, user_id]
    );

    if (invitResult.rows.length === 0) {
      return res.status(404).json({ message: 'Invitation introuvable ou déjà traitée.' });
    }

    await pool.query(
      `UPDATE invitations SET statut = 'refusee' WHERE id_invit = $1`,
      [id]
    );

    res.status(200).json({ message: 'Invitation refusée.' });

  } catch (err) {
    console.error('Erreur refuserInvitation :', err);
    res.status(500).json({ message: 'Erreur serveur.' });
  }
};

// GET /api/users/rechercher?telephone=6XX — Rechercher un utilisateur
const rechercherUtilisateur = async (req, res) => {
  const { telephone, nom } = req.query;
  const user_id = req.user.user_id;

  if (!telephone && !nom) {
    return res.status(400).json({ message: 'Fournissez un téléphone ou un nom.' });
  }

  try {
    let result;

    if (telephone) {
      result = await pool.query(
        `SELECT user_id, nom, prenom, telephone
         FROM users
         WHERE telephone LIKE $1 AND user_id != $2 AND statut = true
         LIMIT 10`,
        [`%${telephone}%`, user_id]
      );
    } else {
      result = await pool.query(
        `SELECT user_id, nom, prenom, telephone
         FROM users
         WHERE (LOWER(nom) LIKE LOWER($1) OR LOWER(prenom) LIKE LOWER($1))
         AND user_id != $2 AND statut = true
         LIMIT 10`,
        [`%${nom}%`, user_id]
      );
    }

    res.status(200).json({ utilisateurs: result.rows });

  } catch (err) {
    console.error('Erreur rechercherUtilisateur :', err);
    res.status(500).json({ message: 'Erreur serveur.' });
  }
};

module.exports = {
  envoyerInvitation,
  listerInvitationsRecues,
  accepterInvitation,
  refuserInvitation,
  rechercherUtilisateur
};