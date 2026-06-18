const express = require('express');
const router = express.Router();

router.post('/', (req, res) => {
  res.json({ message: 'POST position — à implémenter' });
});

module.exports = router;