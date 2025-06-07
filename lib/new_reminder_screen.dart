import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:smart_call_scheduler/contact_selection_dialog.dart';
import 'package:smart_call_scheduler/phone_number_selection_dialog.dart';
import 'dart:io';
import 'dart:async';
import 'api_service.dart';
import 'reminders_screen.dart';
import 'call_logs_screen.dart';
import 'bottom_nav_with_fab.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart'
    as dtp;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:phone_number/phone_number.dart';
import 'package:country_picker/country_picker.dart';
import 'dart:ui' as ui;

class NewReminderScreen extends StatefulWidget {
  const NewReminderScreen({super.key});

  @override
  _NewReminderScreenState createState() => _NewReminderScreenState();
}

class _NewReminderScreenState extends State<NewReminderScreen> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDateTime;
  String _frequency = 'one-time';
  bool _isVoiceMessage = true;
  bool _isRecording = false;
  String? _selectedDayOfWeek;
  bool _isSubmitting = false;

  // Contact selection
  String? _selectedContactName;
  String? _selectedContactNumber;

  // Additional variables for timezone and country code
  String _userTimezone = 'UTC';
  String? _isoCountryCode;

  // Audio recording and playback
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _recordedFilePath;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initializeAudio();
    _getUserTimezone();
    _getDeviceCountryCode();
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _initializeAudio() async {
    // Request microphone permission
    PermissionStatus status = await Permission.microphone.request();

    if (!status.isGranted) {
      showCustomSnackBar('Microphone permission is required to record audio',
          color: Colors.red);
    }

    // Listen to audio player state changes
    _audioPlayer.playerStateStream.listen((state) {
      setState(() {
        _isPlaying = state.playing;
      });
    });
  }

  Future<void> _getDeviceCountryCode() async {
    Locale deviceLocale = ui.window.locale;
    setState(() {
      _isoCountryCode = deviceLocale.countryCode ?? 'US';
    });
  }

  Future<void> _getUserTimezone() async {
    try {
      String timezone = await FlutterTimezone.getLocalTimezone();
      setState(() {
        _userTimezone = timezone;
      });
    } catch (e) {
      setState(() {
        _userTimezone = 'UTC';
      });
    }
  }

  Future<void> _startRecording() async {
    try {
      PermissionStatus status = await Permission.microphone.status;
      if (!status.isGranted) {
        status = await Permission.microphone.request();
        if (!status.isGranted) {
          showCustomSnackBar('Microphone permission denied', color: Colors.red);
          return;
        }
      }

      // Check if recorder is available
      if (await _audioRecorder.hasPermission()) {
        final directory = await getApplicationDocumentsDirectory();
        String filePath =
            '${directory.path}/recorded_voice_${const Uuid().v4()}.m4a';

        await _audioRecorder.start(
          const RecordConfig(),
          path: filePath,
        );

        setState(() {
          _isRecording = true;
          _recordedFilePath = filePath;
        });
      } else {
        showCustomSnackBar('Microphone permission denied', color: Colors.red);
      }
    } catch (e) {
      showCustomSnackBar('Error starting recording: $e', color: Colors.red);
    }
  }

  Future<void> _stopRecording() async {
    try {
      await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
      });
    } catch (e) {
      showCustomSnackBar('Error stopping recording: $e', color: Colors.red);
    }
  }

  Future<void> _playRecording() async {
    if (_recordedFilePath != null && File(_recordedFilePath!).existsSync()) {
      try {
        if (_isPlaying) {
          await _audioPlayer.stop();
        } else {
          await _audioPlayer.setFilePath(_recordedFilePath!);
          await _audioPlayer.play();
        }
      } catch (e) {
        showCustomSnackBar('Error playing recording: $e', color: Colors.red);
      }
    }
  }

  Future<void> _pickDateTime() async {
    if (_frequency == 'one-time') {
      dtp.DatePicker.showDateTimePicker(
        context,
        onConfirm: (date) {
          setState(() {
            _selectedDateTime = date;
          });
        },
        minTime: DateTime.now(),
        currentTime: _selectedDateTime ?? DateTime.now(),
      );
    } else if (_frequency == 'daily' || _frequency == 'weekly') {
      dtp.DatePicker.showTimePicker(
        context,
        onConfirm: (time) {
          final now = DateTime.now();
          setState(() {
            _selectedDateTime = DateTime(
              now.year,
              now.month,
              now.day,
              time.hour,
              time.minute,
            );
          });
        },
        currentTime: _selectedDateTime ?? DateTime.now(),
      );
    }
  }

  final List<String> _frequencyOptions = ['one-time', 'daily', 'weekly'];
  final List<String> _daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  Future<void> _openContactPicker() async {
    try {
      PermissionStatus status = await Permission.contacts.status;
      if (!status.isGranted) {
        status = await Permission.contacts.request();
        if (!status.isGranted) {
          _showContactsPermissionDialog();
          return;
        }
      }

      List<Contact> contacts = await FlutterContacts.getContacts(
          withProperties: true, withPhoto: false);

      if (contacts.isEmpty) {
        showCustomSnackBar('No contacts found.', color: Colors.red);
        return;
      }

      Contact? selectedContact = await showDialog<Contact>(
        context: context,
        builder: (context) => ContactSelectionDialog(contacts: contacts),
      );

      if (selectedContact != null && selectedContact.phones.isNotEmpty) {
        String? selectedPhoneNumber = await showDialog<String>(
          context: context,
          builder: (context) =>
              PhoneNumberSelectionDialog(contact: selectedContact),
        );

        if (selectedPhoneNumber != null && selectedPhoneNumber.isNotEmpty) {
          String contactName = selectedContact.displayName;
          String? formattedNumber =
              await _formatPhoneNumber(selectedPhoneNumber);

          if (formattedNumber != null && formattedNumber.isNotEmpty) {
            setState(() {
              _selectedContactName = contactName;
              _selectedContactNumber = formattedNumber;
              _contactController.text = contactName;
            });
          } else {
            showCustomSnackBar('Failed to format phone number',
                color: Colors.red);
          }
        } else {
          showCustomSnackBar('No phone number selected', color: Colors.red);
        }
      } else {
        showCustomSnackBar('No phone number found for this contact',
            color: Colors.red);
      }
    } catch (e) {
      showCustomSnackBar('Error accessing contacts: $e', color: Colors.red);
    }
  }

  Future<String?> _formatPhoneNumber(String phoneNumber) async {
    try {
      // Clean the phone number
      String cleanedNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      
      // If it already has country code, return as is
      if (cleanedNumber.startsWith('+')) {
        return cleanedNumber;
      }
      
      // Try to parse with phone_number package
      try {
        String isoCode = _isoCountryCode ?? 'US';
        PhoneNumber parsedNumber = await PhoneNumberUtil().parse(cleanedNumber, regionCode: isoCode);
        return parsedNumber.e164;
      } catch (e) {
        // If parsing fails, ask user for country code
        String? selectedIsoCode = await _askUserForCountryCode();
        if (selectedIsoCode != null) {
          try {
            PhoneNumber parsedNumber = await PhoneNumberUtil().parse(cleanedNumber, regionCode: selectedIsoCode);
            return parsedNumber.e164;
          } catch (e) {
            // If still fails, return with default country code
            return '+1$cleanedNumber'; // Default to US
          }
        }
        return null;
      }
    } catch (e) {
      // Fallback: return the number with + if it doesn't have it
      if (!phoneNumber.startsWith('+')) {
        return '+1$phoneNumber'; // Default to US country code
      }
      return phoneNumber;
    }
  }

  Future<String?> _askUserForCountryCode() async {
    Completer<String?> completer = Completer<String?>();
    showCountryPicker(
      context: context,
      showPhoneCode: false,
      onSelect: (Country country) {
        completer.complete(country.countryCode);
      },
    );
    return completer.future;
  }

  bool _isAddReminderButtonEnabled() {
    return _selectedContactNumber != null &&
        _selectedDateTime != null &&
        (_isVoiceMessage
            ? _recordedFilePath != null
            : _messageController.text.isNotEmpty);
  }

  Future<void> addReminder() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isAddReminderButtonEnabled()) {
      showCustomSnackBar('Please fill in all required fields',
          color: Colors.red);
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    DateTime localDateTime = _selectedDateTime!;
    DateTime utcDateTime = localDateTime.toUtc();
    String formattedDateTime =
        DateFormat('yyyy-MM-dd HH:mm:ss').format(utcDateTime);

    try {
      if (_isVoiceMessage && _recordedFilePath != null) {
        File recordedFile = File(_recordedFilePath!);
        String voiceUrl = await ApiService().uploadVoiceFile(recordedFile);
        await ApiService().scheduleVoiceCall(
          _selectedContactNumber!,
          voiceUrl,
          formattedDateTime,
          _frequency,
          _selectedDayOfWeek,
          _selectedContactName!,
          _userTimezone,
          _selectedContactName!,
        );
      } else {
        await ApiService().scheduleCall(
          _selectedContactNumber!,
          _messageController.text,
          formattedDateTime,
          _frequency,
          _selectedDayOfWeek,
          _selectedContactName!,
          _userTimezone,
          _selectedContactName!,
        );
      }
      showCustomSnackBar('Reminder added successfully', color: Colors.green);

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const RemindersScreen()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      showCustomSnackBar('Error: $e', color: Colors.red);
    }
  }

  void showCustomSnackBar(String message, {Color? color}) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: color ?? Colors.blue,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _showContactsPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contacts Permission Required'),
        content: const Text(
            'This app needs access to your contacts to function properly. Please grant contacts permission in the app settings.'),
        actions: [
          TextButton(
            child: const Text('Open Settings'),
            onPressed: () {
              openAppSettings();
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildAddReminderButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isAddReminderButtonEnabled() && !_isSubmitting
            ? addReminder
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0052D4),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          shadowColor: Colors.blueAccent.withOpacity(0.4),
          elevation: 5,
        ),
        child: _isSubmitting
            ? const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
            : const Text('Add Reminder',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildTextField(
      String label, TextEditingController controller, String hintText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            suffixIcon: label == "Select contacts"
                ? IconButton(
                    icon: const Icon(Icons.contact_phone),
                    onPressed: _openContactPicker,
                  )
                : null,
          ),
          readOnly: label == "Select contacts",
          onTap: label == "Select contacts" ? _openContactPicker : null,
        ),
      ],
    );
  }

  Widget _buildFrequencyDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Notify',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
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
          },
        ),
      ],
    );
  }

  Widget _buildDayOfWeekPicker() {
    return _frequency == 'weekly'
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select Day of Week',
                  style:
                      TextStyle(fontSize: 16.0, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4.0),
              DropdownButtonFormField<String>(
                value: _selectedDayOfWeek,
                isExpanded: true,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: _daysOfWeek.map((String day) {
                  return DropdownMenuItem<String>(
                    value: day.substring(0, 3).toLowerCase(),
                    child: Text(day),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedDayOfWeek = newValue;
                  });
                },
                validator: (value) =>
                    value == null ? 'Please select a day of the week' : null,
              ),
            ],
          )
        : Container();
  }

  Widget _buildTimePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Time',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickDateTime,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time,
                    color: Color.fromARGB(255, 112, 18, 18)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedDateTime == null
                        ? 'Select Time'
                        : _frequency == 'one-time'
                            ? DateFormat('dd MMM yyyy, hh:mm a')
                                .format(_selectedDateTime!)
                            : DateFormat('hh:mm a').format(_selectedDateTime!),
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVoiceMessageCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Checkbox(
          value: _isVoiceMessage,
          onChanged: (bool? value) {
            setState(() {
              _isVoiceMessage = value ?? false;
            });
          },
          activeColor: Colors.blue,
        ),
        const Text('Use voice message',
            style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black,
                fontSize: 16)),
      ],
    );
  }

  Widget _buildVoiceMessageRecorder() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _isRecording ? _stopRecording : _startRecording,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue.withOpacity(0.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.2),
                          spreadRadius: 5,
                          blurRadius: 15,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF0052D4),
                    ),
                    child: Icon(_isRecording ? Icons.stop : Icons.mic,
                        size: 36, color: Colors.white),
                  ),
                ],
              ),
            ),
            if (_recordedFilePath != null && !_isRecording)
              IconButton(
                onPressed: _playRecording,
                icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
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
        prefixIcon: Icon(Icons.message),
      ),
      maxLines: 3,
      validator: (value) => _isVoiceMessage
          ? null
          : (value == null || value.isEmpty
              ? 'Please enter a text message'
              : null),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTextField(
                        'Select contacts', _contactController, 'Phone Number'),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildFrequencyDropdown()),
                        const SizedBox(width: 16),
                        Expanded(child: _buildTimePicker()),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildDayOfWeekPicker(),
                    const SizedBox(height: 16),
                    _buildVoiceMessageCheckbox(),
                    const SizedBox(height: 16),
                    _isVoiceMessage
                        ? _buildVoiceMessageRecorder()
                        : _buildTextMessageField(),
                    const SizedBox(height: 24),
                    Center(child: _buildAddReminderButton()),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNavWithFAB(
        currentIndex: 0,
        onTabTapped: (index) {
          if (index == 0) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const RemindersScreen()),
              (Route<dynamic> route) => false,
            );
          }
          if (index == 1) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const CallLogsScreen()),
              (Route<dynamic> route) => false,
            );
          }
        },
      ),
    );
  }
}