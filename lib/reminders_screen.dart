import 'package:flutter/material.dart';
import 'api_service.dart';
import 'drawer_menu.dart';
import 'new_reminder_screen.dart'; // Import the NewReminderScreen

class RemindersScreen extends StatefulWidget {
  @override
  _RemindersScreenState createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final ApiService apiService = ApiService(); // Initialize the ApiService
  List<dynamic> reminders = []; // List to hold reminders
  bool isLoading = true; // To show a loading indicator

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
          SnackBar(content: Text('Reminder deleted successfully')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error deleting reminder: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('All Reminders'),
      ),
      drawer: DrawerMenu(), // Add the drawer menu
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(),
            ) // Show a loading indicator while fetching data
          : reminders.isEmpty
              ? Center(child: Text('No reminders found'))
              : Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ListView.builder(
                    itemCount: reminders.length,
                    itemBuilder: (context, index) {
                      final reminder = reminders[index];
                      return Card(
                        elevation: 2,
                        margin: EdgeInsets.symmetric(vertical: 8.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: ListTile(
                          title: Text(
                            reminder['message'],
                            style: TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            'Time: ${reminder['time']}\nFrequency: ${reminder['frequency']}',
                            style: TextStyle(
                                fontSize: 14.0, color: Colors.grey[600]),
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => deleteReminder(reminder['id']),
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
            MaterialPageRoute(builder: (context) => NewReminderScreen()),
          ).then((_) => fetchReminders()); // Refresh reminders after adding
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.blueAccent,
      ),
    );
  }
}
