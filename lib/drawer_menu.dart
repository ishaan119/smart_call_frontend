// drawer_menu.dart

import 'package:flutter/material.dart';
import 'new_reminder_screen.dart';
import 'phone_verification_screen.dart';
import 'verified_numbers_screen.dart';
import 'reminders_screen.dart';
import 'call_logs_screen.dart'; // Import the CallLogsScreen

class DrawerMenu extends StatelessWidget {
  const DrawerMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal, Colors.tealAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Adjusted the image display here
                CircleAvatar(
                  radius: 45,
                  backgroundColor: Colors.transparent,
                  child: ClipOval(
                    child: Image.asset(
                      'assets/app_icon.png',
                      fit: BoxFit.cover,
                      width: 90,
                      height: 90,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Smart Call',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          _buildDrawerItem(
            icon: Icons.add_alarm,
            text: 'Add Reminder',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NewReminderScreen(),
                ),
              );
            },
          ),
          _buildDrawerItem(
            icon: Icons.phone_android,
            text: 'Verify Phone',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PhoneVerificationScreen(),
                ),
              );
            },
          ),
          _buildDrawerItem(
            icon: Icons.list_alt,
            text: 'All Reminders',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RemindersScreen(),
                ),
              );
            },
          ),
          _buildDrawerItem(
            icon: Icons.verified_user,
            text: 'Verified Numbers',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const VerifiedNumbersScreen(),
                ),
              );
            },
          ),
          _buildDrawerItem(
            icon: Icons.history, // Add the Call Logs menu item
            text: 'Call Logs',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CallLogsScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String text,
    required GestureTapCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.teal),
      title: Text(
        text,
        style: const TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: onTap,
    );
  }
}
