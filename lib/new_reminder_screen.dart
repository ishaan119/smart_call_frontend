import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'dart:async';
import 'api_service.dart';
import 'reminders_screen.dart';
import 'drawer_menu.dart';
import 'phone_verification_screen.dart';

class NewReminderScreen extends StatefulWidget {
  const NewReminderScreen({super.key});

  @override
  _NewReminderScreenState createState() => _NewReminderScreenState();
}

class _NewReminderScreenState extends State<NewReminderScreen> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _nameController =
      TextEditingController(); // Controller for reminder name
  TimeOfDay? _selectedTime;
  final ApiService apiService = ApiService();
  String? _selectedPhoneNumber;
  String _frequency = 'one-time'; // Default to one-time
  String? _selectedDayOfWeek;
  List<String> _verifiedNumbers = [];
  bool _isLoading = true;
  bool _isVoiceMessage = true; // Default to voice message
  bool _isRecording = false;

  FlutterSoundRecorder? _audioRecorder;
  String? _recordedFilePath;

  @override
  void initState() {
    super.initState();
    fetchVerifiedNumbers();
    _audioRecorder = FlutterSoundRecorder();
    _initializeRecorder();
  }

  Future<void> fetchVerifiedNumbers() async {
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
        SnackBar(content: Text('Error fetching verified numbers: $e')),
      );
    }
  }

  Future<void> _initializeRecorder() async {
    var status = await Permission.microphone.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission is required')),
      );
      return;
    }
    await _audioRecorder!.openRecorder();
  }

  Future<void> _startRecording() async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/recorded_voice.aac';
    await _audioRecorder!.startRecorder(toFile: filePath, codec: Codec.aacADTS);
    setState(() {
      _isRecording = true;
      _recordedFilePath = filePath;
    });
  }

  Future<void> _stopRecording() async {
    await _audioRecorder!.stopRecorder();
    setState(() {
      _isRecording = false;
    });
  }

  /// Method to show the time picker and select a time for the reminder
  Future<void> _pickTime() async {
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

  Future<void> addReminder() async {
    if (_selectedPhoneNumber == null ||
        _selectedTime == null ||
        _nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('All fields including reminder name are required')),
      );
      return;
    }

    String formattedTime = _formatTimeOfDay(_selectedTime!);
    String dateTime =
        '${DateTime.now().toIso8601String().substring(0, 10)} $formattedTime:00';

    try {
      if (_isVoiceMessage && _recordedFilePath != null) {
        // Upload the voice file and schedule the reminder with the voice URL
        File recordedFile = File(_recordedFilePath!);
        String voiceUrl = await apiService.uploadVoiceFile(recordedFile);
        await apiService.scheduleVoiceCall(
          _selectedPhoneNumber!,
          voiceUrl,
          dateTime,
          _frequency,
          _selectedDayOfWeek,
          _nameController.text, // Pass the reminder name
        );
      } else {
        // Schedule the reminder with the text message
        await apiService.scheduleCall(
          _selectedPhoneNumber!,
          _messageController.text,
          dateTime,
          _frequency,
          _selectedDayOfWeek,
          _nameController.text,
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reminder added')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const RemindersScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Reminder',
            style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold)),
      ),
      drawer: const DrawerMenu(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_verifiedNumbers.isEmpty)
                        Center(
                          child: Column(
                            children: [
                              const Text('No verified phone numbers available',
                                  style: TextStyle(
                                      fontSize: 16.0, color: Colors.red)),
                              const SizedBox(height: 16.0),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const PhoneVerificationScreen()),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16.0, horizontal: 64.0),
                                  elevation: 3,
                                ),
                                child: const Text(
                                  'Verify Phone Number',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18.0,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        )
                      else ...[
                        const Text('Select Phone Number',
                            style: TextStyle(
                                fontSize: 18.0, fontWeight: FontWeight.w600)),
                        DropdownButton<String>(
                          value: _selectedPhoneNumber,
                          isExpanded: true,
                          items: _verifiedNumbers.map((String number) {
                            return DropdownMenuItem<String>(
                              value: number,
                              child: Text(number),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedPhoneNumber = newValue;
                            });
                          },
                        ),
                        const SizedBox(height: 16.0),
                        TextField(
                          controller:
                              _nameController, // Input for reminder name
                          decoration:
                              const InputDecoration(labelText: 'Reminder Name'),
                        ),
                        const SizedBox(height: 16.0),
                        const Text('Reminder Type',
                            style: TextStyle(
                                fontSize: 18.0, fontWeight: FontWeight.w600)),
                        DropdownButton<String>(
                          value: _frequency,
                          isExpanded: true,
                          items: <String>['one-time', 'daily', 'weekly']
                              .map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _frequency = newValue!;
                              _selectedDayOfWeek =
                                  null; // Reset day of week for non-weekly reminders
                            });
                          },
                        ),
                        if (_frequency == 'weekly') ...[
                          const SizedBox(height: 16.0),
                          const Text('Day of the Week',
                              style: TextStyle(
                                  fontSize: 18.0, fontWeight: FontWeight.w600)),
                          DropdownButton<String>(
                            value: _selectedDayOfWeek,
                            isExpanded: true,
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
                                child: Text(value.toUpperCase()),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedDayOfWeek = newValue;
                              });
                            },
                          ),
                        ],
                        const SizedBox(height: 16.0),
                        const Text('Message Type',
                            style: TextStyle(
                                fontSize: 18.0, fontWeight: FontWeight.w600)),
                        SwitchListTile(
                          title: const Text('Use Voice Message'),
                          value: _isVoiceMessage,
                          onChanged: (bool value) {
                            setState(() {
                              _isVoiceMessage = value;
                            });
                          },
                        ),
                        if (_isVoiceMessage)
                          Column(
                            children: [
                              ElevatedButton(
                                onPressed: _isRecording
                                    ? _stopRecording
                                    : _startRecording,
                                child: Text(_isRecording
                                    ? 'Stop Recording'
                                    : 'Start Recording'),
                              ),
                              if (_recordedFilePath != null)
                                const Text('Recording saved',
                                    style: TextStyle(color: Colors.green)),
                            ],
                          )
                        else
                          TextField(
                            controller: _messageController,
                            decoration: const InputDecoration(
                                labelText: 'Text Message'),
                          ),
                        const SizedBox(height: 16.0),
                        ListTile(
                          title: Text(_selectedTime == null
                              ? 'Select Time'
                              : _selectedTime!.format(context)),
                          trailing: const Icon(Icons.access_time),
                          onTap: _pickTime,
                        ),
                        const SizedBox(height: 16.0),
                        ElevatedButton(
                          onPressed: addReminder,
                          child: const Text('Add Reminder'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();
    final formattedTime =
        DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return "${formattedTime.hour.toString().padLeft(2, '0')}:${formattedTime.minute.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    _audioRecorder!.closeRecorder();
    _audioRecorder = null;
    super.dispose();
  }
}
