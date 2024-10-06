import 'package:flutter/material.dart';
import 'bottom_nav_with_fab.dart'; // Import the BottomNavWithFAB widget
import 'api_service.dart';
import 'new_reminder_screen.dart';
import 'call_logs_screen.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Import the flutter_svg package
import 'package:intl/intl.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({Key? key}) : super(key: key);

  @override
  _RemindersScreenState createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final ApiService apiService = ApiService();
  List<dynamic> activeReminders = [];
  List<dynamic> expiredReminders = [];
  bool isLoading = true;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    fetchReminders();
  }

  Future<void> fetchReminders() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await apiService.getReminders();
      activeReminders = [];
      expiredReminders = [];

      for (var reminder in response) {
        DateTime reminderTime = DateTime.parse(reminder['time']);
        if (reminderTime.isUtc == false) {
          reminderTime = DateTime.parse(reminder['time'] + 'Z');
        }
        reminder['localTime'] = reminderTime.toLocal();
        if (isOneTimeReminderInPast(
            reminder['localTime'], reminder['frequency'])) {
          expiredReminders.add(reminder);
        } else {
          activeReminders.add(reminder);
        }
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching reminders: $e');
    }
  }

  bool isOneTimeReminderInPast(DateTime reminderLocalTime, String frequency) {
    if (frequency != 'one-time') return false;
    DateTime now = DateTime.now();
    return reminderLocalTime.isBefore(now);
  }

  void deleteReminder(int id) async {
    try {
      await apiService.deleteReminder(id);
      fetchReminders();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Reminder deleted successfully'),
            backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error deleting reminder: $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  void playVoiceMessage(String url) async {
    try {
      if (url.isNotEmpty) {
        await _audioPlayer.play(UrlSource(url));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Invalid voice message URL.'),
              backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error playing voice message: $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  Widget buildReminderCard(dynamic reminder, bool isExpired) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: ListTile(
        leading: GestureDetector(
          onTap: isExpired
              ? null
              : () => playVoiceMessage(reminder['voice_url'] ?? ''),
          child: Container(
            width: 64.0, // Adjusted container size
            height: 64.0,
            decoration: BoxDecoration(
              color: isExpired
                  ? Colors.grey[400]
                  : Colors.transparent, // Adjusted background color
              shape: BoxShape.circle,
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0), // Proper padding
              child: SvgPicture.asset(
                'assets/icons/play_icon.svg', // Use your custom SVG path
                width: 40, // Adjust width as per design
                height: 40, // Adjust height as per design
              ),
            ),
          ),
        ),
        title: Text(
          reminder['name'] ?? 'Reminder Name',
          style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.w600,
              color: isExpired ? Colors.grey : Colors.black),
        ),
        subtitle: Row(
          children: [
            Icon(Icons.access_time, size: 16, color: Colors.grey[500]),
            const SizedBox(width: 4),
            Text(
              DateFormat('dd MMM yyyy, hh:mm a').format(reminder['localTime']),
              style: TextStyle(
                  fontSize: 14.0,
                  color: isExpired ? Colors.grey : Colors.black),
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete, color: Colors.red),
          onPressed: () {
            deleteReminder(reminder['id']);
          },
        ),
      ),
    );
  }

  Widget buildRemindersList() {
    return ListView(
      padding: const EdgeInsets.only(bottom: 80.0),
      children: [
        if (activeReminders.isNotEmpty)
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text('Active',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ...activeReminders
            .map((reminder) => buildReminderCard(reminder, false))
            .toList(),
        if (expiredReminders.isNotEmpty) ...[
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: Text('Expired',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          ...expiredReminders
              .map((reminder) => buildReminderCard(reminder, true))
              .toList(),
        ],
      ],
    );
  }

  Widget buildEmptyReminders() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/empty_reminders_icon.png', // Custom icon for empty state
            height: 150,
          ),
          const SizedBox(height: 20),
          const Text(
            'No reminders found',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const NewReminderScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1577FE), // Primary button color
              padding:
                  const EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
            child: const Text(
              'Add Reminder',
              style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('All Reminders', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 1,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: activeReminders.isEmpty && expiredReminders.isEmpty
                  ? buildEmptyReminders()
                  : buildRemindersList(),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NewReminderScreen()),
          );
        },
        backgroundColor: const Color(0xFF1577FE), // Primary color
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNavWithFAB(
        currentIndex: 0, // Active tab index for "All Reminders"
        onTabTapped: (index) {
          if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    CallLogsScreen(), // Navigate to Call Logs Screen
              ),
            );
          }
        },
      ),
    );
  }
}
