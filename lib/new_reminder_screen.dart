// new_reminder_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:async';
import 'api_service.dart';
import 'reminders_screen.dart';
import 'drawer_menu.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart'
    as dtp;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:phone_number/phone_number.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:country_picker/country_picker.dart'; // Import the country_picker package
import 'dart:ui' as ui; // Import dart:ui for accessing the device locale

class NewReminderScreen extends StatefulWidget {
  const NewReminderScreen({Key? key}) : super(key: key);

  @override
  _NewReminderScreenState createState() => _NewReminderScreenState();
}

class _NewReminderScreenState extends State<NewReminderScreen> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _reminderNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDateTime;
  final ApiService apiService = ApiService();
  String _frequency = 'one-time'; // Default to 'one-time'
  String? _selectedDayOfWeek;
  bool _isVoiceMessage = true; // Default to voice message
  bool _isRecording = false;
  bool _isSubmitting = false; // Flag to disable the button after first press

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

  FlutterSoundRecorder? _audioRecorder;
  FlutterSoundPlayer? _audioPlayer;
  String? _recordedFilePath;
  String _userTimezone = 'UTC'; // Default timezone
  String? _selectedContactName;
  String? _selectedContactNumber;
  String? _isoCountryCode; // Variable to store the device's country code

  final PhoneNumberUtil _phoneNumberUtil = PhoneNumberUtil();

  @override
  void initState() {
    super.initState();
    _audioRecorder = FlutterSoundRecorder();
    _audioPlayer = FlutterSoundPlayer();
    _initializeRecorder();
    _getUserTimezone();
    _getDeviceCountryCode(); // Get the device's country code
  }

  void _getDeviceCountryCode() {
    Locale deviceLocale = ui.window.locale;
    setState(() {
      _isoCountryCode =
          deviceLocale.countryCode ?? 'US'; // Default to 'US' if null
    });
    print('Detected country code: $_isoCountryCode');
  }

  Future<void> _getUserTimezone() async {
    try {
      String timezone = await FlutterTimezone.getLocalTimezone();
      setState(() {
        _userTimezone = timezone;
      });
    } catch (e) {
      print('Could not get the user timezone: $e');
      setState(() {
        _userTimezone = 'UTC';
      });
    }
  }

  Future<void> _initializeRecorder() async {
    try {
      PermissionStatus status = await Permission.microphone.request();
      if (!status.isGranted) {
        showCustomSnackBar('Microphone permission is required',
            color: Colors.red);
        return;
      }
      await _audioRecorder!.openRecorder();
      await _audioPlayer!.openPlayer();
    } catch (e) {
      print('Error initializing recorder: $e');
    }
  }

  Future<void> _startRecording() async {
    try {
      if (!_audioRecorder!.isRecording) {
        final directory = await getApplicationDocumentsDirectory();
        String filePath =
            '${directory.path}/recorded_voice_${const Uuid().v4()}.wav';

        if (_audioRecorder != null) {
          await _audioRecorder!.startRecorder(
            toFile: filePath,
            codec: Codec.pcm16WAV,
          );
          setState(() {
            _isRecording = true;
            _recordedFilePath = filePath;
            _updateButtonState();
          });
        }
      }
    } catch (e) {
      print('Error starting recorder: $e');
      showCustomSnackBar('Error starting recorder: $e', color: Colors.red);
    }
  }

  Future<void> _stopRecording() async {
    try {
      if (_audioRecorder != null && _audioRecorder!.isRecording) {
        await _audioRecorder!.stopRecorder();
        setState(() {
          _isRecording = false;
          _updateButtonState();
        });
      }
    } catch (e) {
      print('Error stopping recorder: $e');
      showCustomSnackBar('Error stopping recorder: $e', color: Colors.red);
    }
  }

  Future<void> _playRecording() async {
    try {
      if (_recordedFilePath != null) {
        await _audioPlayer!.startPlayer(fromURI: _recordedFilePath);
      }
    } catch (e) {
      print('Error playing recording: $e');
      showCustomSnackBar('Error playing recording: $e', color: Colors.red);
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
      // For 'daily' and 'weekly', only time picker is needed
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
            _selectedDateTime = DateTime(
              now.year,
              now.month,
              now.day,
              time.hour,
              time.minute,
            );
            _updateButtonState();
          });
        },
        currentTime: DateTime.now(),
      );
    }
  }

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
        withProperties: true,
        withPhoto: false,
      );

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
          builder: (context) => PhoneNumberSelectionDialog(
            contact: selectedContact,
          ),
        );

        if (selectedPhoneNumber != null && selectedPhoneNumber.isNotEmpty) {
          String contactName = selectedContact.displayName;

          // Normalize the phone number
          String? formattedNumber =
              await _formatPhoneNumber(selectedPhoneNumber);

          if (formattedNumber != null && formattedNumber.isNotEmpty) {
            setState(() {
              _selectedContactName = contactName;
              _selectedContactNumber = formattedNumber;
              _updateButtonState();
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
      print('Error accessing contacts: $e');
      showCustomSnackBar('Error accessing contacts: $e', color: Colors.red);
    }
  }

  void _showContactsPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contacts Permission Required'),
        content: const Text(
          'This app needs access to your contacts to function properly. '
          'Please grant contacts permission in the app settings.',
        ),
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

  Future<String?> _formatPhoneNumber(String phoneNumber) async {
    try {
      print('Original phone number: $phoneNumber');

      // Remove all non-digit characters except '+'
      String cleanedNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      print('Cleaned phone number: $cleanedNumber');

      PhoneNumber parsedNumber;

      if (cleanedNumber.startsWith('+')) {
        // International format, parse without region code
        parsedNumber = await _phoneNumberUtil.parse(cleanedNumber);
      } else {
        // Local format, parse with device's country code
        String isoCode = _isoCountryCode ?? 'US';
        try {
          parsedNumber = await _phoneNumberUtil.parse(
            cleanedNumber,
            regionCode: isoCode,
          );
        } catch (e) {
          print('Parsing with device country code failed: $e');

          // Parsing failed, ask user to select country code
          String? selectedIsoCode = await _askUserForCountryCode();

          if (selectedIsoCode != null) {
            parsedNumber = await _phoneNumberUtil.parse(
              cleanedNumber,
              regionCode: selectedIsoCode,
            );
          } else {
            // User did not select a country code
            return null;
          }
        }
      }

      if (parsedNumber.e164 != null) {
        print('Formatted number (E.164): ${parsedNumber.e164}');
        return parsedNumber.e164;
      } else {
        print('Parsed number is invalid');
        return null;
      }
    } catch (e) {
      print('Error formatting phone number: $e');
      return null;
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

  Future<void> addReminder() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedContactNumber == null ||
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

    DateTime localDateTime = _selectedDateTime!;
    DateTime utcDateTime = localDateTime.toUtc();
    String formattedDateTime =
        DateFormat('yyyy-MM-dd HH:mm:ss').format(utcDateTime);

    String userTimezone = _userTimezone;

    try {
      if (_isVoiceMessage && _recordedFilePath != null) {
        File recordedFile = File(_recordedFilePath!);
        String voiceUrl = await apiService.uploadVoiceFile(recordedFile);
        await apiService.scheduleVoiceCall(
          _selectedContactNumber!,
          voiceUrl,
          formattedDateTime,
          _frequency,
          _selectedDayOfWeek,
          _reminderNameController.text,
          userTimezone,
        );
      } else {
        await apiService.scheduleCall(
          _selectedContactNumber!,
          _messageController.text,
          formattedDateTime,
          _frequency,
          _selectedDayOfWeek,
          _reminderNameController.text,
          userTimezone,
        );
      }

      showCustomSnackBar('Reminder added successfully', color: Colors.green);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const RemindersScreen()),
      );
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      print('Error adding reminder: $e');
      showCustomSnackBar('Error: $e', color: Colors.red);
    }
  }

  void _updateButtonState() {
    setState(() {});
  }

  bool _isAddReminderButtonEnabled() {
    return _selectedContactNumber != null &&
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

  Widget _buildContactPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Contact',
          style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4.0),
        GestureDetector(
          onTap: _openContactPicker,
          child: Container(
            padding:
                const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: Text(
              _selectedContactName ?? 'Tap to select a contact',
              style: TextStyle(
                fontSize: 16.0,
                color: _selectedContactName != null
                    ? Colors.black
                    : Colors.grey[600],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReminderNameField() {
    return TextFormField(
      controller: _reminderNameController,
      decoration: const InputDecoration(
        labelText: 'Reminder Name',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.text_fields),
      ),
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
          child: Text(value[0].toUpperCase() + value.substring(1)),
        );
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

  Widget _buildDayOfWeekPicker() {
    return _frequency == 'weekly'
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Day of Week',
                style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w600),
              ),
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
                    _updateButtonState();
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
    String timeText;

    if (_selectedDateTime == null) {
      timeText = 'Select Time';
    } else if (_frequency == 'one-time') {
      timeText =
          'Selected: ${DateFormat('MMM d, yyyy - h:mm a').format(_selectedDateTime!)}';
    } else {
      timeText = 'Selected: ${DateFormat('h:mm a').format(_selectedDateTime!)}';
    }

    return ListTile(
      leading: const Icon(Icons.access_time),
      title: Text(
        timeText,
        style: const TextStyle(fontSize: 16.0),
      ),
      onTap: _pickDateTime,
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
                backgroundColor: _isRecording ? Colors.red : Colors.blue,
              ),
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
            child: Text(
              'Recording saved successfully!',
              style: TextStyle(color: Colors.green),
            ),
          ),
        if (_isRecording)
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Text(
              'Recording in progress...',
              style: TextStyle(color: Colors.red),
            ),
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
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              )
            : const Text('Add Reminder'),
      ),
    );
  }

  void showCustomSnackBar(String message, {Color? color}) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: color ?? Colors.teal,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Reminder'), centerTitle: true),
      drawer: const DrawerMenu(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildContactPicker(),
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
                _buildDayOfWeekPicker(),
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

class ContactSelectionDialog extends StatefulWidget {
  final List<Contact> contacts;

  const ContactSelectionDialog({Key? key, required this.contacts})
      : super(key: key);

  @override
  _ContactSelectionDialogState createState() => _ContactSelectionDialogState();
}

class _ContactSelectionDialogState extends State<ContactSelectionDialog> {
  List<Contact> _filteredContacts = [];
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _filteredContacts = widget.contacts;
    _searchController.addListener(_filterContacts);
    _focusNode.requestFocus();
  }

  void _filterContacts() {
    String searchTerm = _searchController.text.toLowerCase();
    setState(() {
      _filteredContacts = widget.contacts.where((contact) {
        return contact.displayName.toLowerCase().contains(searchTerm);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Contact'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400, // Adjust height as needed
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              focusNode: _focusNode,
              decoration: const InputDecoration(
                hintText: 'Search contacts',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _filteredContacts.isNotEmpty
                  ? ListView.builder(
                      itemCount: _filteredContacts.length,
                      itemBuilder: (context, index) {
                        Contact contact = _filteredContacts[index];
                        return ListTile(
                          title: Text(contact.displayName),
                          onTap: () => Navigator.pop(context, contact),
                        );
                      },
                    )
                  : const Center(
                      child: Text('No contacts found.'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class PhoneNumberSelectionDialog extends StatelessWidget {
  final Contact contact;

  const PhoneNumberSelectionDialog({Key? key, required this.contact})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Phone Number'),
      content: SizedBox(
        width: double.maxFinite,
        height: 200, // Adjust height as needed
        child: contact.phones.isNotEmpty
            ? ListView.builder(
                shrinkWrap: true,
                itemCount: contact.phones.length,
                itemBuilder: (context, index) {
                  String phoneNumber = contact.phones[index].number;
                  return ListTile(
                    title: Text(phoneNumber),
                    onTap: () => Navigator.pop(context, phoneNumber),
                  );
                },
              )
            : const Center(
                child: Text('No phone numbers available for this contact.'),
              ),
      ),
    );
  }
}
