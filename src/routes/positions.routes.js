const express = require('express');
const router = express.Router();
const { verifierUserToken } = require('../middleware/auth');
const {
  envoyerPosition,
  getPositionsMembres
} = require('../controllers/positions.controller');

router.post('/', verifierUserToken, envoyerPosition);
router.get('/membres', verifierUserToken, getPositionsMembres);

module.exports = router;