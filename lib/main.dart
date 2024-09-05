import 'package:flutter/material.dart';
import 'new_reminder_screen.dart';
import 'phone_verification_screen.dart';
import 'reminders_screen.dart';
import 'verified_numbers_screen.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(VoiceReminderApp());
}

class VoiceReminderApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Call',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        hintColor: Colors.amber,
        textTheme: GoogleFonts.robotoTextTheme(
          Theme.of(context).textTheme,
        ),
        appBarTheme: AppBarTheme(
          color: Colors.teal,
          elevation: 0,
          titleTextStyle: GoogleFonts.roboto(
            fontSize: 20.0,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        buttonTheme: ButtonThemeData(
          buttonColor: Colors.teal,
          textTheme: ButtonTextTheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.teal,
            textStyle: GoogleFonts.roboto(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 32.0),
            elevation: 3,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[200],
          contentPadding:
              EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
          labelStyle: TextStyle(color: Colors.blueGrey),
        ),
        cardTheme: CardTheme(
          color: Colors.white,
          shadowColor: Colors.black26,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        ),
      ),
      home: RemindersScreen(),
    );
  }
}
