import 'dart:convert';
import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../services/http_client.dart';

class InvitationsScreen extends StatefulWidget {
  const InvitationsScreen({super.key});

  @override
  State<InvitationsScreen> createState() => _InvitationsScreenState();
}

class _InvitationsScreenState extends State<InvitationsScreen> {
  List<Map<String, dynamic>> _invitations = [];
  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    _chargerInvitations();
  }

  Future<void> _chargerInvitations() async {
    setState(() => _chargement = true);
    try {
      final response = await HttpClient.get(ApiConfig.invitations);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _invitations = List<Map<String, dynamic>>.from(
            data['invitations'],
          );
          _chargement = false;
        });
      } else {
        setState(() => _chargement = false);
      }
    } catch (e) {
      setState(() => _chargement = false);
    }
  }


  Future<void> _repondreInvitation(int invitId, bool accepter) async {
    try {
      final action = accepter ? 'accepter' : 'refuser';
      final response = await HttpClient.put(
        '${ApiConfig.invitations}/$invitId/$action',
      );

      final data = jsonDecode(response.body);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(data['message']),
          backgroundColor: accepter
              ? const Color(0xFF34A853)
              : const Color(0xFF757575),
        ),
      );

      _chargerInvitations();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur de connexion.')),
      );
    }
  }

  Color _couleurStatut(String statut) {
    switch (statut) {
      case 'en_attente':
        return const Color(0xFFFBBC04);
      case 'acceptee':
        return const Color(0xFF34A853);
      case 'refusee':
        return const Color(0xFFEA4335);
      case 'expiree':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _libelleStatut(String statut) {
    switch (statut) {
      case 'en_attente':
        return 'En attente';
      case 'acceptee':
        return 'Acceptée';
      case 'refusee':
        return 'Refusée';
      case 'expiree':
        return 'Expirée';
      default:
        return statut;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF212121)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Color(0xFF212121),
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF1A73E8)),
            onPressed: _chargerInvitations,
          ),
        ],
      ),
      body: _chargement
          ? const Center(child: CircularProgressIndicator())
          : _invitations.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF1A73E8).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mail_outline,
                size: 40,
                color: Color(0xFF1A73E8),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucune invitation',
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'Poppins',
                color: Color(0xFF757575),
              ),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _chargerInvitations,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _invitations.length,
          itemBuilder: (context, index) {
            return _buildCarteInvitation(_invitations[index]);
          },
        ),
      ),
    );
  }

  Widget _buildCarteInvitation(Map<String, dynamic> invitation) {
    final statut = invitation['statut'];
    final enAttente = statut == 'en_attente';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A73E8).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.group,
                  color: Color(0xFF1A73E8),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invitation['nom_grp'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    Text(
                      'Invité par ${invitation['inviteur_prenom']} ${invitation['inviteur_nom']}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF757575),
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _couleurStatut(statut).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _libelleStatut(statut),
                  style: TextStyle(
                    fontSize: 11,
                    color: _couleurStatut(statut),
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),

          // Boutons si en attente
          if (enAttente) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _repondreInvitation(
                        invitation['id_invit'], false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEA4335),
                      side: const BorderSide(color: Color(0xFFEA4335)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Refuser',
                      style: TextStyle(fontFamily: 'Poppins'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _repondreInvitation(
                        invitation['id_invit'], true),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 44),
                    ),
                    child: const Text(
                      'Accepter',
                      style: TextStyle(fontFamily: 'Poppins'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}