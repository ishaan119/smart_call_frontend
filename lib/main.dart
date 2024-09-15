import 'package:flutter/material.dart';
import 'reminders_screen.dart';
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
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: Colors.grey[100],
        hintColor: Colors.grey,
        textTheme: GoogleFonts.robotoTextTheme(
          Theme.of(context).textTheme.apply(
                bodyColor: Colors.grey[800],
                displayColor: Colors.grey[800],
              ),
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
        buttonTheme: ButtonThemeData(
          buttonColor: Colors.teal,
          textTheme: ButtonTextTheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
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
            padding:
                const EdgeInsets.symmetric(vertical: 16.0, horizontal: 32.0),
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
      ),
      home: const RemindersScreen(),
    );
  }
}
