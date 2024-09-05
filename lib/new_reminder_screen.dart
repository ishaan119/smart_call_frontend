import 'package:flutter/material.dart';
import 'package:smart_call_scheduler/reminders_screen.dart';
import 'api_service.dart';
import 'drawer_menu.dart';
import 'phone_verification_screen.dart'; // Import the PhoneVerificationScreen

class NewReminderScreen extends StatefulWidget {
  @override
  _NewReminderScreenState createState() => _NewReminderScreenState();
}

class _NewReminderScreenState extends State<NewReminderScreen> {
  final TextEditingController _messageController = TextEditingController();
  TimeOfDay? _selectedTime;
  final ApiService apiService = ApiService();
  String? _selectedPhoneNumber;
  String _frequency = 'one-time';
  String? _selectedDayOfWeek; // For weekly reminders
  List<String> _verifiedNumbers = [];
  bool _isLoading = true; // To show a loading indicator

  @override
  void initState() {
    super.initState();
    fetchVerifiedNumbers();
  }

  void fetchVerifiedNumbers() async {
    try {
      List<Map<String, dynamic>> numbers =
          await apiService.getVerifiedNumbers();
      setState(() {
        _verifiedNumbers =
            numbers.map((number) => number['phone_number'] as String).toList();
        _selectedPhoneNumber =
            _verifiedNumbers.isNotEmpty ? _verifiedNumbers[0] : null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching verified numbers: $e')));
    }
  }

  void _pickTime() async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null) {
      setState(() {
        _selectedTime = pickedTime;
      });
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();
    final formattedTime =
        DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return "${formattedTime.hour.toString().padLeft(2, '0')}:${formattedTime.minute.toString().padLeft(2, '0')}";
  }

  Future<void> addReminder() async {
    String message = _messageController.text;

    if (message.isEmpty ||
        _selectedTime == null ||
        _selectedPhoneNumber == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('All fields are required')));
      return;
    }

    String formattedTime = _formatTimeOfDay(_selectedTime!);
    String dateTime =
        '${DateTime.now().toIso8601String().substring(0, 10)} $formattedTime:00';

    try {
      final response = await apiService.scheduleCall(
        _selectedPhoneNumber!,
        message,
        dateTime,
        _frequency,
        _selectedDayOfWeek, // Pass the day of the week if it's a weekly reminder
      );
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reminder added: ${response['job_id']}')));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => RemindersScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error adding reminder: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('New Reminder',
            style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold)),
      ),
      drawer: DrawerMenu(),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_verifiedNumbers.isEmpty) ...[
                        Center(
                          child: Column(
                            children: [
                              Text('No verified phone numbers available',
                                  style: TextStyle(
                                      fontSize: 16.0, color: Colors.red)),
                              SizedBox(height: 16.0),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            PhoneVerificationScreen()),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                      vertical: 16.0, horizontal: 64.0),
                                  elevation: 3,
                                ),
                                child: Text(
                                  'Verify Phone Number',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        Text('Select Phone Number',
                            style: TextStyle(
                                fontSize: 18.0, fontWeight: FontWeight.w600)),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.0),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: DropdownButton<String>(
                            value: _selectedPhoneNumber,
                            isExpanded: true,
                            underline: SizedBox(),
                            items: _verifiedNumbers.map((String number) {
                              return DropdownMenuItem<String>(
                                value: number,
                                child: Text(number,
                                    style: TextStyle(fontSize: 16.0)),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedPhoneNumber = newValue;
                              });
                            },
                          ),
                        ),
                        SizedBox(height: 16.0),
                        TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            labelText: 'Voice Message',
                            filled: true,
                            fillColor: Colors.grey[200],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                                vertical: 16.0, horizontal: 16.0),
                          ),
                          style: TextStyle(fontSize: 16.0),
                        ),
                        SizedBox(height: 16.0),
                        Text('Time',
                            style: TextStyle(
                                fontSize: 18.0, fontWeight: FontWeight.w600)),
                        ListTile(
                          title: Text(
                              _selectedTime == null
                                  ? 'Select Time'
                                  : _selectedTime!.format(context),
                              style: TextStyle(fontSize: 16.0)),
                          trailing: Icon(Icons.access_time, color: Colors.blue),
                          onTap: _pickTime,
                          tileColor: Colors.grey[200],
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0)),
                        ),
                        SizedBox(height: 16.0),
                        Text('Frequency',
                            style: TextStyle(
                                fontSize: 18.0, fontWeight: FontWeight.w600)),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.0),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: DropdownButton<String>(
                            value: _frequency,
                            isExpanded: true,
                            underline: SizedBox(),
                            items: <String>['one-time', 'daily', 'weekly']
                                .map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value,
                                    style: TextStyle(fontSize: 16.0)),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _frequency = newValue!;
                                _selectedDayOfWeek = null;
                              });
                            },
                          ),
                        ),
                        if (_frequency == 'weekly') ...[
                          SizedBox(height: 16.0),
                          Text('Day of Week',
                              style: TextStyle(
                                  fontSize: 18.0, fontWeight: FontWeight.w600)),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12.0),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: DropdownButton<String>(
                              value: _selectedDayOfWeek,
                              isExpanded: true,
                              underline: SizedBox(),
                              items: <String>[
                                'mon',
                                'tue',
                                'wed',
                                'thu',
                                'fri',
                                'sat',
                                'sun'
                              ].map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value.toUpperCase(),
                                      style: TextStyle(fontSize: 16.0)),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedDayOfWeek = newValue;
                                });
                              },
                            ),
                          ),
                        ],
                        SizedBox(height: 32.0), // Add space before the button
                        ElevatedButton(
                          onPressed:
                              _selectedPhoneNumber == null ? null : addReminder,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 16.0),
                          ),
                          child: Center(
                            child: Text(
                              'Add Reminder',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
