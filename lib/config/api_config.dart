class ApiConfig {
  static const String baseUrl = 'http://192.168.1.123:3000/api';
  // Auth
  static const String register = '$baseUrl/auth/register';
  static const String login    = '$baseUrl/auth/login';

  // Groupes
  static const String groupes  = '$baseUrl/groupes';

  // Invitations
  static const String invitations       = '$baseUrl/invitations';
  static const String rechercherUser    = '$baseUrl/users/rechercher';

  // Positions
  static const String positions         = '$baseUrl/positions';
  static const String positionsMembres  = '$baseUrl/positions/membres';

  // Bracelets — POST /api/groupes/:id/bracelets (route existante dans bracelets.routes.js)
  static String bracelets(int groupId) => '$baseUrl/groupes/$groupId/bracelets';
}
