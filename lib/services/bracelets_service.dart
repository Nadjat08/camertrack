import 'dart:convert';
import '../config/api_config.dart';
import 'http_client.dart';

class BraceletsService {
  // Associer un bracelet déjà enregistré (scanné via QR) à un groupe
  static Future<Map<String, dynamic>> ajouterBracelet({
    required int groupId,
    required String identifiantUnique,
    required String nomEnfant,
    required String prenomEnfant,
    String? dateNaissance, // format attendu par le backend : 'YYYY-MM-DD'
  }) async {
    try {
      final response = await HttpClient.post(
        ApiConfig.bracelets(groupId),
        body: {
          'identifiant_unique': identifiantUnique,
          'nom_enfant': nomEnfant,
          'prenom_enfant': prenomEnfant,
          if (dateNaissance != null) 'date_naissance': dateNaissance,
        },
      );

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 201,
        'message': data['message'],
        'bracelet': data['bracelet'],
      };
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion.'};
    }
  }
}