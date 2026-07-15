import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'Auth_gard.dart';

// Clé globale pour accéder au contexte de navigation
// depuis n'importe où dans l'app
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class HttpClient {

  // Récupérer le token JWT
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Vérifier la réponse et déconnecter si token expiré
  static Future<void> _verifierReponse(http.Response response) async {
    if (response.statusCode == 401 || response.statusCode == 403) {
      // Token expiré ou invalide
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('user_id');
      await prefs.remove('nom');
      await prefs.remove('email');

      // Rediriger vers login depuis n'importe où
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/login',
            (route) => false,
      );
    }
  }

  // Headers communs avec JWT
  static Future<Map<String, String>> _headers() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // GET
  static Future<http.Response> get(String url) async {
    final response = await http.get(
      Uri.parse(url),
      headers: await _headers(),
    );
    await _verifierReponse(response);
    return response;
  }

  // POST
  static Future<http.Response> post(
      String url, {
        Map<String, dynamic>? body,
      }) async {
    final response = await http.post(
      Uri.parse(url),
      headers: await _headers(),
      body: body != null ? jsonEncode(body) : null,
    );
    await _verifierReponse(response);
    return response;
  }

  // PUT
  static Future<http.Response> put(
      String url, {
        Map<String, dynamic>? body,
      }) async {
    final response = await http.put(
      Uri.parse(url),
      headers: await _headers(),
      body: body != null ? jsonEncode(body) : null,
    );
    await _verifierReponse(response);
    return response;
  }

  // DELETE
  static Future<http.Response> delete(String url) async {
    final response = await http.delete(
      Uri.parse(url),
      headers: await _headers(),
    );
    await _verifierReponse(response);
    return response;
  }
}