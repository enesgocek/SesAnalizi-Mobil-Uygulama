import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'localization_manager.dart';
import 'home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const VokalKocApp());
}

class VokalKocApp extends StatelessWidget {
  const VokalKocApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocalizationManager(),
      builder: (context, child) {
        return MaterialApp(
          title: 'Vokal Koç Studio',
          debugShowCheckedModeBanner: false,
          theme: _buildStudioTheme(),
          home: HomePage(),
        );
      },
    );
  }

  ThemeData _buildStudioTheme() {
    // Studio Pro Color Palette
    const bgDark = Color(0xFF0A0E21); // Deep Blue-Black
    const cardDark = Color(0xFF1D1E33); // Dark Card Color
    // Using a slightly different cyan that pops nicely on dark
    const primaryNeon = Color(0xFF00E5FF); 
    const secondaryNeon = Color(0xFFD500F9); // Neon Purple
    const errorRed = Color(0xFFFF1744); // Neon Red

    var baseTheme = ThemeData.dark();

    return baseTheme.copyWith(
      useMaterial3: true,
      scaffoldBackgroundColor: bgDark,
      colorScheme: const ColorScheme.dark(
        primary: primaryNeon,
        secondary: secondaryNeon,
        surface: cardDark,
        error: errorRed,
        onPrimary: Colors.black,
        onSecondary: Colors.white,
        onSurface: Colors.white,
      ),
      // Typography
      textTheme: GoogleFonts.outfitTextTheme(baseTheme.textTheme).copyWith(
        displayLarge: GoogleFonts.orbitron(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 2.0,
        ),
        titleLarge: GoogleFonts.orbitron(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: 1.0,
        ),
        bodyLarge: GoogleFonts.robotoMono(
          color: Colors.white70,
          fontSize: 16,
        ),
      ),
      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          fontFamily: 'Orbitron',
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 1.5,
        ),
      ),
      // Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryNeon,
          foregroundColor: Colors.black,
          elevation: 8,
          shadowColor: primaryNeon.withOpacity(0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0),
        ),
      ),
      // Card Theme
      cardTheme: CardTheme(
        color: cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
      ),
    );
  }
}
