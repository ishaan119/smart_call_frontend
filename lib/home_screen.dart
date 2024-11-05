import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_call_scheduler/reminders_screen.dart';
// Import the HomeScreen widget

void main() {
  runApp(const VoiceReminderApp());
}

class VoiceReminderApp extends StatelessWidget {
  const VoiceReminderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Call',
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode:
          ThemeMode.system, // Automatically switch based on system settings
      home: const RemindersScreen(), // Set HomeScreen as the main entry point
    );
  }

  ThemeData _buildLightTheme() {
    final base = ThemeData.light();
    return base.copyWith(
      primaryColor: const Color(0xFF0052D4),
      scaffoldBackgroundColor: Colors.white,
      textTheme: GoogleFonts.nunitoTextTheme(base.textTheme).apply(
        bodyColor: Colors.grey[900],
        displayColor: Colors.grey[900],
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF0052D4),
        elevation: 2,
        titleTextStyle: GoogleFonts.nunito(
          fontSize: 22.0,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    final base = ThemeData.dark();
    return base.copyWith(
      primaryColor: const Color(0xFF21D4FD),
      scaffoldBackgroundColor: const Color(0xFF121212),
      textTheme: GoogleFonts.nunitoTextTheme(base.textTheme).apply(
        bodyColor: Colors.grey[300],
        displayColor: Colors.grey[300],
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF0052D4),
        elevation: 2,
        titleTextStyle: GoogleFonts.nunito(
          fontSize: 22.0,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
    );
  }
}
