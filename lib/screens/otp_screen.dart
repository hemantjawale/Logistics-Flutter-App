import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import '../services/api_client.dart';

class OtpScreen extends StatefulWidget {
  final String phone;
  final Function(String otp) onVerified;

  const OtpScreen({super.key, required this.phone, required this.onVerified});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;

  Future<void> _verify() async {
    final otp = _otpController.text;
    if (otp.length != 6) return;
    
    // In a real flow, we might verify OTP with backend here, 
    // but typically we send it along with the registration data or password reset data.
    // For this flow, we just pass it back to the parent.
    widget.onVerified(otp);
  }

  Future<void> _resend() async {
    setState(() => _isLoading = true);
    try {
      await ApiClient.sendOtp(widget.phone);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OTP Resent')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.w600),
      decoration: BoxDecoration(
        border: Border.all(color: const Color.fromARGB(255, 126, 137, 161)),
        borderRadius: BorderRadius.circular(20),
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      appBar: AppBar(
        title: const Text('Verify Phone'),
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Enter OTP sent to ${widget.phone}', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 30),
            Pinput(
              length: 6,
              controller: _otpController,
              defaultPinTheme: defaultPinTheme,
              focusedPinTheme: defaultPinTheme.copyDecorationWith(
                border: Border.all(color: const Color(0xFF4F46E5)),
                borderRadius: BorderRadius.circular(8),
              ),
              onCompleted: (pin) => _verify(),
            ),
            const SizedBox(height: 30),
            if (_isLoading)
              const CircularProgressIndicator()
            else
              TextButton(
                onPressed: _resend,
                child: const Text('Resend OTP'),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _verify,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: const Color(0xFF4F46E5),
              ),
              child: const Text('Verify'),
            ),
          ],
        ),
      ),
    );
  }
}
