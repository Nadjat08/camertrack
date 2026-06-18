const express = require('express');
const router = express.Router();

router.post('/', (req, res) => {
  res.json({ message: 'POST invitation — à implémenter' });
});

router.put('/:id/accepter', (req, res) => {
  res.json({ message: 'Accepter invitation — à implémenter' });
});

router.put('/:id/refuser', (req, res) => {
  res.json({ message: 'Refuser invitation — à implémenter' });
});

module.exports = router;