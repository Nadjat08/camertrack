class MembrePosition {
  final int userId;
  final String nom;
  final String prenom;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final String role;
  final int groupId;
  final String nomGroupe;
  final bool enLigne;

  MembrePosition({
    required this.userId,
    required this.nom,
    required this.prenom,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.role,
    required this.groupId,
    required this.nomGroupe,
    required this.enLigne,
  });

  // Initiales pour le marqueur sur la carte
  String get initiales {
    final p = prenom.isNotEmpty ? prenom[0].toUpperCase() : '';
    final n = nom.isNotEmpty ? nom[0].toUpperCase() : '';
    return '$p$n';
  }

  factory MembrePosition.fromJson(Map<String, dynamic> json) {
    return MembrePosition(
      userId: json['user_id'],
      nom: json['nom'],
      prenom: json['prenom'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
      role: json['role'] ?? 'membre',
      groupId: json['group_id'],
      nomGroupe: json['nom_grp'] ?? '',
      enLigne: json['en_ligne'] ?? false,
    );
  }
}