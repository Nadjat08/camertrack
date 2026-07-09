const express = require('express');
const router = express.Router();
const verifierToken = require('../middleware/auth');
const {
  ajouterBracelet,
  verifierBracelet
} = require('../controllers/bracelets.controller');

router.post('/groupes/:id/bracelets', verifierToken, ajouterBracelet);
router.get('/bracelets/:identifiant', verifierToken, verifierBracelet);

module.exports = router;