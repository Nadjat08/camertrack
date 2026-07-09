const express = require('express');
const router = express.Router();
const verifierToken = require('../middleware/auth');
const {
  envoyerPosition,
  getPositionsMembres
} = require('../controllers/positions.controller');

router.post('/', verifierToken, envoyerPosition);
router.get('/membres', verifierToken, getPositionsMembres);

module.exports = router;