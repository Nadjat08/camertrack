import 'package:socket_io_client/socket_io_client.dart';
import '../config/api_config.dart';

class SocketService {
  static Socket? _socket;

  static Socket get socket {
    _socket ??= io(
      ApiConfig.socketBaseUrl,
      OptionBuilder().setTransports(['websocket']).disableAutoConnect().build(),
    );
    return _socket!;
  }

  // Connecter et rejoindre les rooms des groupes
  static Future<void> connecter(List<int> groupIds) async {
    if (socket.connected) return;

    socket.connect();

    socket.onConnect((_) {
      // Rejoindre toutes les rooms des groupes
      socket.emit('rejoindre_groupes', groupIds);
    });

    socket.onDisconnect((_) {
      // socket disconnected
    });
  }

  // Écouter les mises à jour de positions
  static void ecouterPositions(Function(Map<String, dynamic>) callback) {
    socket.on('position_mise_a_jour', (data) {
      callback(Map<String, dynamic>.from(data));
    });
  }

  // Écouter les alertes SOS envoyées par le bracelet
  static void ecouterSos(Function(Map<String, dynamic>) callback) {
    socket.on('sos_declenche', (data) {
      callback(Map<String, dynamic>.from(data));
    });
  }

  // Déconnecter
  static void deconnecter() {
    socket.disconnect();
  }
}
