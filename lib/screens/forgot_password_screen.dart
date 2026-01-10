import 'package:flutter/material.dart';
import '../services/api_client.dart';
import 'otp_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _phoneController = TextEditingController();
  final _passController = TextEditingController();
  bool _otpSent = false;

  Future<void> _sendOtp() async {
    if (_phoneController.text.isEmpty) return;
    try {
      await ApiClient.sendOtp(_phoneController.text);
      if (mounted) {
        setState(() => _otpSent = true);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpScreen(
              phone: _phoneController.text,
              onVerified: (otp) => _resetPassword(otp),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _resetPassword(String otp) async {
    // Show dialog to enter new password
    if (!mounted) return;
    final newPass = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('New Password', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: _passController,
          obscureText: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(labelText: 'Enter new password', labelStyle: TextStyle(color: Colors.white70)),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, _passController.text),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (newPass != null && newPass.isNotEmpty) {
      try {
        await ApiClient.resetPassword(_phoneController.text, otp, newPass);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password Reset Successfully')));
          Navigator.popUntil(context, (route) => route.isFirst); // Go back to login
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      appBar: AppBar(
        title: const Text('Forgot Password'),
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text(
              'Enter your phone number to receive an OTP.',
              style: TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone, color: Colors.white54),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _sendOtp,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: const Color(0xFF4F46E5),
              ),
              child: const Text('Send OTP'),
            ),
          ],
        ),
      ),
    );
  }
}
