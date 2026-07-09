const express = require('express');
const router = express.Router();
const verifierToken = require('../middleware/auth');
const {
  envoyerInvitation,
  listerInvitationsRecues,
  accepterInvitation,
  refuserInvitation,
  rechercherUtilisateur
} = require('../controllers/invitations.controller');

router.post('/', verifierToken, envoyerInvitation);
router.get('/', verifierToken, listerInvitationsRecues);
router.put('/:id/accepter', verifierToken, accepterInvitation);
router.put('/:id/refuser', verifierToken, refuserInvitation);
router.get('/rechercher', verifierToken, rechercherUtilisateur);

module.exports = router;