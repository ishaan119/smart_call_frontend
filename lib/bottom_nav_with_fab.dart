import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Import flutter_svg package

class BottomNavWithFAB extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabTapped;

  const BottomNavWithFAB({
    super.key,
    required this.currentIndex,
    required this.onTabTapped,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 10.0, // Ensure enough margin around the notch
      child: SizedBox(
        height: 60, // Adjust height for more space
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            Expanded(
              child: GestureDetector(
                onTap: () => onTabTapped(0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Custom SVG icon for All Reminders
                    SvgPicture.asset(
                      'assets/icons/reminders_icon.svg',
                      color: currentIndex == 0
                          ? const Color(0xFF0052D4)
                          : Colors.grey,
                      height: 24.0, // Set height as per your design
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'All Reminders',
                      style: TextStyle(
                        fontSize: 12,
                        color: currentIndex == 0
                            ? const Color(0xFF0052D4)
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 40), // Space for the FAB notch
            Expanded(
              child: GestureDetector(
                onTap: () => onTabTapped(1),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Custom SVG icon for Call Logs
                    SvgPicture.asset(
                      'assets/icons/call_logs_icon.svg',
                      color: currentIndex == 1
                          ? const Color(0xFF0052D4)
                          : Colors.grey,
                      height: 24.0, // Set height as per your design
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Call Logs',
                      style: TextStyle(
                        fontSize: 12,
                        color: currentIndex == 1
                            ? const Color(0xFF0052D4)
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
