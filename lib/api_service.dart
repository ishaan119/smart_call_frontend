// api_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as path;
import 'package:device_info_plus/device_info_plus.dart';
import 'models/verified_number.dart'; // Assuming you have this model
import 'models/call_log.dart'; // New model for CallLog

class ApiService {
  final String baseUrl = 'https://smartcall.docninja.in';
  final _storage = const FlutterSecureStorage(); // Secure storage for device_id

  // Singleton pattern (optional)
  static final ApiService _instance = ApiService._internal();

  factory ApiService() {
    return _instance;
  }

  ApiService._internal();

  // Method to get or generate a device_id
  Future<String> _getDeviceId() async {
    String? deviceId = await _storage.read(key: 'device_id');
    if (deviceId == null) {
      // Use device_info_plus to get a unique device ID
      final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

      try {
        if (Platform.isAndroid) {
          AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
          // Use the `id` property for Android
          deviceId =
              androidInfo.id; // This should always return a value for Android
        } else if (Platform.isIOS) {
          IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
          // Use `identifierForVendor` for iOS devices
          deviceId = iosInfo
              .identifierForVendor; // This should always return a value for iOS
        } else {
          deviceId = 'unknown'; // Fallback for other platforms
        }

        // Write the deviceId to secure storage
        if (deviceId != null && deviceId.isNotEmpty) {
          await _storage.write(key: 'device_id', value: deviceId);
        } else {
          deviceId = 'unknown'; // Handle case where deviceId is still null
        }
      } catch (e) {
        print('Error getting device ID: $e');
        deviceId = 'unknown'; // Handle errors
      }
    }

    return deviceId;
  }

  // Method to upload a voice file and get the file URL
  Future<String> uploadVoiceFile(File voiceFile) async {
    String fileName = path.basename(voiceFile.path);

    var request =
        http.MultipartRequest('POST', Uri.parse('$baseUrl/upload_voice'));
    request.files.add(await http.MultipartFile.fromPath('file', voiceFile.path,
        filename: fileName));
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
  Future<Map<String, dynamic>> scheduleVoiceCall(
    String to,
    String voiceUrl,
    String time,
    String frequency,
    String? dayOfWeek,
    String? name,
    String timezone,
    String contactName,
  ) async {
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
        'timezone': timezone,
        'contact_name': contactName,
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
    final response = await http.post(
      Uri.parse('$baseUrl/send_verification_code'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'phone_number': phoneNumber,
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
    String phoneNumber,
    String code,
    String? name,
  ) async {
    final deviceId = await _getDeviceId();
    final response = await http.post(
      Uri.parse('$baseUrl/check_verification_code'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'phone_number': phoneNumber,
        'code': code,
        'device_id': deviceId,
        'name': name,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to verify code: ${response.body}');
    }
  }

  // Method to schedule a one-time or recurring call (daily or weekly)
  Future<Map<String, dynamic>> scheduleCall(
    String to,
    String message,
    String time,
    String frequency,
    String? dayOfWeek,
    String? name,
    String timezone,
    String contactName,
  ) async {
    final deviceId = await _getDeviceId();
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
        'device_id': deviceId,
        'name': name,
        'timezone': timezone,
        'contact_name': contactName,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to schedule reminder: ${response.body}');
    }
  }

  // Method to fetch all reminders associated with a specific device_id
  Future<List<dynamic>> getReminders() async {
    final deviceId = await _getDeviceId();
    final response =
        await http.get(Uri.parse('$baseUrl/reminders?device_id=$deviceId'));

    if (response.statusCode == 200) {
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
  Future<List<VerifiedNumber>> getVerifiedNumbers() async {
    final deviceId = await _getDeviceId();
    final response = await http
        .get(Uri.parse('$baseUrl/get_verified_numbers?device_id=$deviceId'));

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      List<VerifiedNumber> numbers =
          body.map((item) => VerifiedNumber.fromJson(item)).toList();
      return numbers;
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
  Future<Map<String, dynamic>> addVerifiedNumber(
    String phoneNumber,
    String? name,
  ) async {
    final deviceId = await _getDeviceId();
    final response = await http.post(
      Uri.parse('$baseUrl/add_verified_number'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'phone_number': phoneNumber,
        'name': name,
        'device_id': deviceId,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to add verified number: ${response.body}');
    }
  }

  // Method to update a verified number's name
  Future<void> updateVerifiedNumber(int id, String name) async {
    final response = await http.put(
      Uri.parse('$baseUrl/update_verified_number/$id'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'name': name,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update verified number: ${response.body}');
    }
  }

  // Method to reschedule a reminder
  Future<void> rescheduleReminder(int id, String newTime) async {
    final response = await http.put(
      Uri.parse('$baseUrl/reschedule_reminder/$id'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'time': newTime,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to reschedule reminder: ${response.body}');
    }
  }

  // Method to update a reminder
  Future<void> updateReminder(int id, Map<String, dynamic> updatedData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/reminders/$id'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(updatedData),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update reminder: ${response.body}');
    }
  }

  // New Method: Fetch Call Logs
  Future<List<CallLog>> getCallLogs() async {
    final deviceId = await _getDeviceId();
    final response =
        await http.get(Uri.parse('$baseUrl/call_logs?device_id=$deviceId'));

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      List<CallLog> callLogs =
          body.map((item) => CallLog.fromJson(item)).toList();
      return callLogs;
    } else {
      throw Exception('Failed to fetch call logs: ${response.body}');
    }
  }

  // Add the method to store FCM token
  Future<void> storeFCMToken(String fcmToken) async {
    final deviceId = await _getDeviceId();
    final response = await http.post(
      Uri.parse('$baseUrl/store_fcm_token'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'fcm_token': fcmToken,
        'device_id': deviceId, // Send the device ID as a reference
      }),
    );

    if (response.statusCode != 200 || response.statusCode != 201) {
      throw Exception('Failed to store FCM token: ${response.body}');
    }
  }
}
