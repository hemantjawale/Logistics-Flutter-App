import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_client.dart';
import '../services/user_session.dart';
import '../services/background_service.dart';

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({super.key});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  List<dynamic> _jobs = [];
  bool _isLoading = true;
  String? _driverId;

  @override
  void initState() {
    super.initState();
    _loadJobs();
    // Start background tracking when driver opens dashboard
    BackgroundService.startTracking();
  }

  Future<void> _loadJobs() async {
    final user = await UserSession.getUser();
    if (user == null) return;
    
    _driverId = user['_id'];

    try {
      // Fetch all shipments so driver can pick up unassigned ones for demo purposes
      // In production, this should be 'Pending' or assigned to me.
      final shipments = await ApiClient.fetchShipments(); 
      setState(() {
        _jobs = shipments;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // Show error
      }
    }
  }

  Future<void> _startJob(String shipmentId) async {
    try {
      await ApiClient.updateShipment(shipmentId, {'status': 'In Transit'});
      _loadJobs();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Job Started!')));
      }
    } catch (e) {
       // Handle error
    }
  }

  Future<void> _completeJob(String shipmentId) async {
    // 1. Request OTP
    try {
      await ApiClient.requestDeliveryOtp(shipmentId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OTP sent to Customer')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send OTP: $e')));
      }
      return; // Stop if OTP failed
    }

    // 2. Show Dialog to enter OTP
    if (!mounted) return;
    final otpController = TextEditingController();
    final otp = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter Delivery OTP'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ask customer for the OTP sent to their mobile.'),
            const SizedBox(height: 10),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'OTP',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, otpController.text),
            child: const Text('Verify & Complete'),
          ),
        ],
      ),
    );

    if (otp == null || otp.isEmpty) return;

    // 3. Verify OTP and Complete
    try {
      await ApiClient.completeDeliveryWithOtp(shipmentId, otp);
      _loadJobs();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Job Completed Successfully!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Verification Failed: $e')));
      }
    }
  }

  Future<void> _launchMap(String destination) async {
    // Assuming destination is a string address or "lat,lng"
    // For demo, we'll use a generic query
    final Uri url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(destination)}');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Dashboard'),
        backgroundColor: Colors.transparent,
      ),
      body: _jobs.isEmpty 
          ? const Center(child: Text('No assigned jobs'))
          : ListView.builder(
              itemCount: _jobs.length,
              itemBuilder: (context, index) {
                final job = _jobs[index];
                final isStarted = job['status'] == 'In Transit';
                
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Shipment #${job['trackingNumber']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 8),
                        Text('Destination: ${job['destination']}'),
                        Text('Status: ${job['status']}'),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            if (!isStarted)
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: () => _startJob(job['_id']),
                                  icon: const Icon(Icons.play_arrow),
                                  label: const Text('Start Job'),
                                ),
                              )
                            else
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: () => _completeJob(job['_id']),
                                  icon: const Icon(Icons.check),
                                  label: const Text('Complete Job'),
                                  style: FilledButton.styleFrom(backgroundColor: Colors.green),
                                ),
                              ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _launchMap(job['destination']),
                                icon: const Icon(Icons.map),
                                label: const Text('Navigate'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
