const express = require('express');
const cors = require('cors');
const http = require('http');
const { Server } = require('socket.io');
require('dotenv').config();

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: { origin: '*' }
});

// Middlewares globaux
app.use(cors());
app.use(express.json());

// Attacher io à chaque requête
// pour que les controllers puissent l'utiliser
app.use((req, res, next) => {
  req.io = io;
  next();
});

// Routes
app.use('/api/auth',        require('./src/routes/auth.routes'));
app.use('/api/groupes',     require('./src/routes/groupes.routes'));
app.use('/api/invitations', require('./src/routes/invitations.routes'));
app.use('/api/positions',   require('./src/routes/positions.routes'));
app.use('/api/users',       require('./src/routes/invitations.routes'));
app.use('/api',             require('./src/routes/bracelets.routes'));
app.use('/api/locations',          require('./src/routes/location.routes'));

// Route de test
app.get('/', (req, res) => {
  res.json({ message: 'CamerTrack API is running' });
});

// Socket.io
require('./src/socket/socket')(io);

// Démarrage
const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`Serveur démarré sur le port ${PORT}`);
});