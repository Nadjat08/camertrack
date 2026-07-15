// Import du package Flutter de base (widgets, Material Design)
import 'package:flutter/material.dart';

// Import du package pour les points animés en bas des slides
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

// Import pour sauvegarder des données localement sur l'appareil
import 'package:shared_preferences/shared_preferences.dart';

// OnboardingScreen est un StatefulWidget car l'écran doit se redessiner
// à chaque changement de page (numéro de slide, texte du bouton)
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  // Crée l'objet State qui va gérer les données changeantes de cet écran
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

// La classe State contient toutes les données et la logique de l'écran
class _OnboardingScreenState extends State<OnboardingScreen> {

  // Le "pilote" du PageView : permet de contrôler quelle page est affichée
  // et de naviguer vers la page suivante avec animation
  final PageController _pageController = PageController();

  // Mémorise le numéro de la page actuellement affichée (0, 1 ou 2)
  // Utilisé pour changer le texte du bouton : "Suivant" ou "Commencer"
  int _currentPage = 0;

  // Liste des données de chaque slide
  // Chaque élément est un dictionnaire contenant l'icône, la couleur,
  // le titre et la description du slide correspondant
  final List<Map<String, dynamic>> _slides = [
    {
      // Slide 1 : Géolocalisation
      'icon': Icons.location_on,
      'color': const Color(0xFF1A73E8), // Bleu principal CamerTrack
      'title': 'Suivez votre famille\nen temps réel', // \n = retour à la ligne
      'description':
      'Visualisez la position de tous vos proches sur une carte interactive, où que vous soyez au Cameroun.',
    },
    {
      // Slide 2 : Bracelet connecté
      'icon': Icons.watch,
      'color': const Color(0xFF34A853), // Vert : sécurité, "tout va bien"
      'title': 'Protégez vos enfants\navec le bracelet',
      'description':
      'Nos bracelets connectés permettent de suivre vos enfants même sans smartphone, avec alerte SOS intégrée.',
    },
    {
      // Slide 3 : Alertes
      'icon': Icons.notifications_active,
      'color': const Color(0xFFEA4335), // Rouge : danger, urgence
      'title': 'Alertes instantanées\nen cas de danger',
      'description':
      'Recevez une notification immédiate si votre enfant sort d\'une zone de sécurité ou déclenche le SOS.',
    },
  ];

  // Fonction appelée quand l'utilisateur appuie sur "Passer" ou "Commencer"
  // Future<void> car elle fait des opérations asynchrones (écriture sur disque)
  Future<void> _terminerOnboarding() async {

    // Ouvre le fichier de configuration local de l'app
    // await = attend que l'opération soit terminée avant de continuer
    final prefs = await SharedPreferences.getInstance();

    // Sauvegarde onboarding_done = true sur l'appareil
    // Le SplashScreen vérifiera cette valeur au prochain démarrage
    // pour ne plus afficher l'onboarding
    await prefs.setBool('onboarding_done', true);

    // Vérifie que l'écran est toujours affiché avant de naviguer
    // (évite un crash si l'utilisateur a quitté l'écran pendant le await)
    if (!mounted) return;

    // Navigue vers le questionnaire en REMPLAÇANT l'écran actuel
    // (pushReplacement = pas de retour en arrière possible)
    Navigator.pushReplacementNamed(context, '/questionnaire');
  }

  // Libère la mémoire utilisée par le PageController quand l'écran est détruit
  // Bonne pratique obligatoire pour éviter les fuites mémoire
  @override
  void dispose() {
    _pageController.dispose(); // Libère le PageController
    super.dispose();           // Appelle la méthode dispose() du parent
  }

  // Construit l'interface visuelle de l'écran
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Fond blanc

