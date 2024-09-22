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
  final ApiService apiService = ApiService();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  bool _codeSent = false;
  bool _isLoading = false;
  bool _isPhoneValid = false;
  bool _isNameValid = false;
  bool _isCodeValid = false;

  final _formKey = GlobalKey<FormState>();
  final FocusNode _codeControllerFocusNode = FocusNode();

  // Regular expression for validating phone numbers with country code
  final RegExp phoneNumberRegEx = RegExp(r'^\+\d{1,3}\d{4,14}(?:x.+)?$');

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
        FocusScope.of(context).requestFocus(_codeControllerFocusNode);
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
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const NewReminderScreen(),
          ),
        );
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

  void _validateInput() {
    setState(() {
      _isPhoneValid = _phoneController.text.isNotEmpty &&
          phoneNumberRegEx.hasMatch(_phoneController
              .text); // Use regular expression to validate phone number
      _isNameValid = _nameController.text.isNotEmpty;
      _isCodeValid = _codeController.text.isNotEmpty;
    });
  }

  Widget _buildPhoneInput() {
    return TextFormField(
      controller: _phoneController,
      decoration: InputDecoration(
        labelText: 'Recipient\'s Phone Number',
        prefixIcon: const Icon(Icons.phone),
        errorText:
            _isPhoneValid ? null : 'Phone number must include country code',
      ),
      keyboardType: TextInputType.phone,
      style: const TextStyle(fontSize: 16.0),
      onChanged: (_) => _validateInput(),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter the recipient\'s phone number';
        } else if (!phoneNumberRegEx.hasMatch(value)) {
          return 'Please enter a valid phone number with country code (e.g., +1234567890)';
        }
        return null;
      },
      enabled: !_codeSent,
    );
  }

  Widget _buildNameInput() {
    return TextFormField(
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: 'Recipient\'s Name',
        prefixIcon: Icon(Icons.person),
      ),
      keyboardType: TextInputType.text,
      style: const TextStyle(fontSize: 16.0),
      onChanged: (_) => _validateInput(),
      enabled: !_codeSent,
    );
  }

  Widget _buildCodeInput() {
    return TextFormField(
      controller: _codeController,
      focusNode: _codeControllerFocusNode,
      decoration: const InputDecoration(
        labelText: 'Verification Code',
        prefixIcon: Icon(Icons.lock),
      ),
      keyboardType: TextInputType.number,
      style: const TextStyle(fontSize: 16.0),
      onChanged: (_) => _validateInput(),
    );
  }

  Widget _buildSendCodeButton() {
    return ElevatedButton(
      onPressed:
          (_isPhoneValid && _isNameValid) && !_isLoading ? sendCode : null,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
      ),
      child: _isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Text('Send Verification Code'),
    );
  }

  Widget _buildVerifyCodeButton() {
    return ElevatedButton(
      onPressed: (_isCodeValid && !_isLoading) ? verifyCode : null,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
      ),
      child: _isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Text('Verify Code'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Phone Number'),
        centerTitle: true,
      ),
      drawer: const DrawerMenu(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    'Verify Reminder Recipient',
                    style: TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                const SizedBox(height: 24.0),
                Text(
                  'To send reminders, you need to verify the recipient’s phone number. Please enter the recipient’s phone number with the country code, along with their name. You can only send reminders to verified numbers.',
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
