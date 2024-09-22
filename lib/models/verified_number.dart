// models/verified_number.dart

class VerifiedNumber {
  final int id;
  final String phoneNumber;
  final String? name;

  VerifiedNumber({
    required this.id,
    required this.phoneNumber,
    this.name,
  });

  // Factory method to create a VerifiedNumber from JSON
  factory VerifiedNumber.fromJson(Map<String, dynamic> json) {
    return VerifiedNumber(
      id: json['id'],
      phoneNumber: json['phone_number'],
      name: json['name'],
    );
  }

  // Method to convert VerifiedNumber to JSON (if needed)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone_number': phoneNumber,
      'name': name,
    };
  }
}
