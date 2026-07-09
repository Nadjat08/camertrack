module.exports = (io) => {
  io.on('connection', (socket) => {
    console.log('Client connecté :', socket.id);

    // Un membre rejoint les rooms de ses groupes
    socket.on('rejoindre_groupes', (groupIds) => {
      if (Array.isArray(groupIds)) {
        groupIds.forEach(groupId => {
          socket.join(`groupe_${groupId}`);
          console.log(`Socket ${socket.id} a rejoint groupe_${groupId}`);
        });
      }
    });

    // Un membre quitte ses rooms
    socket.on('quitter_groupes', (groupIds) => {
      if (Array.isArray(groupIds)) {
        groupIds.forEach(groupId => {
          socket.leave(`groupe_${groupId}`);
        });
      }
    });

    socket.on('disconnect', () => {
      console.log('Client déconnecté :', socket.id);
    });
  });
};