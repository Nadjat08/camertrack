const express = require('express');
const router = express.Router();
const verifierToken = require('../middleware/auth');
const verifierBraceletToken = require('../middleware/braceletAuth');
const { syncLocation, syncSos } = require('../controllers/locations.controller');

router.post('/location/sync', verifierBraceletToken, syncLocation);
router.post('/sos/sync', verifierBraceletToken, syncSos);

module.exports = router;
