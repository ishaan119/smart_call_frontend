import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:intl/intl.dart'; // Import for date and time formatting
import 'api_service.dart';
import 'drawer_menu.dart';
import 'new_reminder_screen.dart';

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

  @override
  void initState() {
    super.initState();
    fetchReminders();
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching reminders: $e')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reminder deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting reminder: $e')),
      );
    }
  }

  void playVoiceMessage(String url) async {
    try {
      if (url.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Loading voice message...')),
        );

        await _audioPlayer.play(UrlSource(url));

        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid voice message URL.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error playing voice message: $e')),
      );
    }
  }

  void showDeleteConfirmationDialog(int id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Delete Reminder"),
          content: const Text("Are you sure you want to delete this reminder?"),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text(
                "Delete",
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                deleteReminder(id);
              },
            ),
          ],
        );
      },
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

  // Updated rescheduleReminder function
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reminder rescheduled successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error rescheduling reminder: $e')),
        );
      }
    }
  }

  Future<DateTime?> showDateTimePicker() async {
    // First, pick a date
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(), // Can't pick a date in the past
      lastDate:
          DateTime.now().add(const Duration(days: 365)), // Up to 1 year ahead
    );

    if (date == null) return null;

    // Then, pick a time
    TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time == null) return null;

    // Combine date and time into a DateTime
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
      color: isPast ? Colors.grey[300] : null, // Gray out past reminders
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
                icon: Icon(Icons.play_circle_fill,
                    color: isPast ? Colors.grey : Colors.teal),
                iconSize: 30.0,
                onPressed: isPast
                    ? null
                    : () => playVoiceMessage(reminder['voice_url']),
              ),
            if (isPast)
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.blue),
                onPressed: () => rescheduleReminder(reminder),
                tooltip: 'Reschedule',
              ),
            IconButton(
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              onPressed: () => showDeleteConfirmationDialog(reminder['id']),
            ),
          ],
        ),
      ),
    );
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
              ? const Center(
                  child: Text(
                    'No reminders found',
                    style: TextStyle(fontSize: 18.0),
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
                    }).toList(),
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
                    }).toList(),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NewReminderScreen()),
          ).then((_) => fetchReminders());
        },
        backgroundColor: Colors.teal[600],
        child: const Icon(Icons.add),
      ),
    );
  }
}
