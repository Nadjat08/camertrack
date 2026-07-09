const express = require('express');
const router = express.Router();
const { verifierUserToken } = require('../middleware/auth');
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
router.post('/', verifierUserToken, creerGroupe);
router.get('/', verifierUserToken, listerGroupes);
router.get('/:id', verifierUserToken, detailGroupe);
router.put('/:id', verifierUserToken, modifierGroupe);
router.delete('/:id', verifierUserToken, supprimerGroupe);
router.delete('/:id/membres/:userId', verifierUserToken, retirerMembre);
router.delete('/:id/quitter', verifierUserToken, quitterGroupe);

module.exports = router;