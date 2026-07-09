const express = require('express');
const router = express.Router();
const { verifierUserToken } = require('../middleware/auth');
const {
  envoyerInvitation,
  listerInvitationsRecues,
  accepterInvitation,
  refuserInvitation,
  rechercherUtilisateur
} = require('../controllers/invitations.controller');

router.post('/', verifierUserToken, envoyerInvitation);
router.get('/', verifierUserToken, listerInvitationsRecues);
router.put('/:id/accepter', verifierUserToken, accepterInvitation);
router.put('/:id/refuser', verifierUserToken, refuserInvitation);
router.get('/rechercher', verifierUserToken, rechercherUtilisateur);

module.exports = router;