// Import du package Flutter de base (widgets, Material Design)
import 'package:flutter/material.dart';

// Import pour sauvegarder les réponses localement sur l'appareil
import 'package:shared_preferences/shared_preferences.dart';

// QuestionnaireScreen est un StatefulWidget car les réponses sélectionnées
// changent l'apparence des options (couleur, bordure, icône de validation)
class QuestionnaireScreen extends StatefulWidget {
  const QuestionnaireScreen({super.key});

  @override
  State<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {

  // Mémorise l'index de la réponse sélectionnée pour la question 1
  // int? = peut être null (aucune réponse sélectionnée au départ)
  int? _sourceReponse;

  // Mémorise l'index de la réponse sélectionnée pour la question 2
  // int? = peut être null (aucune réponse sélectionnée au départ)
  int? _usageReponse;

  // Indique si le bouton "Continuer" est en cours de chargement
  // true = affiche un spinner, false = affiche le texte "Continuer"
  bool _loading = false;

  // ── DONNÉES DE LA QUESTION 1 ────────────────────────────────────
  // Liste des options pour "Comment avez-vous connu CamerTrack ?"
  // Chaque option a une icône et un label
  final List<Map<String, dynamic>> _sources = [
    {'icon': Icons.tiktok,   'label': 'TikTok'},
    {'icon': Icons.facebook, 'label': 'Facebook'},
    {'icon': Icons.people,   'label': 'Un proche'},
    {'icon': Icons.search,   'label': 'Recherche Google'},
    {'icon': Icons.tv,       'label': 'Télévision / Radio'},
  ];

  // ── DONNÉES DE LA QUESTION 2 ────────────────────────────────────
  // Liste des options pour "Quel est votre usage principal ?"
  final List<Map<String, dynamic>> _usages = [
    {'icon': Icons.child_care,      'label': 'Suivre mes enfants'},
    {'icon': Icons.family_restroom, 'label': 'Suivre ma famille'},
    {'icon': Icons.people_alt,      'label': 'Les deux'},
  ];

  // Fonction appelée quand l'utilisateur appuie sur "Continuer"
  Future<void> _terminer() async {

    // Vérifie que les deux questions ont une réponse
    // Si une réponse manque, affiche un message d'erreur rouge en bas
    if (_sourceReponse == null || _usageReponse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez répondre aux deux questions.'),
          backgroundColor: Color(0xFFEA4335), // Rouge = erreur
        ),
      );
      return; // Arrête la fonction ici, ne continue pas
    }

    // Active le spinner sur le bouton pendant la sauvegarde
    setState(() => _loading = true);

    // Ouvre le fichier de configuration local de l'app
    final prefs = await SharedPreferences.getInstance();

    // Sauvegarde l'index de la réponse à la question 1
    // Ex: si l'utilisateur a choisi "Facebook" (index 1), sauvegarde 1
    await prefs.setInt('source', _sourceReponse!);
    // ! après _sourceReponse signifie "je garantis que ce n'est pas null"
    // (on a déjà vérifié au-dessus qu'il n'est pas null)

    // Sauvegarde l'index de la réponse à la question 2
    await prefs.setInt('usage', _usageReponse!);

    // Vérifie que l'écran est toujours affiché avant de naviguer
    if (!mounted) return;

    // Navigue vers l'écran d'inscription en remplaçant l'écran actuel
    Navigator.pushReplacementNamed(context, '/register');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        // SingleChildScrollView permet de scroller si le contenu
        // dépasse la hauteur de l'écran (important sur petits écrans)
        child: SingleChildScrollView(
          // Marges : 24px horizontalement, 32px verticalement
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),

