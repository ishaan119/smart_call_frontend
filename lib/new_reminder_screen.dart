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
import 'package:intl/intl.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart'
    as dtp;
import 'models/verified_number.dart';

class NewReminderScreen extends StatefulWidget {
  const NewReminderScreen({super.key});

  @override
  _NewReminderScreenState createState() => _NewReminderScreenState();
}

class _NewReminderScreenState extends State<NewReminderScreen> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _reminderNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDateTime;
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
  FlutterSoundPlayer? _audioPlayer;
  String? _recordedFilePath;

  @override
  void initState() {
    super.initState();
    fetchVerifiedNumbers();
    _audioRecorder = FlutterSoundRecorder();
    _audioPlayer = FlutterSoundPlayer();
    _initializeRecorder();
  }

  Future<void> fetchVerifiedNumbers() async {
    try {
      List<VerifiedNumber> numbers = await apiService.getVerifiedNumbers();

      setState(() {
        _verifiedNumbers = numbers;
        _selectedNumber =
            _verifiedNumbers.isNotEmpty ? _verifiedNumbers[0] : null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      showCustomSnackBar('Error fetching verified numbers: $e',
          color: Colors.red);
    }
  }

  Future<void> _initializeRecorder() async {
    var status = await Permission.microphone.request();
    if (!status.isGranted) {
      showCustomSnackBar('Microphone permission is required',
          color: Colors.red);
      return;
    }
    await _audioRecorder!.openRecorder();
    await _audioPlayer!.openPlayer();
  }

  Future<void> _startRecording() async {
    final directory = await getApplicationDocumentsDirectory();
    String filePath =
        '${directory.path}/recorded_voice_${const Uuid().v4()}.wav';

    if (_audioRecorder != null) {
      await _audioRecorder!
          .startRecorder(toFile: filePath, codec: Codec.pcm16WAV);
      setState(() {
        _isRecording = true;
        _recordedFilePath = filePath;
        _updateButtonState();
      });
    }
  }

  Future<void> _stopRecording() async {
    if (_audioRecorder != null) {
      await _audioRecorder!.stopRecorder();
      setState(() {
        _isRecording = false;
        _updateButtonState();
      });
    }
  }

  Future<void> _playRecording() async {
    if (_recordedFilePath != null) {
      await _audioPlayer!.startPlayer(fromURI: _recordedFilePath);
    }
  }

  Future<void> _pickDateTime() async {
    if (_frequency == 'one-time') {
      dtp.DatePicker.showDateTimePicker(
        context,
        theme: const dtp.DatePickerTheme(
          backgroundColor: Colors.white,
          itemStyle: TextStyle(color: Colors.black),
          doneStyle: TextStyle(color: Colors.teal),
          cancelStyle: TextStyle(color: Colors.red),
        ),
        onConfirm: (date) {
          setState(() {
            _selectedDateTime = date;
            _updateButtonState();
          });
        },
        minTime: DateTime.now(),
        currentTime: DateTime.now(),
      );
    } else {
      dtp.DatePicker.showTimePicker(
        context,
        theme: const dtp.DatePickerTheme(
          backgroundColor: Colors.white,
          itemStyle: TextStyle(color: Colors.black),
          doneStyle: TextStyle(color: Colors.teal),
          cancelStyle: TextStyle(color: Colors.red),
        ),
        onConfirm: (time) {
          final now = DateTime.now();
          setState(() {
            _selectedDateTime =
                DateTime(now.year, now.month, now.day, time.hour, time.minute);
            _updateButtonState();
          });
        },
        currentTime: DateTime.now(),
      );
    }
  }

  Future<void> addReminder() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedNumber == null ||
        _selectedDateTime == null ||
        (_isVoiceMessage && _recordedFilePath == null) ||
        (!_isVoiceMessage && _messageController.text.isEmpty)) {
      showCustomSnackBar('Please fill in all required fields',
          color: Colors.red);
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    String formattedDateTime =
        DateFormat('yyyy-MM-dd HH:mm:ss').format(_selectedDateTime!);

    try {
      if (_isVoiceMessage && _recordedFilePath != null) {
        File recordedFile = File(_recordedFilePath!);
        String voiceUrl = await apiService.uploadVoiceFile(recordedFile);
        await apiService.scheduleVoiceCall(
          _selectedNumber!.phoneNumber,
          voiceUrl,
          formattedDateTime,
          _frequency,
          _selectedDayOfWeek,
          _reminderNameController.text,
        );
      } else {
        await apiService.scheduleCall(
          _selectedNumber!.phoneNumber,
          _messageController.text,
          formattedDateTime,
          _frequency,
          _selectedDayOfWeek,
          _reminderNameController.text,
        );
      }

      showCustomSnackBar('Reminder added successfully', color: Colors.green);
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (context) => const RemindersScreen()));
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      showCustomSnackBar('Error: $e', color: Colors.red);
    }
  }

  void _updateButtonState() {
    setState(() {});
  }

  bool _isAddReminderButtonEnabled() {
    return _selectedNumber != null &&
        _reminderNameController.text.isNotEmpty &&
        _selectedDateTime != null &&
        (_isVoiceMessage
            ? _recordedFilePath != null
            : _messageController.text.isNotEmpty);
  }

  @override
  void dispose() {
    _audioRecorder?.closeRecorder();
    _audioPlayer?.closePlayer();
    _audioRecorder = null;
    _audioPlayer = null;
    _messageController.dispose();
    _reminderNameController.dispose();
    super.dispose();
  }

  Widget _buildVerifiedNumbersDropdown() {
    if (_verifiedNumbers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No verified phone numbers available.',
                style: TextStyle(fontSize: 18.0, color: Colors.redAccent),
                textAlign: TextAlign.center),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const PhoneVerificationScreen()))
                    .then((_) => fetchVerifiedNumbers());
              },
              child: const Text('Verify Phone Number'),
            ),
          ],
        ),
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select Contact',
              style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4.0),
          DropdownButtonFormField<VerifiedNumber>(
            value: _selectedNumber,
            isExpanded: true,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: _verifiedNumbers.map((VerifiedNumber number) {
              return DropdownMenuItem<VerifiedNumber>(
                  value: number,
                  child: Text(number.name ?? number.phoneNumber));
            }).toList(),
            onChanged: (VerifiedNumber? newValue) {
              setState(() {
                _selectedNumber = newValue;
                _updateButtonState();
              });
            },
            validator: (value) =>
                value == null ? 'Please select a contact' : null,
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
          prefixIcon: Icon(Icons.text_fields)),
      validator: (value) => value == null || value.isEmpty
          ? 'Please enter a reminder name'
          : null,
      onChanged: (_) => _updateButtonState(),
    );
  }

  Widget _buildFrequencyDropdown() {
    return DropdownButtonFormField<String>(
      value: _frequency,
      isExpanded: true,
      decoration: const InputDecoration(border: OutlineInputBorder()),
      items: _frequencyOptions.map((String value) {
        return DropdownMenuItem<String>(
            value: value,
            child: Text(value[0].toUpperCase() + value.substring(1)));
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _frequency = newValue!;
          _selectedDayOfWeek = null;
        });
        _updateButtonState();
      },
    );
  }

  Widget _buildTimePicker() {
    return ListTile(
      leading: const Icon(Icons.access_time),
      title: Text(
        _selectedDateTime == null
            ? 'Select Time'
            : _frequency == 'one-time'
                ? 'Selected: ${DateFormat('MMM d, yyyy – h:mm a').format(_selectedDateTime!)}'
                : 'Selected: ${DateFormat('h:mm a').format(_selectedDateTime!)}',
        style: const TextStyle(fontSize: 16.0),
      ),
      onTap: _pickDateTime,
    );
  }

  Widget _buildMessageTypeSwitch() {
    return SwitchListTile(
      title: const Text('Use Voice Message',
          style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w600)),
      value: _isVoiceMessage,
      onChanged: (bool value) {
        setState(() {
          _isVoiceMessage = value;
        });
        _updateButtonState();
      },
    );
  }

  Widget _buildVoiceMessageRecorder() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: _isRecording ? _stopRecording : _startRecording,
              icon: Icon(_isRecording ? Icons.stop : Icons.mic),
              label: Text(_isRecording ? 'Stop Recording' : 'Start Recording'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: _isRecording ? Colors.red : Colors.blue),
            ),
            if (_recordedFilePath != null && !_isRecording)
              IconButton(
                onPressed: _playRecording,
                icon: const Icon(Icons.play_arrow),
                color: Colors.teal,
                iconSize: 40.0,
              ),
          ],
        ),
        if (_recordedFilePath != null && !_isRecording)
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Text('Recording saved successfully!',
                style: TextStyle(color: Colors.green)),
          ),
        if (_isRecording)
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Text('Recording in progress...',
                style: TextStyle(color: Colors.red)),
          ),
      ],
    );
  }

  Widget _buildTextMessageField() {
    return TextFormField(
      controller: _messageController,
      decoration: const InputDecoration(
          labelText: 'Text Message',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.message)),
      maxLines: 3,
      validator: (value) => _isVoiceMessage
          ? null
          : (value == null || value.isEmpty
              ? 'Please enter a text message'
              : null),
      onChanged: (_) => _updateButtonState(),
    );
  }

  Widget _buildAddReminderButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isAddReminderButtonEnabled() && !_isSubmitting
            ? addReminder
            : null,
        child: _isSubmitting
            ? const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
            : const Text('Add Reminder'),
      ),
    );
  }

  void showCustomSnackBar(String message, {Color? color}) {
    final snackBar =
        SnackBar(content: Text(message), backgroundColor: color ?? Colors.teal);
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Reminder'), centerTitle: true),
      drawer: const DrawerMenu(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildVerifiedNumbersDropdown(),
                      const SizedBox(height: 16.0),
                      _buildReminderNameField(),
                      const SizedBox(height: 16.0),
                      _buildFrequencyDropdown(),
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
