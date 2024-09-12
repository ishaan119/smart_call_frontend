import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart'; // New API import
import 'api_service.dart';
import 'drawer_menu.dart';
import 'new_reminder_screen.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  _RemindersScreenState createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final ApiService apiService = ApiService(); // Initialize the ApiService
  List<dynamic> reminders = []; // List to hold reminders
  bool isLoading = true; // To show a loading indicator

  final AudioPlayer _audioPlayer =
      AudioPlayer(); // Audio player for voice messages

  @override
  void initState() {
    super.initState();
    fetchReminders(); // Fetch reminders when the screen loads
  }

  void fetchReminders() async {
    try {
      final response = await apiService.getReminders();
      setState(() {
        reminders = response;
        isLoading = false; // Hide the loading indicator once data is fetched
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching reminders: $e')));
    }
  }

  void deleteReminder(int id) async {
    try {
      await apiService.deleteReminder(id);
      fetchReminders(); // Refresh the list after deleting a reminder
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reminder deleted successfully')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error deleting reminder: $e')));
    }
  }

  void playVoiceMessage(String url) async {
    try {
      if (url.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Loading voice message...')));

        // Use the play method directly with the URL
        await _audioPlayer.play(UrlSource(url));

        ScaffoldMessenger.of(context)
            .hideCurrentSnackBar(); // Hide the snack bar when the audio starts playing
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid voice message URL.')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error playing voice message: $e')));
    }
  }

  @override
  void dispose() {
    _audioPlayer
        .dispose(); // Dispose the audio player when the screen is closed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Reminders'),
      ),
      drawer: const DrawerMenu(), // Add the drawer menu
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            ) // Show a loading indicator while fetching data
          : reminders.isEmpty
              ? const Center(child: Text('No reminders found'))
              : Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ListView.builder(
                    itemCount: reminders.length,
                    itemBuilder: (context, index) {
                      final reminder = reminders[index];
                      final hasVoiceMessage = reminder['voice_url'] != null &&
                          reminder['voice_url'].isNotEmpty;
                      final message = hasVoiceMessage
                          ? reminder['name']
                          : reminder['message'];

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: ListTile(
                          title: Text(
                            message,
                            style: const TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            'Time: ${reminder['time']}\nFrequency: ${reminder['frequency']}',
                            style: TextStyle(
                                fontSize: 14.0, color: Colors.grey[600]),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (hasVoiceMessage)
                                IconButton(
                                  icon: const Icon(Icons.play_arrow,
                                      color: Colors.blue),
                                  onPressed: () =>
                                      playVoiceMessage(reminder['voice_url']),
                                ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => deleteReminder(reminder['id']),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NewReminderScreen()),
          ).then((_) => fetchReminders()); // Refresh reminders after adding
        },
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add),
      ),
    );
  }
}
