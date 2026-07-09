const express = require('express');
const router = express.Router();
const { verifierUserToken } = require('../middleware/auth');
const {
  ajouterBracelet,
  verifierBracelet,
  enregistrerBracelet,
  statutBracelet
} = require('../controllers/bracelets.controller');

router.post('/bracelets/enregistrer', enregistrerBracelet);
router.get('/bracelets/status/:identifiant', statutBracelet);

router.post('/groupes/:id/bracelets', verifierUserToken, ajouterBracelet);
router.get('/bracelets/:identifiant', verifierUserToken, verifierBracelet);

module.exports = router;