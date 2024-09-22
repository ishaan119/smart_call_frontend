import 'package:flutter/material.dart';
import 'api_service.dart';
import 'models/call_log.dart';
import 'drawer_menu.dart';
import 'package:intl/intl.dart';

class CallLogsScreen extends StatefulWidget {
  const CallLogsScreen({Key? key}) : super(key: key);

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
        return Colors.green;
      case 'no-answer':
      case 'busy':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Call Logs'),
      ),
      drawer: const DrawerMenu(),
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
                itemCount: callLogs.length,
                itemBuilder: (context, index) {
                  final callLog = callLogs[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 16.0),
                    elevation: 2,
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
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Call to: ${callLog.to}'),
                          Text('Status: ${callLog.status}'),
                          Text('Time: ${_formatTimestamp(callLog.timestamp)}'),
                        ],
                      ),
                      isThreeLine: true,
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }
}
