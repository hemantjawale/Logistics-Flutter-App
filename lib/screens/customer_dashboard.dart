import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/user_session.dart';
import 'tracking_screen.dart';

class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  List<Map<String, dynamic>> _myShipments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadShipments();
  }

  Future<void> _loadShipments() async {
    try {
      // In real app, backend should filter by customer ID (user ID)
      final shipments = await ApiClient.fetchShipments(); 
      setState(() {
        _myShipments = shipments; // Filter here if needed
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _createShipment(String destination, String category) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final user = await UserSession.getUser();
      await ApiClient.createShipment({
        'destination': destination,
        'category': category,
        'origin': 'Current Location', // In real app, get GPS
        'customerId': user?['_id'],
        'autoAssignDriver': true,
        'status': 'Pending',
        'trackingNumber': 'TRK-${DateTime.now().millisecondsSinceEpoch}', // Mock
      });
      _loadShipments();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Shipment Requested!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showRequestShipmentDialog() {
    final destinationController = TextEditingController();
    String selectedCategory = 'Other';
    final categories = ['Agriculture', 'Textiles', 'Electronics', 'Pharmaceuticals', 'Automotive', 'FMCG', 'Construction', 'Other'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Request New Shipment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Pick your destination:'),
              const SizedBox(height: 10),
              Container(height: 100, color: Colors.grey[800], child: const Center(child: Icon(Icons.map, size: 50, color: Colors.white54))),
              const SizedBox(height: 10),
              TextField(controller: destinationController, decoration: const InputDecoration(labelText: 'Destination Address', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) => setState(() => selectedCategory = val!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(onPressed: () async { if (destinationController.text.isEmpty) return; Navigator.pop(context); _createShipment(destinationController.text, selectedCategory); }, child: const Text('Request')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Shipments'),
        backgroundColor: Colors.transparent,
      ),
      body: ListView.builder(
        itemCount: _myShipments.length,
        itemBuilder: (context, index) {
          final s = _myShipments[index];
          return Card(
            child: ListTile(
              leading: const Icon(Icons.local_shipping),
              title: Text(s['trackingNumber']),
              subtitle: Text(s['destination']),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => TrackingScreen(shipment: s)),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showRequestShipmentDialog,
        icon: const Icon(Icons.add_location_alt),
        label: const Text('Request Shipment'),
      ),
    );
  }
}
