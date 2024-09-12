import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as path; // For manipulating file paths
import 'package:uuid/uuid.dart'; // For generating a unique identifier

class ApiService {
  final String baseUrl = 'https://48b4-202-134-174-111.ngrok-free.app';
  final _storage = const FlutterSecureStorage(); // Secure storage for device_id

  // Method to get or generate a device_id
  Future<String> _getDeviceId() async {
    String? deviceId = await _storage.read(key: 'device_id');
    if (deviceId == null) {
      // Generate a unique device_id based on the current timestamp or any other method
      deviceId = DateTime.now().millisecondsSinceEpoch.toString();
      await _storage.write(key: 'device_id', value: deviceId);
    }
    return deviceId;
  }

  // Method to upload a voice file and get the file URL
  Future<String> uploadVoiceFile(File voiceFile) async {
    // Get the original file extension
    String fileExtension = path.extension(voiceFile.path);

    // Create a unique filename by appending a UUID or timestamp
    String uniqueFileName = 'voice_${Uuid().v4()}$fileExtension';
    var request =
        http.MultipartRequest('POST', Uri.parse('$baseUrl/upload_voice'));
    // Add the file to the request with the unique filename
    request.files.add(await http.MultipartFile.fromPath('file', voiceFile.path,
        filename: uniqueFileName // Assign unique filename
        ));
    var response = await request.send();

    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      final data = jsonDecode(responseBody);
      return data['file_url']; // Return the file URL
    } else {
      throw Exception('Failed to upload voice file');
    }
  }

  // Schedule a voice call with a recorded voice URL
  Future<Map<String, dynamic>> scheduleVoiceCall(String to, String voiceUrl,
      String time, String frequency, String? dayOfWeek, String? name) async {
    final deviceId = await _getDeviceId();
    final response = await http.post(
      Uri.parse('$baseUrl/schedule_call'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8'
      },
      body: jsonEncode({
        'to': to,
        'voice_url': voiceUrl,
        'time': time,
        'frequency': frequency,
        'day_of_week': dayOfWeek,
        'device_id': deviceId,
        'name': name,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to schedule voice reminder: ${response.body}');
    }
  }

  // Method to send a verification code to a phone number
  Future<Map<String, dynamic>> sendVerificationCode(String phoneNumber) async {
    final deviceId = await _getDeviceId(); // Get device_id
    final response = await http.post(
      Uri.parse('$baseUrl/send_verification_code'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'phone_number': phoneNumber,
        'device_id': deviceId, // Send device_id along with the request
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to send verification code: ${response.body}');
    }
  }

  // Method to check if the verification code is correct
  Future<Map<String, dynamic>> checkVerificationCode(
      String phoneNumber, String code) async {
    final deviceId = await _getDeviceId(); // Get device_id
    final response = await http.post(
      Uri.parse('$baseUrl/check_verification_code'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'phone_number': phoneNumber,
        'code': code,
        'device_id': deviceId, // Send device_id along with the request
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to verify code: ${response.body}');
    }
  }

  // Method to schedule a one-time or recurring call (daily or weekly)
  Future<Map<String, dynamic>> scheduleCall(String to, String message,
      String time, String frequency, String? dayOfWeek, String? name) async {
    final deviceId = await _getDeviceId(); // Get device_id
    final response = await http.post(
      Uri.parse('$baseUrl/schedule_call'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'to': to,
        'message': message,
        'time': time,
        'frequency': frequency,
        'day_of_week': dayOfWeek,
        'device_id': deviceId, // Include device_id in the request
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to schedule reminder: ${response.body}');
    }
  }

  // Method to schedule a recurring call using a cron expression
  Future<Map<String, dynamic>> scheduleRecurringCall(String to, String message,
      String scheduleType, String scheduleValue) async {
    final deviceId = await _getDeviceId(); // Get device_id
    final response = await http.post(
      Uri.parse('$baseUrl/schedule_recurring_call'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'to': to,
        'message': message,
        'schedule_type': scheduleType,
        'schedule_value': scheduleValue,
        'device_id': deviceId, // Include device_id in the request
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to schedule recurring call: ${response.body}');
    }
  }

  // Method to fetch all reminders associated with a specific device_id
  Future<List<dynamic>> getReminders() async {
    final deviceId = await _getDeviceId(); // Get device_id
    final response =
        await http.get(Uri.parse('$baseUrl/reminders?device_id=$deviceId'));

    if (response.statusCode == 200) {
      print(jsonDecode(response.body));
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch reminders: ${response.body}');
    }
  }

  // Method to delete a specific reminder by ID
  Future<void> deleteReminder(int id) async {
    final response =
        await http.delete(Uri.parse('$baseUrl/delete_reminder/$id'));

    if (response.statusCode != 200) {
      throw Exception('Failed to delete reminder: ${response.body}');
    }
  }

  // Method to fetch all verified numbers associated with the device_id
  Future<List<Map<String, dynamic>>> getVerifiedNumbers() async {
    final deviceId = await _getDeviceId(); // Get device_id
    final response = await http
        .get(Uri.parse('$baseUrl/get_verified_numbers?device_id=$deviceId'));

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body
          .map((item) =>
              {'id': item['id'], 'phone_number': item['phone_number']})
          .toList();
    } else {
      throw Exception('Failed to load verified numbers: ${response.body}');
    }
  }

  // Method to delete a verified number by its ID
  Future<void> deleteVerifiedNumber(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/delete_verified_number/$id'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete verified number: ${response.body}');
    }
  }

  // Method to add a verified number, associated with the device_id
  Future<Map<String, dynamic>> addVerifiedNumber(String phoneNumber) async {
    final deviceId = await _getDeviceId(); // Get device_id
    final response = await http.post(
      Uri.parse('$baseUrl/add_verified_number'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'phone_number': phoneNumber,
        'device_id': deviceId, // Associate the number with the device
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to add verified number: ${response.body}');
    }
  }
}
