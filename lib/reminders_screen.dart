import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'api_service.dart';
import 'drawer_menu.dart';
import 'new_reminder_screen.dart';
import 'phone_verification_screen.dart';
import 'models/verified_number.dart';

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
  bool _hasVerifiedNumber = true; // Assume true initially
  final AudioPlayer _audioPlayer = AudioPlayer();
  late String userTimezone;

  @override
  void initState() {
    super.initState();
    tz_data.initializeTimeZones();
    userTimezone = tz.local.name;
    _checkVerifiedNumbers(); // First check for verified numbers
  }

  Future<void> _checkVerifiedNumbers() async {
    try {
      List<VerifiedNumber> verifiedNumbers =
          await apiService.getVerifiedNumbers();
      if (verifiedNumbers.isEmpty) {
        // If no verified numbers, route to the PhoneVerificationScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => const PhoneVerificationScreen()),
        );
      } else {
        _hasVerifiedNumber = true;
        fetchReminders();
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      showCustomSnackBar('Error checking verified numbers: $e',
          color: Colors.red);
    }
  }

  Future<void> fetchReminders() async {
    try {
      final response = await apiService.getReminders();

      // Separate and sort reminders
      activeReminders = [];
      expiredReminders = [];

      for (var reminder in response) {
        // The time from the backend should be in ISO 8601 format with timezone info
        DateTime reminderTime = DateTime.parse(reminder['time']);

        // Ensure the time is treated as UTC if it doesn't have timezone info
        if (reminderTime.isUtc == false) {
          reminderTime = DateTime.parse(reminder['time'] + 'Z');
        }

        // Update the reminder's time to be in local time for display purposes
        reminder['localTime'] = reminderTime.toLocal();

        // Check if one-time reminder is in the past
        bool isPast = isOneTimeReminderInPast(
            reminder['localTime'], reminder['frequency']);
        if (isPast) {
          expiredReminders.add(reminder);
        } else {
          activeReminders.add(reminder);
        }
      }

      // Sort active reminders by time (earliest first)
      activeReminders.sort((a, b) {
        DateTime aTime = a['localTime'];
        DateTime bTime = b['localTime'];
        return aTime.compareTo(bTime);
      });

      // Sort expired reminders by time (most recent expired first)
      expiredReminders.sort((a, b) {
        DateTime aTime = a['localTime'];
        DateTime bTime = b['localTime'];
        return bTime.compareTo(aTime);
      });

      setState(() {
        isLoading = false;
      });

      // If there are reminders, ask for push notification permission
      if (activeReminders.isNotEmpty || expiredReminders.isNotEmpty) {
        await _askNotificationPermission();
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      showCustomSnackBar('Error fetching reminders: $e', color: Colors.red);
    }
  }

  Future<void> _askNotificationPermission() async {
    PermissionStatus permissionStatus = await Permission.notification.status;
    if (!permissionStatus.isGranted) {
      // If permission isn't granted, request it
      PermissionStatus newStatus = await Permission.notification.request();
      if (newStatus.isGranted) {
        // You can initialize Firebase Messaging here
        FirebaseMessaging messaging = FirebaseMessaging.instance;
        await messaging.subscribeToTopic('reminders');
        print('Push notification permission granted');
      } else {
        print('Push notification permission denied');
      }
    } else {
      print('Push notification permission already granted');
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
      showCustomSnackBar('Reminder deleted successfully', color: Colors.green);
    } catch (e) {
      showCustomSnackBar('Error deleting reminder: $e', color: Colors.red);
    }
  }

  void playVoiceMessage(String url) async {
    try {
      if (url.isNotEmpty) {
        showCustomSnackBar('Loading voice message...');

        await _audioPlayer.play(UrlSource(url));

        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      } else {
        showCustomSnackBar('Invalid voice message URL.', color: Colors.red);
      }
    } catch (e) {
      showCustomSnackBar('Error playing voice message: $e', color: Colors.red);
    }
  }

  void rescheduleReminder(reminder) async {
    DateTime? newDateTime = await showDateTimePicker();

    if (newDateTime != null) {
      try {
        // Convert newDateTime to UTC before scheduling
        String newTime =
            DateFormat('yyyy-MM-dd HH:mm:ss').format(newDateTime.toUtc());

        // Include the user's timezone
        String timezone = userTimezone;

        // Determine if the reminder is a voice reminder
        bool isVoiceReminder =
            reminder['voice_url'] != null && reminder['voice_url'].isNotEmpty;

        // Prepare the data for the API request
        Map<String, dynamic> data = {
          'to': reminder['to'],
          'time': newTime,
          'frequency': reminder['frequency'],
          'day_of_week': reminder['day_of_week'],
          'name': reminder['name'],
          'timezone': timezone,
          'device_id': '1234567890', // Include device_id
        };

        if (isVoiceReminder) {
          data['voice_url'] = reminder['voice_url'];
        } else {
          data['message'] = reminder['message'];
        }

        // Make the API call to schedule the reminder
        await apiService.scheduleCall(
            reminder['to'],
            newTime,
            reminder['frequency'],
            reminder['name'],
            reminder['timezone'],
            reminder['device_id'],
            reminder['message']);

        // Delete the old reminder
        await apiService.deleteReminder(reminder['id']);

        fetchReminders();
        showCustomSnackBar('Reminder rescheduled successfully',
            color: Colors.green);
      } catch (e) {
        showCustomSnackBar('Error rescheduling reminder: $e',
            color: Colors.red);
      }
    }
  }

  Future<DateTime?> showDateTimePicker() async {
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(), // Can't pick a date in the past
      lastDate:
          DateTime.now().add(const Duration(days: 365)), // Up to 1 year ahead
    );

    if (date == null) return null;

    TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Widget buildReminderCard(reminder) {
    final hasVoiceMessage =
        reminder['voice_url'] != null && reminder['voice_url'].isNotEmpty;
    final message = reminder['name'] ??
        (hasVoiceMessage ? 'Voice Reminder' : reminder['message']);

    // Get the formatted time string
    String displayTime = formatReminderTime(
      reminder['localTime'],
      reminder['frequency'],
      reminder['day_of_week'],
    );

    // Check if one-time reminder is in the past
    bool isPast =
        isOneTimeReminderInPast(reminder['localTime'], reminder['frequency']);

    return Card(
      elevation: 2,
      color: isPast ? Colors.grey[300] : null,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isPast ? Colors.grey : Colors.teal[600],
          child: hasVoiceMessage
              ? const Icon(Icons.mic, color: Colors.white)
              : const Icon(Icons.text_snippet, color: Colors.white),
        ),
        title: Text(
          message,
          style: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.w600,
            color: isPast ? Colors.grey : Colors.black,
          ),
        ),
        subtitle: Text(
          displayTime + (isPast ? ' (Expired)' : ''),
          style: TextStyle(
              fontSize: 14.0, color: isPast ? Colors.grey : Colors.grey[600]),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasVoiceMessage)
              IconButton(
                icon: const Icon(Icons.play_arrow, color: Colors.green),
                onPressed: () => playVoiceMessage(reminder['voice_url']),
              ),
            IconButton(
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              onPressed: () => deleteReminder(reminder['id']),
            ),
          ],
        ),
      ),
    );
  }

  // Helper function to format the reminder time
  String formatReminderTime(
      DateTime dateTime, String frequency, String? dayOfWeek) {
    String formattedTime = DateFormat.jm().format(dateTime); // e.g., 9:00 PM

    if (frequency == 'daily') {
      return 'Every day at $formattedTime';
    } else if (frequency == 'weekly') {
      if (dayOfWeek != null) {
        // Map day_of_week abbreviation to full name
        String day = getFullDayName(dayOfWeek);
        return 'Every $day at $formattedTime';
      } else {
        return 'Weekly at $formattedTime';
      }
    } else {
      // For one-time reminders
      String formattedDate = DateFormat('MMM d, yyyy').format(dateTime);
      return 'On $formattedDate at $formattedTime';
    }
  }

  // Function to get full day name from abbreviation
  String getFullDayName(String dayAbbreviation) {
    switch (dayAbbreviation.toLowerCase()) {
      case 'mon':
        return 'Monday';
      case 'tue':
        return 'Tuesday';
      case 'wed':
        return 'Wednesday';
      case 'thu':
        return 'Thursday';
      case 'fri':
        return 'Friday';
      case 'sat':
        return 'Saturday';
      case 'sun':
        return 'Sunday';
      default:
        return dayAbbreviation;
    }
  }

  void showCustomSnackBar(String message, {Color? color}) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: color ?? Colors.teal,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Reminders'),
        centerTitle: true,
      ),
      drawer: const DrawerMenu(),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : (activeReminders.isEmpty && expiredReminders.isEmpty)
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.notifications_off,
                        size: 80,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No reminders found',
                        style: TextStyle(fontSize: 18.0),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Add Reminder'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NewReminderScreen(),
                            ),
                          ).then((_) => fetchReminders());
                        },
                      ),
                    ],
                  ),
                )
              : ListView(
                  children: [
                    if (activeReminders.isNotEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'Active Reminders',
                          style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ...activeReminders.map((reminder) {
                      return buildReminderCard(reminder);
                    }),
                    if (expiredReminders.isNotEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'Expired Reminders',
                          style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ...expiredReminders.map((reminder) {
                      return buildReminderCard(reminder);
                    }),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NewReminderScreen(),
            ),
          ).then((_) => fetchReminders());
        },
        backgroundColor: Colors.teal[600],
        child: const Icon(Icons.add),
      ),
    );
  }
}
