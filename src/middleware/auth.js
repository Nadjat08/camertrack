const jwt = require('jsonwebtoken');

const verifierUserToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ message: 'Token manquant. Accès refusé.' });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    if (decoded.role === 'bracelet') {
      return res.status(403).json({ message: 'Token bracelet non autorisé ici.' });
    }
    req.user = decoded; // { user_id, email }
    next();
  } catch (err) {
    return res.status(403).json({ message: 'Token invalide ou expiré.' });
  }
};

const verifierBraceletToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ message: 'Token manquant. Accès refusé.' });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    if (decoded.role !== 'bracelet') {
      return res.status(403).json({ message: 'Token utilisateur non autorisé ici.' });
    }
    req.bracelet = decoded; // { bracelet_id, identifiant_unique, group_id, role: 'bracelet' }
    next();
  } catch (err) {
    return res.status(403).json({ message: 'Token invalide ou expiré.' });
  }
};

module.exports = { verifierUserToken, verifierBraceletToken };