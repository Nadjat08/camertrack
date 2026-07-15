import 'dart:convert';
import 'http_client.dart';
import 'package:geolocator/geolocator.dart';
import '../config/api_config.dart';
import '../models/membre_position.dart';

class PositionService {

  // Demander la permission GPS
  static Future<bool> demanderPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }

    if (permission == LocationPermission.deniedForever) return false;

    return true;
  }

  // Obtenir la position actuelle
  static Future<Position?> obtenirPosition() async {
    final permissionOk = await demanderPermission();
    if (!permissionOk) return null;

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      return null;
    }
  }

  // Envoyer sa position au backend
  static Future<bool> envoyerPosition(double lat, double lng) async {
    try {
      final response = await HttpClient.post(
        ApiConfig.positions,
        body: {
          'latitude': lat,
          'longitude': lng,
          'precision': 10.0,
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }



  // Récupérer les positions des membres de tous les groupes
  static Future<List<MembrePosition>> getPositionsMembres() async {
    try {
      final response = await HttpClient.get(ApiConfig.positionsMembres);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List membres = data['membres'] ?? [];
        return membres.map((m) => MembrePosition.fromJson(m)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}