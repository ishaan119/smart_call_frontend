import 'package:flutter/material.dart';
import 'api_service.dart';
import 'drawer_menu.dart';

class PhoneVerificationScreen extends StatefulWidget {
  @override
  _PhoneVerificationScreenState createState() =>
      _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  final ApiService apiService = ApiService(); // Initialize the ApiService
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  bool _codeSent = false;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>(); // Form key for validation

  void sendCode() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        final response =
            await apiService.sendVerificationCode(_phoneController.text);
        setState(() {
          _codeSent = true;
          _isLoading = false;
        });
        FocusScope.of(context)
            .requestFocus(_codeControllerFocusNode); // Focus on the code field
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error sending verification code: $e')));
      }
    }
  }

  void verifyCode() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await apiService.checkVerificationCode(
          _phoneController.text, _codeController.text);
      setState(() {
        _isLoading = false;
      });
      if (response['status'] == 'verified') {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Phone number verified successfully')));
        Navigator.pushReplacementNamed(
            context, '/new_reminder'); // Navigate to new reminder screen
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to verify phone number')));
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error verifying code: $e')));
    }
  }

  final FocusNode _codeControllerFocusNode =
      FocusNode(); // Focus node for code field

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Phone Verification',
            style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold)),
      ),
      drawer: DrawerMenu(), // Ensure this is correctly implemented
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Form(
              key: _formKey, // Attach the form key
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Verify Your Phone Number',
                    style: TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24.0),
                  Text(
                    'Please enter your phone number with the country code (e.g., +91 for India).',
                    style: TextStyle(
                      fontSize: 16.0,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 16.0),
                  TextFormField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      labelStyle: TextStyle(color: Colors.blueGrey),
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                          vertical: 20.0, horizontal: 16.0),
                    ),
                    keyboardType: TextInputType.phone,
                    style: TextStyle(fontSize: 16.0),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a phone number';
                      } else if (!RegExp(r'^\+\d{1,3}\d{4,14}(?:x.+)?$')
                          .hasMatch(value)) {
                        return 'Please enter a valid phone number with country code';
                      }
                      return null;
                    },
                    enabled: !_codeSent, // Disable when code is sent
                  ),
                  if (_codeSent) ...[
                    SizedBox(height: 16.0),
                    TextFormField(
                      controller: _codeController,
                      focusNode: _codeControllerFocusNode, // Set the focus node
                      decoration: InputDecoration(
                        labelText: 'Verification Code',
                        labelStyle: TextStyle(color: Colors.blueGrey),
                        filled: true,
                        fillColor: Colors.grey[200],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                            vertical: 20.0, horizontal: 16.0),
                      ),
                      keyboardType: TextInputType.number,
                      style: TextStyle(fontSize: 16.0),
                    ),
                  ],
                  SizedBox(height: 32.0),
                  Center(
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : (_codeSent ? verifyCode : sendCode),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        padding: EdgeInsets.symmetric(
                            vertical: 16.0, horizontal: 64.0),
                        elevation: 3, // Adds a subtle shadow
                      ),
                      child: _isLoading
                          ? CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            )
                          : Text(
                              _codeSent ? 'Verify Code' : 'Send Code',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