          child: Column(
            // crossAxisAlignment.start = aligne tout à gauche
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── EN-TÊTE ──────────────────────────────────────────
              const Text(
                'Bienvenue ! 👋',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF212121),
                  fontFamily: 'Poppins',
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Aidez-nous à mieux vous connaître en répondant à ces deux questions rapides.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF757575), // Gris discret
                  fontFamily: 'Poppins',
                  height: 1.5, // Interligne pour la lisibilité
                ),
              ),

              const SizedBox(height: 36),

              // ── QUESTION 1 ───────────────────────────────────────
              const Text(
                'Comment avez-vous connu CamerTrack ?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF212121),
                  fontFamily: 'Poppins',
                ),
              ),

              const SizedBox(height: 16),

              // ".." = opérateur spread : insère tous les éléments
              // de la liste directement dans la Column
              // asMap() transforme la liste en Map {index: valeur}
              // pour avoir accès à l'index de chaque option
              ..._sources.asMap().entries.map((entry) {
                final index = entry.key;    // Numéro de l'option (0, 1, 2...)
                final source = entry.value; // Données de l'option (icon, label)

                // true si cette option est celle sélectionnée par l'utilisateur
                final selected = _sourceReponse == index;

                // GestureDetector détecte le tap sur toute la carte
                return GestureDetector(
                  onTap: () => setState(() => _sourceReponse = index),
                  // setState redessine l'écran avec la nouvelle sélection

                  // AnimatedContainer anime automatiquement les changements
                  // de couleur et de bordure en 200ms (sélection/désélection)
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 10), // Espace entre options
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      // Fond bleu très transparent si sélectionné, gris sinon
                      color: selected
                          ? const Color(0xFF1A73E8).withOpacity(0.08)
                          : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(12),
                      // Bordure bleue si sélectionné, invisible sinon
                      border: Border.all(
                        color: selected
                            ? const Color(0xFF1A73E8)
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),

                    // Row aligne l'icône, le texte et la coche horizontalement
                    child: Row(
                      children: [

                        // Icône de l'option (bleue si sélectionnée, grise sinon)
                        Icon(
                          source['icon'] as IconData,
                          color: selected
                              ? const Color(0xFF1A73E8)
                              : const Color(0xFF757575),
                          size: 22,
                        ),

                        const SizedBox(width: 12), // Espace entre icône et texte

                        // Label de l'option (gras et bleu si sélectionné)
                        Text(
                          source['label'] as String,
                          style: TextStyle(
                            fontSize: 15,
                            fontFamily: 'Poppins',
                            fontWeight: selected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: selected
                                ? const Color(0xFF1A73E8)
                                : const Color(0xFF212121),
                          ),
                        ),

                        // Spacer pousse la coche tout à droite
                        const Spacer(),

                        // Icône de validation : visible UNIQUEMENT si sélectionné
                        // "if (selected)" = affichage conditionnel inline
                        if (selected)
                          const Icon(
                            Icons.check_circle,
                            color: Color(0xFF1A73E8),
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 32),

              // ── QUESTION 2 ───────────────────────────────────────
              // Même logique que la question 1 mais avec :
              // - _usageReponse au lieu de _sourceReponse
              // - Couleur verte (0xFF34A853) au lieu de bleue
              const Text(
                'Quel est votre usage principal ?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF212121),
                  fontFamily: 'Poppins',
                ),
              ),

              const SizedBox(height: 16),

              ..._usages.asMap().entries.map((entry) {
                final index = entry.key;
                final usage = entry.value;

                // true si cette option est celle sélectionnée
                final selected = _usageReponse == index;

                return GestureDetector(
                  // Met à jour _usageReponse avec l'index de l'option tapée
                  onTap: () => setState(() => _usageReponse = index),

                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      // Fond vert très transparent si sélectionné, gris sinon
                      // Question 2 utilise le vert au lieu du bleu
                      color: selected
                          ? const Color(0xFF34A853).withOpacity(0.08)
                          : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(12),
                      // Bordure verte si sélectionné, invisible sinon
                      border: Border.all(
                        color: selected
                            ? const Color(0xFF34A853)
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),

                    child: Row(
                      children: [

                        // Icône verte si sélectionnée, grise sinon
                        Icon(
                          usage['icon'] as IconData,
                          color: selected
                              ? const Color(0xFF34A853)
                              : const Color(0xFF757575),
                          size: 22,
                        ),

                        const SizedBox(width: 12),

                        // Label vert et gras si sélectionné
                        Text(
                          usage['label'] as String,
                          style: TextStyle(
                            fontSize: 15,
                            fontFamily: 'Poppins',
                            fontWeight: selected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: selected
                                ? const Color(0xFF34A853)
                                : const Color(0xFF212121),
                          ),
                        ),

                        const Spacer(),

                        // Coche verte visible uniquement si sélectionné
                        if (selected)
                          const Icon(
                            Icons.check_circle,
                            color: Color(0xFF34A853),
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 40),

              // ── BOUTON CONTINUER ─────────────────────────────────
              ElevatedButton(
                // Si _loading est true → onPressed = null (bouton désactivé)
                // Si _loading est false → onPressed = _terminer (bouton actif)
                // Un bouton avec onPressed = null est automatiquement grisé par Flutter
                onPressed: _loading ? null : _terminer,

                // Si chargement en cours → affiche un spinner blanc
                // Sinon → affiche le texte "Continuer"
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Continuer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}