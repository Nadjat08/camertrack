// Import du package Flutter de base (widgets, Material Design)
import 'package:flutter/material.dart';

// Import pour lire les données sauvegardées localement sur l'appareil
// (token JWT, onboarding_done)
import 'package:shared_preferences/shared_preferences.dart';

// SplashScreen est un StatefulWidget car il gère des animations
// qui changent d'état au fil du temps
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  // Crée l'objet State qui va gérer les animations et la logique
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

// "with SingleTickerProviderStateMixin" est obligatoire pour utiliser
// un AnimationController. Il fournit le "ticker" — une horloge interne
// qui cadence les animations frame par frame (60 fps)
class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {

  // Le chef d'orchestre des animations : contrôle la durée,
  // le démarrage, l'arrêt et la progression
  late AnimationController _controller;

  // Animation qui fait apparaître progressivement le contenu
  // (opacité de 0.0 = invisible à 1.0 = visible)
  late Animation<double> _fadeAnimation;

  // Animation qui fait grossir progressivement le contenu
  // (échelle de 0.8 = 80% de la taille à 1.0 = taille normale)
  late Animation<double> _scaleAnimation;

  // "late" signifie que ces variables seront initialisées plus tard
  // (dans initState) et non pas au moment de la déclaration

  // initState est appelé UNE SEULE FOIS à la création de l'écran
  // C'est ici qu'on initialise tout ce qui doit être prêt avant l'affichage
  @override
  void initState() {
    super.initState(); // Toujours appeler en premier

    // ── CONFIGURATION DE L'ANIMATION CONTROLLER ──────────────────
    _controller = AnimationController(
      vsync: this,  // "this" = le ticker fourni par SingleTickerProviderStateMixin
      // vsync synchronise l'animation avec le rafraîchissement écran
      // et économise la batterie quand l'écran n'est pas visible
      duration: const Duration(milliseconds: 1500), // Durée totale : 1.5 secondes
    );

    // ── CONFIGURATION DE L'ANIMATION DE FONDU (FADE) ─────────────
    _fadeAnimation = Tween<double>(
      begin: 0.0, // Commence invisible
      end: 1.0,   // Termine complètement visible
    ).animate(
      CurvedAnimation(
        parent: _controller,     // Piloté par notre AnimationController
        curve: Curves.easeIn,    // Démarre lentement puis accélère
        // (effet d'apparition naturel)
      ),
    );

    // ── CONFIGURATION DE L'ANIMATION DE ZOOM (SCALE) ─────────────
    _scaleAnimation = Tween<double>(
      begin: 0.8, // Commence à 80% de la taille normale
      end: 1.0,   // Termine à 100% (taille normale)
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack, // Dépasse légèrement la taille finale
        // puis revient (effet de "rebond" subtil)
      ),
    );

    // Lance les deux animations simultanément
    // (elles partagent le même _controller donc démarrent ensemble)
    _controller.forward();

