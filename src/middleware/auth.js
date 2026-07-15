const jwt = require('jsonwebtoken');
const logger = require('../utils/logger');

const verifierToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1]; // Format : Bearer <token>

  if (!token) {
    logger.warn('Auth rejected: missing token', { path: req.originalUrl, method: req.method });
    return res.status(401).json({ message: 'Token manquant. Accès refusé.' });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded; // { user_id, email }
    logger.info('Auth accepted', { userId: decoded.user_id, path: req.originalUrl });
    next();
  } catch (err) {
    logger.warn('Auth rejected: invalid token', { path: req.originalUrl, error: err.message });
    return res.status(403).json({ message: 'Token invalide ou expiré.' });
  }
};

module.exports = verifierToken;