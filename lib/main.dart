import 'package:flutter/material.dart';
import 'package:smart_call_scheduler/models/verified_number.dart';
import 'reminders_screen.dart';
import 'phone_verification_screen.dart';
import 'api_service.dart';
import 'package:google_fonts/google_fonts.dart';

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
      home: const VerificationChecker(), // Start with a verification check
    );
  }

  ThemeData _buildLightTheme() {
    final base = ThemeData.light();
    return base.copyWith(
      primaryColor: Colors.teal,
      scaffoldBackgroundColor: Colors.grey[100],
      hintColor: Colors.grey,
      textTheme: GoogleFonts.robotoTextTheme(base.textTheme).apply(
        bodyColor: Colors.grey[800],
        displayColor: Colors.grey[800],
      ),
      appBarTheme: AppBarTheme(
        color: Colors.teal[600],
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
          backgroundColor: Colors.teal[600],
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
      cardTheme: CardTheme(
        color: Colors.white,
        shadowColor: Colors.black12,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      ),
      iconTheme: IconThemeData(color: Colors.teal[600]),
      colorScheme: base.colorScheme.copyWith(
        primary: Colors.teal,
        secondary: Colors.tealAccent,
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    final base = ThemeData.dark();
    return base.copyWith(
      primaryColor: Colors.teal[200],
      scaffoldBackgroundColor: Colors.grey[900],
      hintColor: Colors.grey[400],
      textTheme: GoogleFonts.robotoTextTheme(base.textTheme).apply(
        bodyColor: Colors.grey[100],
        displayColor: Colors.grey[100],
      ),
      appBarTheme: AppBarTheme(
        color: Colors.teal[800],
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
          backgroundColor: Colors.teal[800],
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
          borderSide: BorderSide(color: Colors.teal[200]!),
        ),
        labelStyle: TextStyle(color: Colors.grey[400]),
      ),
      cardTheme: CardTheme(
        color: Colors.grey[800],
        shadowColor: Colors.black12,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      ),
      iconTheme: IconThemeData(color: Colors.teal[200]),
      colorScheme: base.colorScheme.copyWith(
        primary: Colors.teal[200],
        secondary: Colors.tealAccent,
      ),
    );
  }
}

class VerificationChecker extends StatefulWidget {
  const VerificationChecker({super.key});

  @override
  _VerificationCheckerState createState() => _VerificationCheckerState();
}

class _VerificationCheckerState extends State<VerificationChecker> {
  bool _isLoading = true;
  bool _hasVerifiedNumber = false;
  final ApiService apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _checkVerifiedNumbers();
  }

  Future<void> _checkVerifiedNumbers() async {
    try {
      List<VerifiedNumber> verifiedNumbers =
          await apiService.getVerifiedNumbers();
      setState(() {
        _hasVerifiedNumber = verifiedNumbers.isNotEmpty;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching verified numbers: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // If no verified numbers, show PhoneVerificationScreen
    if (!_hasVerifiedNumber) {
      return const PhoneVerificationScreen();
    }

    // If verified numbers are present, show RemindersScreen
    return const RemindersScreen();
  }
}
