import 'package:flutter/material.dart';
import 'api_service.dart';
import 'drawer_menu.dart';
import 'new_reminder_screen.dart';

class PhoneVerificationScreen extends StatefulWidget {
  const PhoneVerificationScreen({super.key});

  @override
  _PhoneVerificationScreenState createState() =>
      _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  final ApiService apiService = ApiService(); // Initialize the ApiService
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController =
      TextEditingController(); // Controller for name
  final TextEditingController _codeController = TextEditingController();
  bool _codeSent = false;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>(); // Form key for validation
  final FocusNode _codeControllerFocusNode =
      FocusNode(); // Focus node for code field

  void sendCode() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
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
    if (_codeController.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please enter the code')));
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await apiService.checkVerificationCode(
          _phoneController.text,
          _codeController.text,
          _nameController.text.trim());
      setState(() {
        _isLoading = false;
      });
      if (response['status'] == 'verified') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Phone number verified successfully')));
        Navigator.of(context).pop(); // Go back to the previous screen
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Invalid verification code. Please try again.')));
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error verifying code: $e')));
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _codeController.dispose();
    _codeControllerFocusNode.dispose();
    super.dispose();
  }

  Widget _buildPhoneInput() {
    return TextFormField(
      controller: _phoneController,
      decoration: InputDecoration(
        labelText: 'Phone Number',
        prefixIcon: const Icon(Icons.phone),
      ),
      keyboardType: TextInputType.phone,
      style: const TextStyle(fontSize: 16.0),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a phone number';
        } else if (!RegExp(r'^\+\d{1,3}\d{4,14}(?:x.+)?$').hasMatch(value)) {
          return 'Please enter a valid phone number with country code';
        }
        return null;
      },
      enabled: !_codeSent, // Disable when code is sent
    );
  }

  Widget _buildNameInput() {
    return TextFormField(
      controller: _nameController,
      decoration: InputDecoration(
        labelText: 'Name',
        prefixIcon: const Icon(Icons.person),
      ),
      keyboardType: TextInputType.text,
      style: const TextStyle(fontSize: 16.0),
      enabled: !_codeSent, // Disable when code is sent
    );
  }

  Widget _buildCodeInput() {
    return TextFormField(
      controller: _codeController,
      focusNode: _codeControllerFocusNode, // Set the focus node
      decoration: InputDecoration(
        labelText: 'Verification Code',
        prefixIcon: const Icon(Icons.lock),
      ),
      keyboardType: TextInputType.number,
      style: const TextStyle(fontSize: 16.0),
    );
  }

  Widget _buildSendCodeButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : sendCode,
      child: _isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Text('Send Code'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
      ),
    );
  }

  Widget _buildVerifyCodeButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : verifyCode,
      child: _isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Text('Verify Code'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Phone Number'),
        centerTitle: true,
      ),
      drawer: const DrawerMenu(), // Ensure this is correctly implemented
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Form(
            key: _formKey, // Attach the form key
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    'Verify a Phone Number',
                    style: TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                const SizedBox(height: 24.0),
                Text(
                  'Please enter the phone number you want to send reminders to, including the country code (e.g., +1 for USA).',
                  style: TextStyle(
                    fontSize: 16.0,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 24.0),
                _buildPhoneInput(),
                const SizedBox(height: 16.0),
                _buildNameInput(),
                if (_codeSent) ...[
                  const SizedBox(height: 16.0),
                  _buildCodeInput(),
                ],
                const SizedBox(height: 32.0),
                SizedBox(
                  width: double.infinity,
                  child: _codeSent
                      ? _buildVerifyCodeButton()
                      : _buildSendCodeButton(),
                ),
                if (_codeSent)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _codeSent = false;
                        _codeController.clear();
                      });
                    },
                    child: const Text('Edit Phone Number'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
