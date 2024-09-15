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
import 'package:uuid/uuid.dart';

// No need to redefine the VerifiedNumber class here since it's defined in api_service.dart

class NewReminderScreen extends StatefulWidget {
  const NewReminderScreen({super.key});

  @override
  _NewReminderScreenState createState() => _NewReminderScreenState();
}

class _NewReminderScreenState extends State<NewReminderScreen> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _reminderNameController = TextEditingController();
  TimeOfDay? _selectedTime;
  final ApiService apiService = ApiService();
  VerifiedNumber? _selectedNumber;
  String _frequency = 'one-time'; // Default to 'one-time'
  String? _selectedDayOfWeek;
  List<VerifiedNumber> _verifiedNumbers = [];
  bool _isLoading = true;
  bool _isVoiceMessage = true; // Default to voice message
  bool _isRecording = false;
  bool _isSubmitting = false; // Flag to disable the button after first press

  final List<String> _frequencyOptions = ['one-time', 'daily', 'weekly'];

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
      List<VerifiedNumber> numbers = await apiService.getVerifiedNumbers();

      setState(() {
        _verifiedNumbers = numbers;
        // Update _selectedNumber if it's not in the new list
        if (!_verifiedNumbers.contains(_selectedNumber)) {
          _selectedNumber =
              _verifiedNumbers.isNotEmpty ? _verifiedNumbers[0] : null;
        }
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
    // Generate a unique ID for the file
    var uuid = Uuid();
    String uniqueId = uuid.v4(); // Generates a random UUID
    final filePath = '${directory.path}/recorded_voice_$uniqueId.wav';
    // Use Codec.pcm16WAV for .wav or Codec.mp3 for .mp3
    await _audioRecorder!
        .startRecorder(toFile: filePath, codec: Codec.pcm16WAV);
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
    if (_selectedNumber == null ||
        _selectedTime == null ||
        _reminderNameController.text.isEmpty ||
        (_isVoiceMessage && _recordedFilePath == null) ||
        (!_isVoiceMessage && _messageController.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true; // Disable the button
    });

    String formattedTime = _formatTimeOfDay(_selectedTime!);
    String dateTime =
        '${DateTime.now().toIso8601String().substring(0, 10)} $formattedTime:00';

    try {
      if (_isVoiceMessage && _recordedFilePath != null) {
        // Upload the voice file and schedule the reminder with the voice URL
        File recordedFile = File(_recordedFilePath!);
        String voiceUrl = await apiService.uploadVoiceFile(recordedFile);
        await apiService.scheduleVoiceCall(
          _selectedNumber!.phoneNumber,
          voiceUrl,
          dateTime,
          _frequency,
          _selectedDayOfWeek,
          _reminderNameController.text,
        );
      } else {
        // Schedule the reminder with the text message
        await apiService.scheduleCall(
          _selectedNumber!.phoneNumber,
          _messageController.text,
          dateTime,
          _frequency,
          _selectedDayOfWeek,
          _reminderNameController.text,
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reminder added successfully')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const RemindersScreen()),
      );
    } catch (e) {
      setState(() {
        _isSubmitting = false; // Re-enable the button on error
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  void dispose() {
    _audioRecorder!.closeRecorder();
    _audioRecorder = null;
    _messageController.dispose();
    _reminderNameController.dispose();
    super.dispose();
  }

  Widget _buildVerifiedNumbersDropdown() {
    if (_verifiedNumbers.isEmpty) {
      // No verified numbers available
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'No verified phone numbers available.',
              style: TextStyle(fontSize: 18.0, color: Colors.redAccent),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const PhoneVerificationScreen()),
                ).then((_) => fetchVerifiedNumbers());
              },
              child: const Text('Verify Phone Number'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    vertical: 16.0, horizontal: 32.0),
              ),
            ),
          ],
        ),
      );
    } else {
      // Verified numbers are available
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Contact',
            style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4.0),
          DropdownButtonFormField<VerifiedNumber>(
            value: _verifiedNumbers.contains(_selectedNumber)
                ? _selectedNumber
                : null,
            isExpanded: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
            items: _verifiedNumbers.map((VerifiedNumber number) {
              return DropdownMenuItem<VerifiedNumber>(
                value: number,
                child: Text(number.name ?? number.phoneNumber),
              );
            }).toList(),
            onChanged: (VerifiedNumber? newValue) {
              setState(() {
                _selectedNumber = newValue;
              });
            },
          ),
        ],
      );
    }
  }

  Widget _buildReminderNameField() {
    return TextFormField(
      controller: _reminderNameController,
      decoration: const InputDecoration(
        labelText: 'Reminder Name',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.text_fields),
      ),
    );
  }

  Widget _buildFrequencyDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reminder Frequency',
          style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4.0),
        DropdownButtonFormField<String>(
          value: _frequency,
          isExpanded: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          items: _frequencyOptions.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value[0].toUpperCase() + value.substring(1)),
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
      ],
    );
  }

  Widget _buildDayOfWeekDropdown() {
    if (_frequency != 'weekly') return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12.0),
        const Text(
          'Select Day of the Week',
          style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4.0),
        DropdownButtonFormField<String>(
          value: _selectedDayOfWeek,
          isExpanded: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          items: <String>[
            'Monday',
            'Tuesday',
            'Wednesday',
            'Thursday',
            'Friday',
            'Saturday',
            'Sunday'
          ].map((String value) {
            return DropdownMenuItem<String>(
              value: value.substring(0, 3).toLowerCase(),
              child: Text(value),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedDayOfWeek = newValue;
            });
          },
        ),
      ],
    );
  }

  Widget _buildMessageTypeSwitch() {
    return SwitchListTile(
      title: const Text(
        'Use Voice Message',
        style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w600),
      ),
      value: _isVoiceMessage,
      onChanged: (bool value) {
        setState(() {
          _isVoiceMessage = value;
        });
      },
      secondary: Icon(_isVoiceMessage ? Icons.mic : Icons.message),
    );
  }

  Widget _buildVoiceMessageRecorder() {
    if (!_isVoiceMessage) return const SizedBox.shrink();
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: _isRecording ? _stopRecording : _startRecording,
          icon: Icon(_isRecording ? Icons.stop : Icons.mic),
          label: Text(_isRecording ? 'Stop Recording' : 'Start Recording'),
          style: ElevatedButton.styleFrom(
            padding:
                const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        ),
        if (_recordedFilePath != null && !_isRecording)
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Text(
              'Recording saved successfully!',
              style: TextStyle(color: Colors.green),
            ),
          ),
      ],
    );
  }

  Widget _buildTextMessageField() {
    if (_isVoiceMessage) return const SizedBox.shrink();
    return TextFormField(
      controller: _messageController,
      decoration: const InputDecoration(
        labelText: 'Text Message',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.message),
      ),
      maxLines: 3,
    );
  }

  Widget _buildTimePicker() {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.access_time),
      title: Text(
        _selectedTime == null
            ? 'Select Time'
            : 'Selected Time: ${_selectedTime!.format(context)}',
        style: const TextStyle(fontSize: 16.0),
      ),
      onTap: _pickTime,
    );
  }

  Widget _buildAddReminderButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed:
            _isSubmitting ? null : addReminder, // Disable when submitting
        child: _isSubmitting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text('Add Reminder'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Reminder'),
        centerTitle: true,
      ),
      drawer: const DrawerMenu(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 24.0),
                child: _verifiedNumbers.isEmpty
                    ? _buildVerifiedNumbersDropdown()
                    : Form(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildVerifiedNumbersDropdown(),
                            const SizedBox(height: 16.0),
                            _buildReminderNameField(),
                            const SizedBox(height: 16.0),
                            _buildFrequencyDropdown(),
                            _buildDayOfWeekDropdown(),
                            const SizedBox(height: 16.0),
                            _buildMessageTypeSwitch(),
                            if (_isVoiceMessage)
                              _buildVoiceMessageRecorder()
                            else
                              _buildTextMessageField(),
                            const SizedBox(height: 16.0),
                            _buildTimePicker(),
                            const SizedBox(height: 24.0),
                            _buildAddReminderButton(),
                          ],
                        ),
                      ),
              ),
            ),
    );
  }
}
