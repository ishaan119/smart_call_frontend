import 'package:flutter/material.dart';
import 'bottom_nav_with_fab.dart'; // Import the BottomNavWithFAB widget
import 'api_service.dart';
import 'new_reminder_screen.dart';
import 'call_logs_screen.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:intl/intl.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // Firebase Messaging for FCM
import 'package:permission_handler/permission_handler.dart'; // Import permission handler

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  _RemindersScreenState createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final ApiService apiService = ApiService();
  List<dynamic> activeReminders = [];
  List<dynamic> expiredReminders = [];
  bool isLoading = true;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isPlaying = false;
  int? currentlyPlayingReminderId;

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
        if (!reminderTime.isUtc) {
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

      if (activeReminders.isNotEmpty || expiredReminders.isNotEmpty) {
        await _checkNotificationPermission();
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching reminders: $e');
    }
  }

  Future<void> _checkNotificationPermission() async {
    PermissionStatus permissionStatus = await Permission.notification.status;

    if (permissionStatus != PermissionStatus.granted) {
      PermissionStatus newStatus = await Permission.notification.request();

      if (newStatus == PermissionStatus.granted) {
        await _storeFCMToken();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification permission denied')),
        );
      }
    } else {
      await _storeFCMToken();
    }
  }

  Future<void> _storeFCMToken() async {
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      String? fcmToken = await messaging.getToken();

      if (fcmToken != null) {
        await ApiService().storeFCMToken(fcmToken);
      } else {
        throw Exception('Failed to get FCM token');
      }
    } catch (e) {
      print('Error storing FCM token: $e');
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
        const SnackBar(
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

  // Function to handle voice message playing
  void playVoiceMessage(String url, int reminderId) async {
    try {
      if (isPlaying && currentlyPlayingReminderId == reminderId) {
        await pauseVoiceMessage(); // If playing, pause it
      } else {
        if (url.isNotEmpty) {
          print("Playing audio from URL: $url");

          setState(() {
            isPlaying = true;
            currentlyPlayingReminderId = reminderId;
          });

          await _audioPlayer.play(UrlSource(url));
          _audioPlayer.onPlayerComplete.listen((event) {
            setState(() {
              isPlaying = false;
              currentlyPlayingReminderId = null;
            });
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Invalid voice message URL.'),
                backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      setState(() {
        isPlaying = false;
        currentlyPlayingReminderId = null;
      });
      print('Error playing voice message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error playing voice message: $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  // Function to pause the voice message
  Future<void> pauseVoiceMessage() async {
    await _audioPlayer.pause();
    setState(() {
      isPlaying = false;
      currentlyPlayingReminderId = null;
    });
  }

  void _showMenu(BuildContext context, dynamic reminder, bool isExpired) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete'),
                onTap: () {
                  Navigator.pop(context); // Close the bottom sheet
                  deleteReminder(reminder['id']);
                },
              ),
              if (isExpired)
                ListTile(
                  leading: const Icon(Icons.edit, color: Colors.blue),
                  title: const Text('Reschedule'),
                  onTap: () {
                    Navigator.pop(context); // Close the bottom sheet
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NewReminderScreen(),
                      ),
                    );
                  },
                ),
            ],
          );
        });
  }

  Widget buildReminderCard(dynamic reminder, bool isExpired) {
    String frequencyText = '';

    if (reminder['frequency'] == 'daily') {
      frequencyText =
          'Daily ${DateFormat('hh:mm a').format(reminder['localTime'])}';
    } else if (reminder['frequency'] == 'weekly') {
      frequencyText =
          'Every ${DateFormat('EEEE').format(reminder['localTime'])} ${DateFormat('hh:mm a').format(reminder['localTime'])}';
    } else {
      frequencyText =
          DateFormat('dd MMM yyyy, hh:mm a').format(reminder['localTime']);
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: ListTile(
        leading: GestureDetector(
          onTap: () =>
              playVoiceMessage(reminder['voice_url'] ?? '', reminder['id']),
          child: Container(
            width: 72.0,
            height: 72.0,
            decoration: BoxDecoration(
              color: isExpired
                  ? const Color.fromARGB(255, 249, 249, 249)
                  : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              currentlyPlayingReminderId == reminder['id'] && isPlaying
                  ? Icons.pause
                  : Icons.play_arrow,
              size: 48.0,
              color: Colors.blue,
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
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  frequencyText,
                  style: TextStyle(
                      fontSize: 14.0,
                      color: isExpired ? Colors.grey : Colors.black),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  reminder['contact_name'] ??
                      reminder['contact_number'] ??
                      'Unknown Contact',
                  style: TextStyle(
                      fontSize: 14.0,
                      color: isExpired ? Colors.grey : Colors.black),
                ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () => _showMenu(context, reminder, isExpired),
        ),
      ),
    );
  }

  Widget buildRemindersList() {
    return ListView(
      padding: const EdgeInsets.only(bottom: 80.0),
      children: [
        if (activeReminders.isNotEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text('Active',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ...activeReminders
            .map((reminder) => buildReminderCard(reminder, false)),
        if (expiredReminders.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: Text('Expired',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          ...expiredReminders
              .map((reminder) => buildReminderCard(reminder, true)),
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
            'assets/images/empty_reminders_icon.png',
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
              backgroundColor: const Color(0xFF1577FE),
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
        backgroundColor: const Color(0xFF1577FE),
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNavWithFAB(
        currentIndex: 0,
        onTabTapped: (index) {
          if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const CallLogsScreen(),
              ),
            );
          }
        },
      ),
    );
  }
}
