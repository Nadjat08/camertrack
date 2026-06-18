const express = require('express');
const router = express.Router();

router.get('/', (req, res) => {
  res.json({ message: 'GET groupes — à implémenter' });
});

router.post('/', (req, res) => {
  res.json({ message: 'POST groupes — à implémenter' });
});

module.exports = router;