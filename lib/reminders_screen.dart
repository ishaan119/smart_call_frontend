import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:intl/intl.dart';
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

  @override
  void initState() {
    super.initState();
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
        bool isPast =
            isOneTimeReminderInPast(reminder['time'], reminder['frequency']);
        if (isPast) {
          expiredReminders.add(reminder);
        } else {
          activeReminders.add(reminder);
        }
      }

      // Sort active reminders by time (earliest first)
      activeReminders.sort((a, b) {
        DateTime aTime = DateTime.parse(a['time']);
        DateTime bTime = DateTime.parse(b['time']);
        return aTime.compareTo(bTime);
      });

      // Sort expired reminders by time (most recent expired first)
      expiredReminders.sort((a, b) {
        DateTime aTime = DateTime.parse(a['time']);
        DateTime bTime = DateTime.parse(b['time']);
        return bTime.compareTo(aTime);
      });

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      showCustomSnackBar('Error fetching reminders: $e', color: Colors.red);
    }
  }

  bool isOneTimeReminderInPast(String timeStr, String frequency) {
    if (frequency != 'one-time') return false;
    DateTime dateTime = DateTime.parse(timeStr);
    DateTime now = DateTime.now();
    return dateTime.isBefore(now);
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
        // Format datetime to match backend's expected format
        String newTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(newDateTime);

        // Check if the reminder is a voice reminder
        bool isVoiceReminder =
            reminder['voice_url'] != null && reminder['voice_url'].isNotEmpty;

        if (isVoiceReminder) {
          // Reschedule using scheduleVoiceCall
          await apiService.scheduleVoiceCall(
            reminder['to'],
            reminder['voice_url'],
            newTime,
            reminder['frequency'],
            reminder['day_of_week'],
            reminder['name'],
          );
        } else {
          // Reschedule using scheduleCall
          await apiService.scheduleCall(
            reminder['to'],
            reminder['message'],
            newTime,
            reminder['frequency'],
            reminder['day_of_week'],
            reminder['name'],
          );
        }

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
      reminder['time'],
      reminder['frequency'],
      reminder['day_of_week'],
    );

    // Check if one-time reminder is in the past
    bool isPast =
        isOneTimeReminderInPast(reminder['time'], reminder['frequency']);

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
      String timeStr, String frequency, String? dayOfWeek) {
    DateTime dateTime = DateTime.parse(timeStr);
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
