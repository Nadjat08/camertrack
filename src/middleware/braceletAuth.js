const jwt = require('jsonwebtoken');
const logger = require('../utils/logger');

const verifierBraceletToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    logger.warn('Bracelet auth rejected: missing token', { path: req.originalUrl, method: req.method });
    return res.status(401).json({ message: 'Token bracelet manquant. Accès refusé.' });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    if (decoded.role !== 'bracelet') {
      logger.warn('Bracelet auth rejected: bad role', { path: req.originalUrl, role: decoded.role });
      return res.status(403).json({ message: 'Token invalide pour une montre.' });
    }

    req.bracelet = decoded;
    req.auth = decoded;
    logger.info('Bracelet auth accepted', { braceletId: decoded.bracelet_id, path: req.originalUrl });
    next();
  } catch (err) {
    logger.warn('Bracelet auth rejected: invalid token', { path: req.originalUrl, error: err.message });
    return res.status(403).json({ message: 'Token bracelet invalide ou expiré.' });
  }
};

module.exports = verifierBraceletToken;
