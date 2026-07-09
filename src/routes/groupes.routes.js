const express = require('express');
const router = express.Router();
const verifierToken = require('../middleware/auth');
const {
  creerGroupe,
  listerGroupes,
  detailGroupe,
  modifierGroupe,
  supprimerGroupe,
  retirerMembre,
  quitterGroupe
} = require('../controllers/groupes.controller');

// Toutes les routes groupes nécessitent un JWT
router.post('/', verifierToken, creerGroupe);
router.get('/', verifierToken, listerGroupes);
router.get('/:id', verifierToken, detailGroupe);
router.put('/:id', verifierToken, modifierGroupe);
router.delete('/:id', verifierToken, supprimerGroupe);
router.delete('/:id/membres/:userId', verifierToken, retirerMembre);
router.delete('/:id/quitter', verifierToken, quitterGroupe);

module.exports = router;