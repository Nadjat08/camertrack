import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../models/membre_position.dart';
import '../services/position_service.dart';
import '../services/socket_service.dart';
import '../services/groupes_service.dart';
import 'groupes_screen.dart';
import 'invitations_screen.dart';
import 'profil_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MapController _mapController = MapController();

  Position? _maPosition;
  List<MembrePosition> _membres = [];
  List<String> _groupes = [];
  String _filtreGroupe = 'Tous';
  bool _chargement = true;
  Timer? _timerPosition;
  Timer? _timerMembres;

  final List<Color> _couleursGroupes = [
    const Color(0xFF1A73E8),
    const Color(0xFF34A853),
    const Color(0xFFEA4335),
    const Color(0xFFFBBC04),
    const Color(0xFF9C27B0),
  ];

  @override
  void initState() {
    super.initState();
    _initialiser();
  }

  Future<void> _initialiser() async {
    // 1. Obtenir ma position GPS
    await _obtenirMaPosition();

    // 2. Charger les membres
    await _chargerMembres();

    // 3. Connecter Socket.io
    final groupeIds = await GroupesService.getGroupeIds();
    await SocketService.connecter(groupeIds);

    // 4. Écouter les mises à jour temps réel
    // Écouter les mises à jour temps réel
    SocketService.ecouterPositions((data) {
      if (!mounted) return;
      setState(() {
        // Mettre à jour ou ajouter le membre dans la liste
        final index = _membres.indexWhere((m) => m.userId == data['user_id']);

        final membreMAJ = MembrePosition(
          userId: data['user_id'],
          nom: data['nom'],
          prenom: data['prenom'],
          latitude: (data['latitude'] as num).toDouble(),
          longitude: (data['longitude'] as num).toDouble(),
          timestamp: DateTime.parse(data['timestamp']),
          role: data['role'] ?? 'membre',
          groupId: data['group_id'],
          nomGroupe:
              _membres.isNotEmpty && index >= 0
                  ? _membres[index].nomGroupe
                  : '',
          enLigne: true,
        );

        if (index >= 0) {
          _membres[index] = membreMAJ;
        } else {
          _membres.add(membreMAJ);
        }
      });
      _ajusterVue();
    });

    SocketService.ecouterSos((data) {
      if (!mounted) return;
      final braceletId = data['bracelet_id'];
      final latitude = data['latitude'];
      final longitude = data['longitude'];
      final severity = data['severity'] ?? 'HIGH';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '🚨 SOS $severity déclenché par le bracelet $braceletId à $latitude,$longitude',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 8),
        ),
      );

      _ajusterVue();
    });

    // 5. Envoyer ma position toutes les 30 secondes
    _timerPosition = Timer.periodic(const Duration(seconds: 30), (_) {
      _envoyerMaPosition();
    });

    // 6. Rafraîchir les membres toutes les 30 secondes (fallback HTTP)
    _timerMembres = Timer.periodic(const Duration(seconds: 30), (_) {
      _chargerMembres();
    });
  }

  Future<void> _obtenirMaPosition() async {
    final position = await PositionService.obtenirPosition();
    if (position != null && mounted) {
      setState(() {
        _maPosition = position;
        _chargement = false;
      });
      try {
        _mapController.move(
          LatLng(position.latitude, position.longitude),
          15.0,
        );
      } catch (_) {}

      await PositionService.envoyerPosition(
        position.latitude,
        position.longitude,
      );
    } else {
      setState(() => _chargement = false);
    }
  }

  Future<void> _envoyerMaPosition() async {
    final position = await PositionService.obtenirPosition();
    if (position != null && mounted) {
      await PositionService.envoyerPosition(
        position.latitude,
        position.longitude,
      );
      setState(() => _maPosition = position);
    }
  }

  Future<void> _chargerMembres() async {
    final membres = await PositionService.getPositionsMembres();
    if (mounted) {
      setState(() {
        _membres = membres;
        final groupesSet = membres.map((m) => m.nomGroupe).toSet().toList();
        _groupes = groupesSet;
      });
      _ajusterVue();
    }
  }

  void _ajusterVue() {
    final points = <LatLng>[
      if (_maPosition != null)
        LatLng(_maPosition!.latitude, _maPosition!.longitude),
      ..._membresFiltres.map((m) => LatLng(m.latitude, m.longitude)),
    ];

    if (points.isEmpty) return;

    try {
      if (points.length == 1) {
        _mapController.move(points.first, 15.0);
      } else {
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: LatLngBounds.fromPoints(points),
            padding: const EdgeInsets.all(70),
            maxZoom: 16,
          ),
        );
      }
    } catch (_) {
      // ignore: avoid_print
      print('Unable to adjust camera view');
    }
  }

  Color _couleurPourGroupe(String nomGroupe) {
    final index = _groupes.indexOf(nomGroupe) % _couleursGroupes.length;
    return _couleursGroupes[index < 0 ? 0 : index];
  }

  List<MembrePosition> get _membresFiltres {
    if (_filtreGroupe == 'Tous') return _membres;
    return _membres.where((m) => m.nomGroupe == _filtreGroupe).toList();
  }

  @override
  void dispose() {
    _timerPosition?.cancel();
    _timerMembres?.cancel();
    SocketService.deconnecter();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // CARTE
          _chargement
              ? const Center(child: CircularProgressIndicator())
              : FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter:
                      _maPosition != null
                          ? LatLng(
                            _maPosition!.latitude,
                            _maPosition!.longitude,
                          )
                          : const LatLng(3.848, 11.502),
                  initialZoom: 15.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.camertrack',
                  ),
                  if (_maPosition != null)
                    PolylineLayer(
                      polylines:
                          _membresFiltres
                              .where((m) => m.role == 'enfant')
                              .map(
                                (m) => Polyline(
                                  points: [
                                    LatLng(
                                      _maPosition!.latitude,
                                      _maPosition!.longitude,
                                    ),
                                    LatLng(m.latitude, m.longitude),
                                  ],
                                  isDotted: true,
                                  color: const Color(0xFF1A73E8),
                                  strokeWidth: 3,
                                ),
                              )
                              .toList(),
                    ),
                  MarkerLayer(
                    markers: [
                      if (_maPosition != null)
                        Marker(
                          point: LatLng(
                            _maPosition!.latitude,
                            _maPosition!.longitude,
                          ),
                          width: 60,
                          height: 70,
                          child: _buildMarkerMoi(),
                        ),
                      ..._membresFiltres.map(
                        (membre) => Marker(
                          point: LatLng(membre.latitude, membre.longitude),
                          width: 70,
                          height: 80,
                          child: _buildMarkerMembre(membre),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

          // FILTRE PAR GROUPE
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 0,
            right: 0,
            child: _buildFiltreGroupes(),
          ),

          // BOUTON CENTRER
          Positioned(
            bottom: 100,
            right: 16,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white,
              onPressed: () {
                if (_maPosition != null) {
                  _mapController.move(
                    LatLng(_maPosition!.latitude, _maPosition!.longitude),
                    15.0,
                  );
                }
              },
              child: const Icon(Icons.my_location, color: Color(0xFF1A73E8)),
            ),
          ),

          // BARRE DU BAS
          Positioned(bottom: 0, left: 0, right: 0, child: _buildBarreBas()),
        ],
      ),
    );
  }

  Widget _buildMarkerMoi() {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF1A73E8),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(51),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(Icons.person, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF1A73E8),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'Moi',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMarkerMembre(MembrePosition membre) {
    final estBracelet = membre.role == 'enfant';
    final couleur =
        !membre.enLigne
            ? Colors.grey
            : (estBracelet
                ? const Color(0xFFFBBC04)
                : _couleurPourGroupe(membre.nomGroupe));

    return GestureDetector(
      onTap: () => _afficherInfoMembre(membre),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: couleur,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(51),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child:
                  estBracelet
                      ? const Icon(Icons.watch, color: Colors.white, size: 22)
                      : Text(
                        membre.initiales,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
            ),
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: couleur,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              membre.prenom,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _afficherInfoMembre(MembrePosition membre) {
    final couleur = _couleurPourGroupe(membre.nomGroupe);
    final diff = DateTime.now().difference(membre.timestamp);
    final derniereMaj =
        diff.inMinutes < 1
            ? 'À l\'instant'
            : diff.inMinutes < 60
            ? 'Il y a ${diff.inMinutes} min'
            : 'Il y a ${diff.inHours}h';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: couleur,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      membre.initiales,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${membre.prenom} ${membre.nom}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  membre.nomGroupe,
                  style: TextStyle(
                    fontSize: 14,
                    color: couleur,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      membre.enLigne ? Icons.circle : Icons.circle_outlined,
                      size: 12,
                      color: membre.enLigne ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      membre.enLigne ? 'En ligne' : 'Hors ligne',
                      style: TextStyle(
                        color: membre.enLigne ? Colors.green : Colors.grey,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.access_time, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      derniereMaj,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _mapController.move(
                      LatLng(membre.latitude, membre.longitude),
                      17.0,
                    );
                  },
                  icon: const Icon(Icons.center_focus_strong),
                  label: const Text('Centrer sur cette personne'),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildFiltreGroupes() {
    final tous = ['Tous', ..._groupes];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children:
            tous.map((groupe) {
              final selectionne = _filtreGroupe == groupe;
              final couleur =
                  groupe == 'Tous'
                      ? const Color(0xFF1A73E8)
                      : _couleurPourGroupe(groupe);
              return GestureDetector(
                onTap: () => setState(() => _filtreGroupe = groupe),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: selectionne ? couleur : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(26),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    groupe,
                    style: TextStyle(
                      color: selectionne ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildBarreBas() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.map, 'Carte', true, null),
          _buildNavItem(Icons.group, 'Groupes', false, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const GroupesScreen()),
            );
          }),
          _buildNavItem(Icons.notifications, 'Alertes', false, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const InvitationsScreen(),
              ),
            );
          }),
          _buildNavItem(Icons.person, 'Profil', false, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfilScreen()),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    bool actif,
    VoidCallback? onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: actif ? const Color(0xFF1A73E8) : Colors.grey,
            size: 26,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: actif ? const Color(0xFF1A73E8) : Colors.grey,
              fontFamily: 'Poppins',
              fontWeight: actif ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
