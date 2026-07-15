import 'dart:convert';
import '../config/api_config.dart';
import 'http_client.dart';

class GroupesService {

  // Récupérer tous les groupes
  static Future<List<Map<String, dynamic>>> getGroupes() async {
    try {
      final response = await HttpClient.get(ApiConfig.groupes);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['groupes']);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Récupérer les IDs des groupes
  static Future<List<int>> getGroupeIds() async {
    final groupes = await getGroupes();
    return groupes.map<int>((g) => g['group_id'] as int).toList();
  }

  // Créer un groupe
  static Future<Map<String, dynamic>> creerGroupe(String nomGroupe) async {
    try {
      final response = await HttpClient.post(
        ApiConfig.groupes,
        body: {'nom_grp': nomGroupe},
      );

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 201,
        'message': data['message'],
        'groupe': data['groupe'],
      };
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion.'};
    }
  }

  // Détail d'un groupe avec ses membres
  static Future<Map<String, dynamic>?> getDetailGroupe(int groupId) async {
    try {
      final response = await HttpClient.get(
        '${ApiConfig.groupes}/$groupId',
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Rechercher un utilisateur
  static Future<List<Map<String, dynamic>>> rechercherUtilisateur(
      String query, bool parTelephone) async {
    try {
      final param = parTelephone
          ? 'telephone=$query'
          : 'nom=$query';

      final response = await HttpClient.get(
        '${ApiConfig.rechercherUser}?$param',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['utilisateurs']);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Envoyer une invitation
  static Future<Map<String, dynamic>> envoyerInvitation(
      int groupId, String telephone) async {
    try {
      final response = await HttpClient.post(
        ApiConfig.invitations,
        body: {
          'group_id': groupId,
          'telephone': telephone,
        },
      );

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 201,
        'message': data['message'],
      };
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion.'};
    }
  }

  // Quitter un groupe
  static Future<Map<String, dynamic>> quitterGroupe(int groupId) async {
    try {
      final response = await HttpClient.delete(
        '${ApiConfig.groupes}/$groupId/quitter',
      );

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'message': data['message'],
      };
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion.'};
    }
  }
}