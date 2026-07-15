import 'package:flutter/material.dart';
import '../services/groupes_service.dart';
import 'detail_groupe_screen.dart';


class GroupesScreen extends StatefulWidget {
  const GroupesScreen({super.key});

  @override
  State<GroupesScreen> createState() => _GroupesScreenState();
}

class _GroupesScreenState extends State<GroupesScreen> {
  List<Map<String, dynamic>> _groupes = [];
  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    _chargerGroupes();
  }

  Future<void> _chargerGroupes() async {
    setState(() => _chargement = true);

    final groupes = await GroupesService.getGroupes();

    if (mounted) {
      setState(() {
        _groupes = groupes;
        _chargement = false;
      });
    }
  }

  Future<void> _afficherCreerGroupe() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Créer un groupe',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nom du groupe',
            hintText: 'Ex : Famille HAMAN',
            prefixIcon: Icon(Icons.group),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            style: ElevatedButton.styleFrom(
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text('Créer'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final response = await GroupesService.creerGroupe(result);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message']),
          backgroundColor: response['success']
              ? const Color(0xFF34A853)
              : const Color(0xFFEA4335),
        ),
      );

      if (response['success']) {
        _chargerGroupes();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Mes groupes',
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
            onPressed: _chargerGroupes,
          ),
        ],
      ),
      body: _chargement
          ? const Center(child: CircularProgressIndicator())
          : _groupes.isEmpty
          ? _buildEtatVide()
          : RefreshIndicator(
        onRefresh: _chargerGroupes,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _groupes.length,
          itemBuilder: (context, index) {
            return _buildCarteGroupe(_groupes[index]);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _afficherCreerGroupe,
        backgroundColor: const Color(0xFF1A73E8),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Nouveau groupe',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildEtatVide() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF1A73E8).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.group_add,
              size: 50,
              color: Color(0xFF1A73E8),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Aucun groupe pour l\'instant',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
              color: Color(0xFF212121),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Créez votre premier groupe\npour commencer à partager vos positions.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF757575),
              fontFamily: 'Poppins',
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _afficherCreerGroupe,
            icon: const Icon(Icons.add),
            label: const Text('Créer un groupe'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(200, 48),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarteGroupe(Map<String, dynamic> groupe) {
    final estAdmin = groupe['role'] == 'admin';
    final nombreMembres = int.tryParse(groupe['nombre_membres'].toString()) ?? 1;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailGroupeScreen(
              groupId: groupe['group_id'],
              nomGroupe: groupe['nom_grp'],
            ),
          ),
        ).then((_) => _chargerGroupes());
      },
      child: Container(
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
        child: Row(
          children: [
            // Icône du groupe
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF1A73E8).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.group,
                color: Color(0xFF1A73E8),
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            // Infos du groupe
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    groupe['nom_grp'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                      color: Color(0xFF212121),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.people, size: 14, color: Color(0xFF757575)),
                      const SizedBox(width: 4),
                      Text(
                        '$nombreMembres membre${nombreMembres > 1 ? 's' : ''}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF757575),
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (estAdmin)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A73E8).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Admin',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF1A73E8),
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF757575)),
          ],
        ),
      ),
    );
  }
}