      // SafeArea évite que le contenu se cache derrière
      // la barre de statut ou les coins arrondis de l'écran
      body: SafeArea(

        // Column empile les widgets verticalement de haut en bas
        child: Column(
          children: [

            // ── BOUTON "PASSER"
            // Positionne le bouton en haut à droite de l'écran
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                // 16 pixels d'espace autour du bouton
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  // Appelle _terminerOnboarding pour sauter l'onboarding
                  onPressed: _terminerOnboarding,
                  child: const Text(
                    'Passer',
                    style: TextStyle(
                      color: Color(0xFF757575),  // Gris discret
                      fontFamily: 'Poppins',
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),

            // ── SLIDES (PAGEVIEW)
            // Expanded prend tout l'espace vertical disponible
            // entre le bouton "Passer" et l'indicateur de points
            Expanded(
              child: PageView.builder(
                // Relie le PageView à notre PageController (le pilote)
                controller: _pageController,

                // Nombre total de slides
                itemCount: _slides.length,

                // Appelé automatiquement à chaque changement de page
                onPageChanged: (index) {
                  // setState() redessine l'écran avec le nouveau numéro de page
                  // Ce qui met à jour le texte du bouton ("Suivant"/"Commencer")
                  // et l'indicateur de points
                  setState(() => _currentPage = index);
                },

                // Construit chaque slide selon son index (0, 1 ou 2)
                itemBuilder: (context, index) {

                  // Récupère les données du slide correspondant à l'index
                  final slide = _slides[index];

                  return Padding(
                    // Marges horizontales de 32 pixels
                    padding: const EdgeInsets.symmetric(horizontal: 32),

                    // Centre le contenu verticalement dans le slide
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [

                        // ── ICÔNE DANS UN CERCLE
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            // Couleur du slide à 10% d'opacité (très transparent)
                            // pour créer un fond cercle subtil
                            color: (slide['color'] as Color).withOpacity(0.1),
                            shape: BoxShape.circle, // Forme circulaire
                          ),
                          // L'icône au centre du cercle
                          // "as IconData" et "as Color" précisent le type
                          // car le dictionnaire utilise dynamic
                          child: Icon(
                            slide['icon'] as IconData,
                            size: 70,
                            color: slide['color'] as Color,
                          ),
                        ),

                        // Espace de 48 pixels entre l'icône et le titre
                        const SizedBox(height: 48),

                        // ── TITRE DU SLIDE
                        Text(
                          slide['title'] as String,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF212121), // Gris très foncé
                            fontFamily: 'Poppins',
                            height: 1.3, // Interligne : 1.3 × la taille de police
                          ),
                        ),

                        // Espace de 16 pixels entre le titre et la description
                        const SizedBox(height: 16),

                        // ── DESCRIPTION DU SLIDE
                        Text(
                          slide['description'] as String,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF757575), // Gris moyen
                            fontFamily: 'Poppins',
                            height: 1.6, // Interligne généreux pour la lisibilité
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // ── INDICATEUR DE POINTS
            // Affiche 3 points animés synchronisés avec le PageView
            SmoothPageIndicator(
              // Synchronisé avec le PageView via le même PageController
              controller: _pageController,
              count: _slides.length, // 3 points

              // ExpandingDotsEffect : le point actif s'étire horizontalement
              effect: ExpandingDotsEffect(
                activeDotColor: const Color(0xFF1A73E8), // Bleu pour le point actif
                dotColor: const Color(0xFFE0E0E0),       // Gris pour les points inactifs
                dotHeight: 8,
                dotWidth: 8,
                expansionFactor: 3, // Le point actif est 3x plus large
              ),
            ),

            // Espace de 32 pixels entre les points et le bouton
            const SizedBox(height: 32),

            // ── BOUTON SUIVANT / COMMENCER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: ElevatedButton(
                onPressed: () {
                  // Si on n'est PAS sur le dernier slide
                  if (_currentPage < _slides.length - 1) {
                    // Passe à la page suivante avec une animation de 300ms
                    // easeInOut = démarre doucement, accélère, puis ralentit
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  } else {
                    // On est sur le dernier slide → termine l'onboarding
                    _terminerOnboarding();
                  }
                },

                // Opérateur ternaire : affiche "Suivant" ou "Commencer"
                // selon si on est sur le dernier slide ou non
                // condition ? valeur_si_vrai : valeur_si_faux
                child: Text(
                  _currentPage < _slides.length - 1 ? 'Suivant' : 'Commencer',
                ),
              ),
            ),

            // Espace de 32 pixels en bas du bouton
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}