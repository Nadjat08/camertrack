import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/splash_screen.dart';
import 'screens/Onboarding_screen.dart';
import 'screens/questionnaire_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/groupes_screen.dart';
import 'screens/detail_groupe_screen.dart';
import 'screens/invitations_screen.dart';
import 'services/http_client.dart';
import 'screens/profil_screen.dart';

void main() {
  runApp(const CamerTrackApp());
}

class CamerTrackApp extends StatelessWidget {
  const CamerTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CamerTrack',
      debugShowCheckedModeBanner: false,

      navigatorKey: navigatorKey,

      theme: ThemeData(
        // Couleur principale : Bleu confiance
        primaryColor: const Color(0xFF1A73E8),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A73E8),
          primary: const Color(0xFF1A73E8),
          secondary: const Color(0xFF34A853),
          error: const Color(0xFFEA4335),
          surface: const Color(0xFFF5F5F5),
        ),

        // Typographie Poppins
        fontFamily: 'Poppins',
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF212121),
          ),
          displayMedium: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF212121),
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            color: Color(0xFF212121),
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: Color(0xFF757575),
          ),
        ),

        // Style des boutons principaux
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A73E8),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
        ),

        // Style des champs de saisie
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFF1A73E8),
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFEA4335)),
          ),
        ),

        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      ),

      // Démarrage sur le splash screen
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/questionnaire': (context) => const QuestionnaireScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/groupes':     (context) => const GroupesScreen(),
        '/invitations': (context) => const InvitationsScreen(),
        '/profil': (context) => const ProfilScreen(),
      },
    );
  }
}