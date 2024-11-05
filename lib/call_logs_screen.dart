import 'package:flutter/material.dart';
import 'package:smart_call_scheduler/reminders_screen.dart';
import 'api_service.dart';
import 'models/call_log.dart';
import 'bottom_nav_with_fab.dart'; // Import the BottomNavWithFAB widget
import 'new_reminder_screen.dart'; // Import the NewReminderScreen for navigation
import 'package:intl/intl.dart';

class CallLogsScreen extends StatefulWidget {
  const CallLogsScreen({super.key});

  @override
  _CallLogsScreenState createState() => _CallLogsScreenState();
}

class _CallLogsScreenState extends State<CallLogsScreen> {
  final ApiService apiService = ApiService();
  late Future<List<CallLog>> _callLogsFuture;

  @override
  void initState() {
    super.initState();
    _callLogsFuture = apiService.getCallLogs();
  }

  Future<void> _refreshCallLogs() async {
    setState(() {
      _callLogsFuture = apiService.getCallLogs();
    });
  }

  String _formatTimestamp(String timestamp) {
    final dateTime = DateTime.parse(timestamp);
    return DateFormat.yMMMd().add_jm().format(dateTime);
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'answered':
        return Icons.phone_in_talk;
      case 'no-answer':
        return Icons.phone_missed;
      case 'busy':
        return Icons.phone_locked;
      default:
        return Icons.phone;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'answered':
        return const Color(0xFF1577FE); // Updated to match app color
      case 'no-answer':
      case 'busy':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildCallLogCard(CallLog callLog) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      elevation: 2,
      shadowColor: Colors.grey[200],
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(callLog.status),
          child: Icon(
            _getStatusIcon(callLog.status),
            color: Colors.white,
          ),
        ),
        title: Text(
          callLog.reminderName ?? 'Unknown Reminder',
          style: const TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Call to: ${callLog.to}',
              style: TextStyle(fontSize: 14.0, color: Colors.grey[600]),
            ),
            Text(
              'Status: ${callLog.status}',
              style: TextStyle(fontSize: 14.0, color: Colors.grey[600]),
            ),
            Text(
              'Time: ${_formatTimestamp(callLog.timestamp)}',
              style: TextStyle(fontSize: 14.0, color: Colors.grey[600]),
            ),
          ],
        ),
        isThreeLine: true,
        trailing: Icon(
          Icons.more_vert,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Call Logs', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white, // Keep the header white
        iconTheme: const IconThemeData(color: Colors.black), // Black icon color
      ),
      body: RefreshIndicator(
        onRefresh: _refreshCallLogs,
        child: FutureBuilder<List<CallLog>>(
          future: _callLogsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              // Show a loading indicator while the future is loading
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              // If an error occurred, display it
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              // If no data was returned, show an empty state
              return const Center(child: Text('No call logs found.'));
            } else {
              // Data loaded successfully, display the call logs in a card-based layout
              final callLogs = snapshot.data!;
              return ListView.builder(
                padding: const EdgeInsets.only(
                    bottom: 80.0), // Ensure padding for FAB
                itemCount: callLogs.length,
                itemBuilder: (context, index) {
                  final callLog = callLogs[index];
                  return _buildCallLogCard(callLog);
                },
              );
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NewReminderScreen()),
          );
        },
        backgroundColor: const Color(0xFF1577FE), // Updated primary color
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNavWithFAB(
        currentIndex: 1, // Active tab index for "Call Log"
        onTabTapped: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const RemindersScreen()),
            );
          }
        },
      ),
    );
  }
}
