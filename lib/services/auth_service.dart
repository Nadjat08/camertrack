import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class AuthService {
  // Inscription
  static Future<Map<String, dynamic>> register({
    required String nom,
    String? prenom,
    required String email,
    required String telephone,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.register),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nom': nom,
          'prenom': prenom,
          'email': email,
          'telephone': telephone,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      return {
        'success': response.statusCode == 201,
        'message': data['message'],
        'data': data,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Impossible de contacter le serveur. Vérifiez votre connexion.',
      };
    }
  }

  // Connexion
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.login),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Sauvegarder le token et les infos utilisateur
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setInt('user_id', data['user']['user_id']);
        await prefs.setString('nom', data['user']['nom']);
        await prefs.setString('prenom', data['user']['prenom'] ?? '');
        await prefs.setString('email', data['user']['email']);
        await prefs.setString('telephone', data['user']['telephone'] ?? '');
      }

      return {
        'success': response.statusCode == 200,
        'message': data['message'],
        'data': data,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Impossible de contacter le serveur. Vérifiez votre connexion.',
      };
    }
  }

  // Récupérer les infos du compte connecté, stockées localement
  static Future<Map<String, String>> getUtilisateurLocal() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'nom': prefs.getString('nom') ?? '',
      'prenom': prefs.getString('prenom') ?? '',
      'email': prefs.getString('email') ?? '',
      'telephone': prefs.getString('telephone') ?? '',
    };
  }

  // Déconnexion
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user_id');
    await prefs.remove('nom');
    await prefs.remove('prenom');
    await prefs.remove('email');
    await prefs.remove('telephone');
  }
}