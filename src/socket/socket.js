module.exports = (io) => {
  io.on('connection', (socket) => {
    console.log('Nouveau client connecté :', socket.id);

    socket.on('disconnect', () => {
      console.log('Client déconnecté :', socket.id);
    });
  });
};