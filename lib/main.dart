import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'reminders_screen.dart';
import 'intro_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter binding
  await Firebase.initializeApp(); // Initialize Firebase
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool introSeen = prefs.getBool('intro_seen') ?? false;
  runApp(VoiceReminderApp(introSeen: introSeen));
}

class VoiceReminderApp extends StatelessWidget {
  final bool introSeen;
  const VoiceReminderApp({super.key, required this.introSeen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Call',
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode:
          ThemeMode.system, // Automatically switch based on system settings
      home: introSeen ? const RemindersScreen() : const IntroScreen(),
    );
  }

  ThemeData _buildLightTheme() {
    final base = ThemeData.light();
    return base.copyWith(
      primaryColor: const Color(0xFF1577FE), // Updated to match the base color
      scaffoldBackgroundColor: Colors.grey[100],
      hintColor: Colors.grey,
      textTheme: GoogleFonts.robotoTextTheme(base.textTheme).apply(
        bodyColor: Colors.grey[800],
        displayColor: Colors.grey[800],
      ),
      appBarTheme: AppBarTheme(
        color: const Color(0xFF1577FE), // Updated base color here too
        elevation: 2,
        titleTextStyle: GoogleFonts.roboto(
          fontSize: 22.0,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor:
              const Color(0xFF1577FE), // Apply the base color to buttons
          textStyle: GoogleFonts.roboto(
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 32.0),
          elevation: 2,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        labelStyle: const TextStyle(color: Colors.grey),
      ),
      cardTheme: const CardThemeData( // FIXED: Changed from CardTheme to CardThemeData
        color: Colors.white,
        shadowColor: Colors.black12,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12.0)),
        ),
        margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      ),
      iconTheme: const IconThemeData(color: Color(0xFF1577FE)), // Icon color
      colorScheme: base.colorScheme.copyWith(
        primary: const Color(0xFF1577FE), // Primary color scheme updated
        secondary: Colors.blueAccent,
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    final base = ThemeData.dark();
    return base.copyWith(
      primaryColor:
          const Color(0xFF1577FE), // Keep primary color consistent in dark mode
      scaffoldBackgroundColor: Colors.grey[900],
      hintColor: Colors.grey[400],
      textTheme: GoogleFonts.robotoTextTheme(base.textTheme).apply(
        bodyColor: Colors.grey[100],
        displayColor: Colors.grey[100],
      ),
      appBarTheme: AppBarTheme(
        color:
            const Color(0xFF1577FE), // Match dark theme AppBar with base color
        elevation: 2,
        titleTextStyle: GoogleFonts.roboto(
          fontSize: 22.0,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor:
              const Color(0xFF1577FE), // Update base color to match
          textStyle: GoogleFonts.roboto(
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 32.0),
          elevation: 2,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[800],
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: Color(0xFF1577FE)),
        ),
        labelStyle: TextStyle(color: Colors.grey[400]),
      ),
      cardTheme: CardThemeData(
        color: Colors.grey[800],
        shadowColor: Colors.black12,
        elevation: 2,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12.0)),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      ),
      iconTheme: const IconThemeData(color: Color(0xFF1577FE)),
      colorScheme: base.colorScheme.copyWith(
        primary: const Color(0xFF1577FE), // Base color consistent for dark mode
        secondary: Colors.blueAccent,
      ),
    );
  }
}