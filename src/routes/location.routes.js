const express = require('express');
const router = express.Router();
const { verifierBraceletToken } = require('../middleware/auth');
const { syncPositions, syncSos } = require('../controllers/location.controller');

// Routes protégées par l'authentification M2M (Bracelet)
router.post('/location/sync', verifierBraceletToken, syncPositions);
router.post('/sos/sync', verifierBraceletToken, syncSos);

module.exports = router;