    // ── REDIRECTION APRÈS 2.5 SECONDES ───────────────────────────
    // Future.delayed attend 2.5s puis appelle _redirect()
    // Sans bloquer l'interface (l'animation continue pendant ce délai)
    Future.delayed(const Duration(milliseconds: 2500), () {
      _redirect();
    });
  }

  // Fonction qui décide vers quel écran rediriger l'utilisateur
  // après le splash screen
  Future<void> _redirect() async {

    // Ouvre le fichier de configuration local de l'app
    final prefs = await SharedPreferences.getInstance();

    // Récupère le token JWT sauvegardé lors de la dernière connexion
    // Retourne null si l'utilisateur n'est pas connecté
    final token = prefs.getString('token');

    // Récupère si l'onboarding a déjà été vu
    // ?? false signifie : si la valeur n'existe pas, utilise false par défaut
    final onboardingDone = prefs.getBool('onboarding_done') ?? false;

    // Vérifie que l'écran est toujours affiché avant de naviguer
    // (évite un crash si l'utilisateur a quitté pendant le await)
    if (!mounted) return;

    // ── LOGIQUE DE REDIRECTION ────────────────────────────────────
    if (token != null) {
      // Token présent = utilisateur déjà connecté
      // → On l'envoie directement à l'accueil
      Navigator.pushReplacementNamed(context, '/home');

    } else if (!onboardingDone) {
      // Pas de token ET onboarding pas encore vu
      // = première ouverture de l'app
      // → On affiche l'onboarding
      Navigator.pushReplacementNamed(context, '/onboarding');

    } else {
      // Pas de token MAIS onboarding déjà vu
      // = utilisateur connaît l'app mais n'est pas connecté
      // → On affiche le login
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  // Libère la mémoire de l'AnimationController quand l'écran est détruit
  // OBLIGATOIRE pour les AnimationControllers pour éviter les fuites mémoire
  @override
  void dispose() {
    _controller.dispose(); // Libère l'AnimationController et son ticker
    super.dispose();       // Appelle la méthode dispose() du parent
  }

  // Construit l'interface visuelle du splash screen
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fond bleu principal de CamerTrack
      backgroundColor: const Color(0xFF1A73E8),

      body: Center(
        // ── ANIMATION DE FONDU ────────────────────────────────────
        // FadeTransition applique l'animation d'opacité à tout son contenu
        // opacity est liée à _fadeAnimation (0.0 → 1.0)
        child: FadeTransition(
          opacity: _fadeAnimation,

          // ── ANIMATION DE ZOOM ─────────────────────────────────
          // ScaleTransition applique l'animation de taille à tout son contenu
          // scale est liée à _scaleAnimation (0.8 → 1.0)
          // Les deux animations (fade + scale) s'appliquent simultanément
          child: ScaleTransition(
            scale: _scaleAnimation,

            // Column empile le logo, le nom, le slogan et le spinner
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // Centre verticalement
              children: [

                // ── LOGO / ICÔNE ───────────────────────────────────
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white, // Fond blanc pour faire ressortir l'icône bleue
                    borderRadius: BorderRadius.circular(24), // Coins arrondis (carré arrondi)
                    boxShadow: [
                      BoxShadow(
                        // Ombre portée sous le logo
                        color: Colors.black.withOpacity(0.15), // Noir à 15% d'opacité
                        blurRadius: 20,        // Flou de l'ombre (plus = plus doux)
                        offset: const Offset(0, 8), // Décalage : 0 horizontal, 8 vers le bas
                      ),
                    ],
                  ),
                  // Icône de localisation au centre du logo
                  child: const Icon(
                    Icons.location_on,
                    size: 60,
                    color: Color(0xFF1A73E8), // Bleu CamerTrack sur fond blanc
                  ),
                ),

                // Espace de 24 pixels entre le logo et le nom
                const SizedBox(height: 24),

                // ── NOM DE L'APPLICATION ───────────────────────────
                const Text(
                  'CamerTrack',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Poppins',
                    letterSpacing: 1.2, // Espacement entre les lettres
                    // (donne un aspect plus élégant)
                  ),
                ),

                // Espace de 8 pixels entre le nom et le slogan
                const SizedBox(height: 8),

                // ── SLOGAN ─────────────────────────────────────────
                const Text(
                  'Votre famille, toujours proche',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70, // Blanc à 70% d'opacité (légèrement transparent)
                    // pour créer une hiérarchie visuelle avec le nom
                    fontFamily: 'Poppins',
                  ),
                ),

                // Grand espace de 60 pixels pour séparer le texte du spinner
                const SizedBox(height: 60),

                // ── INDICATEUR DE CHARGEMENT ───────────────────────
                // Spinner circulaire blanc qui tourne pendant le chargement
                const CircularProgressIndicator(
                  // AlwaysStoppedAnimation force la couleur blanche
                  // (sans ça le spinner prendrait la couleur primaire du thème)
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2, // Epaisseur du trait de spinner (fin et elegant)
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}