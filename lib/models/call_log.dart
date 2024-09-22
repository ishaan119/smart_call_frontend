class CallLog {
  final int id;
  final int reminderId;
  final String to;
  final String callSid;
  final String status;
  final String timestamp;
  final String? reminderName; // Optional reminder name

  CallLog({
    required this.id,
    required this.reminderId,
    required this.to,
    required this.callSid,
    required this.status,
    required this.timestamp,
    this.reminderName,
  });

  factory CallLog.fromJson(Map<String, dynamic> json) {
    return CallLog(
      id: json['id'],
      reminderId: json['reminder_id'],
      to: json['to'],
      callSid: json['call_sid'],
      status: json['status'],
      timestamp: json['timestamp'],
      reminderName: json['reminder_name'], // Parse the reminder name
    );
  }
}
