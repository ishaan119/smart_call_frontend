import 'package:flutter/material.dart';
import 'package:smart_call_scheduler/new_reminder_screen.dart';
import 'bottom_nav_with_fab.dart'; // Custom bottom nav with custom icons

class FABNavScaffold extends StatelessWidget {
  final int currentIndex;
  final Widget body;
  final Function(int) onTabTapped;

  const FABNavScaffold({
    Key? key,
    required this.currentIndex,
    required this.body,
    required this.onTabTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: body, // Content specific to each screen
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to a screen when FAB is pressed, e.g., NewReminderScreen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const NewReminderScreen()),
          );
        },
        backgroundColor: const Color(0xFF0052D4),
        child: Image.asset(
          'assets/icons/add_icon.png', // Custom FAB icon (e.g., add_icon.png)
          height: 24,
          color: Colors.white,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNavWithFAB(
        currentIndex: currentIndex,
        onTabTapped: onTabTapped,
      ),
    );
  }
}
