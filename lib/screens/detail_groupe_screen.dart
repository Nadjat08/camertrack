import 'package:flutter/material.dart';
import '../services/groupes_service.dart';
import '../services/bracelets_service.dart';
import 'scan_bracelet_screen.dart';

class DetailGroupeScreen extends StatefulWidget {
  final int groupId;
  final String nomGroupe;

  const DetailGroupeScreen({
    super.key,
    required this.groupId,
    required this.nomGroupe,
  });

  @override
  State<DetailGroupeScreen> createState() => _DetailGroupeScreenState();
}

class _DetailGroupeScreenState extends State<DetailGroupeScreen> {
  Map<String, dynamic>? _detail;
  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    _chargerDetail();
  }

  Future<void> _chargerDetail() async {
    setState(() => _chargement = true);
    final detail = await GroupesService.getDetailGroupe(widget.groupId);
    if (mounted) {
      setState(() {
        _detail = detail;
        _chargement = false;
      });
    }
  }

  Future<void> _afficherInviter() async {
    final controller = TextEditingController();
    bool parTelephone = true;
    List<Map<String, dynamic>> resultats = [];
    bool recherche = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Inviter un membre',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 16),

              // Toggle téléphone / nom
              Row(
                children: [
                  _buildToggle('Téléphone', parTelephone, () {
                    setModalState(() {
                      parTelephone = true;
                      resultats = [];
                      controller.clear();
                    });
                  }),
                  const SizedBox(width: 8),
                  _buildToggle('Nom', !parTelephone, () {
                    setModalState(() {
                      parTelephone = false;
                      resultats = [];
                      controller.clear();
                    });
                  }),
                ],
              ),
              const SizedBox(height: 16),

              // Champ de recherche
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      keyboardType: parTelephone
                          ? TextInputType.phone
                          : TextInputType.text,
                      decoration: InputDecoration(
                        labelText: parTelephone
                            ? 'Numéro de téléphone'
                            : 'Nom ou prénom',
                        prefixIcon: Icon(parTelephone
                            ? Icons.phone
                            : Icons.person_search),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      if (controller.text.trim().isEmpty) return;
                      setModalState(() => recherche = true);
                      final res = await GroupesService.rechercherUtilisateur(
                        controller.text.trim(),
                        parTelephone,
                      );
                      setModalState(() {
                        resultats = res;
                        recherche = false;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(60, 52),
                      padding: EdgeInsets.zero,
                    ),
                    child: recherche
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : const Icon(Icons.search),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Résultats
              if (resultats.isEmpty && !recherche)
                const Center(
                  child: Text(
                    'Aucun utilisateur trouvé',
                    style: TextStyle(
                      color: Color(0xFF757575),
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),

              ...resultats.map((user) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF1A73E8),
                  child: Text(
                    user['prenom'][0].toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(
                  '${user['prenom']} ${user['nom']}',
                  style: const TextStyle(fontFamily: 'Poppins'),
                ),
                subtitle: Text(
                  user['telephone'],
                  style: const TextStyle(fontFamily: 'Poppins'),
                ),
                trailing: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    final result = await GroupesService.envoyerInvitation(
                      widget.groupId,
                      user['telephone'],
                    );
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result['message']),
                        backgroundColor: result['success']
                            ? const Color(0xFF34A853)
                            : const Color(0xFFEA4335),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                  ),
                  child: const Text('Inviter'),
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  // Bottom sheet "Ajouter un bracelet" : scan du QR affiché sur la montre
  // + profil de l'enfant, puis appel à BraceletsService.ajouterBracelet.
  Future<void> _afficherAjouterBracelet() async {
    final prenomController = TextEditingController();
    final nomController = TextEditingController();
    DateTime? dateNaissance;
    String? identifiantScanne;
    bool envoi = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ajouter un bracelet',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 16),

              // Bouton de scan du QR code
              InkWell(
                onTap: () async {
                  final code = await Navigator.push<String>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ScanBraceletScreen(),
                    ),
                  );
                  if (code != null) {
                    setModalState(() => identifiantScanne = code);
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: identifiantScanne != null
                        ? const Color(0xFF34A853).withOpacity(0.1)
                        : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: identifiantScanne != null
                          ? const Color(0xFF34A853)
                          : const Color(0xFFE0E0E0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        identifiantScanne != null
                            ? Icons.check_circle
                            : Icons.qr_code_scanner,
                        color: identifiantScanne != null
                            ? const Color(0xFF34A853)
                            : const Color(0xFF1A73E8),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          identifiantScanne != null
                              ? 'Bracelet scanné : $identifiantScanne'
                              : 'Scanner le QR code du bracelet',
                          style: const TextStyle(fontFamily: 'Poppins'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: prenomController,
                decoration: const InputDecoration(
                  labelText: 'Prénom de l\'enfant',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nomController,
                decoration: const InputDecoration(
                  labelText: 'Nom de l\'enfant',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),

              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime(2015, 1, 1),
                    firstDate: DateTime(2005, 1, 1),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setModalState(() => dateNaissance = date);
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date de naissance',
                    prefixIcon: Icon(Icons.cake_outlined),
                  ),
                  child: Text(
                    dateNaissance != null
                        ? '${dateNaissance!.day.toString().padLeft(2, '0')}/'
                        '${dateNaissance!.month.toString().padLeft(2, '0')}/'
                        '${dateNaissance!.year}'
                        : 'Sélectionner une date',
                    style: const TextStyle(fontFamily: 'Poppins'),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: envoi
                      ? null
                      : () async {
                    if (identifiantScanne == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Veuillez scanner le QR code du bracelet.'),
                        ),
                      );
                      return;
                    }
                    if (prenomController.text.trim().isEmpty ||
                        nomController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Nom et prénom obligatoires.'),
                        ),
                      );
                      return;
                    }

                    setModalState(() => envoi = true);

                    final result = await BraceletsService.ajouterBracelet(
                      groupId: widget.groupId,
                      identifiantUnique: identifiantScanne!,
                      nomEnfant: nomController.text.trim(),
                      prenomEnfant: prenomController.text.trim(),
                      dateNaissance: dateNaissance != null
                          ? '${dateNaissance!.year}-'
                          '${dateNaissance!.month.toString().padLeft(2, '0')}-'
                          '${dateNaissance!.day.toString().padLeft(2, '0')}'
                          : null,
                    );

                    setModalState(() => envoi = false);

                    if (!context.mounted) return;
                    Navigator.pop(context);

                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result['message'] ?? ''),
                        backgroundColor: result['success'] == true
                            ? const Color(0xFF34A853)
                            : const Color(0xFFEA4335),
                      ),
                    );

                    if (result['success'] == true) {
                      _chargerDetail();
                    }
                  },
                  child: envoi
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Text('Ajouter le bracelet'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggle(String label, bool actif, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: actif ? const Color(0xFF1A73E8) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: actif ? Colors.white : const Color(0xFF757575),
            fontFamily: 'Poppins',
            fontWeight: actif ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
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
        title: Text(
          widget.nomGroupe,
          style: const TextStyle(
            color: Color(0xFF212121),
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.watch, color: Color(0xFF1A73E8)),
            onPressed: _afficherAjouterBracelet,
            tooltip: 'Ajouter un bracelet',
          ),
          IconButton(
            icon: const Icon(Icons.person_add, color: Color(0xFF1A73E8)),
            onPressed: _afficherInviter,
            tooltip: 'Inviter un membre',
          ),
        ],
      ),
      body: _chargement
          ? const Center(child: CircularProgressIndicator())
          : _detail == null
          ? const Center(child: Text('Erreur de chargement'))
          : RefreshIndicator(
        onRefresh: _chargerDetail,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Carte infos groupe
            Container(
              padding: const EdgeInsets.all(20),
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
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A73E8).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.group,
                      color: Color(0xFF1A73E8),
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.nomGroupe,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      Text(
                        '${(_detail!['membres'] as List).length} membres',
                        style: const TextStyle(
                          color: Color(0xFF757575),
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Titre membres
            const Text(
              'Membres',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
                color: Color(0xFF212121),
              ),
            ),
            const SizedBox(height: 12),

            // Liste des membres
            ...(_detail!['membres'] as List).map((membre) =>
                _buildCarteMembre(membre)),
          ],
        ),
      ),
    );
  }

  Widget _buildCarteMembre(Map<String, dynamic> membre) {
    final estAdmin = membre['role'] == 'admin';
    // Un bracelet (role 'enfant') n'a ni téléphone ni, parfois, nom/prénom complets :
    // on sécurise l'accès pour éviter un crash "Null is not a subtype of String".
    final prenom = (membre['prenom'] ?? '').toString();
    final nom = (membre['nom'] ?? '').toString();
    final initiales =
        '${prenom.isNotEmpty ? prenom[0] : ''}${nom.isNotEmpty ? nom[0] : ''}'
            .toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: estAdmin
                ? const Color(0xFF1A73E8)
                : const Color(0xFF34A853),
            child: Text(
              initiales,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${membre['prenom']} ${membre['nom']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                    fontSize: 15,
                  ),
                ),
                Text(
                  membre['telephone'] ?? (membre['role'] == 'enfant' ? 'Bracelet enfant' : ''),
                  style: const TextStyle(
                    color: Color(0xFF757575),
                    fontFamily: 'Poppins',
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (estAdmin)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
    );
  }

}