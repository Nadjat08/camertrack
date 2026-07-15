const express = require('express');
const router = express.Router();
const verifierToken = require('../middleware/auth');
const {
  ajouterBracelet,
  verifierBracelet,
  enregistrerBracelet,
  statutBracelet
} = require('../controllers/bracelets.controller');

// Routes appelées par le PARENT (authentifiées)
router.post('/groupes/:id/bracelets', verifierToken, ajouterBracelet);
router.get('/bracelets/:identifiant', verifierToken, verifierBracelet);

// Routes appelées par LA MONTRE (pas de token requis, elle n'en a pas encore)
router.post('/bracelets/enregistrer', enregistrerBracelet);
router.get('/bracelets/status/:identifiant', statutBracelet);

module.exports = router;