import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/shipment.dart';
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

  @override
  void dispose() {
    super.dispose();
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

  Future<void> _createShipment({
    required String destination,
    required String category,
    required double length,
    required double width,
    required double height,
    required double weight,
    required double price,
    required String priority,
  }) async {
    setState(() => _isLoading = true);
    try {
      final user = await UserSession.getUser();
      
      final shipmentData = {
        'trackingNumber': 'TRK-${DateTime.now().millisecondsSinceEpoch}',
        'origin': 'Current Location',
        'destination': destination,
        'category': category,
        'customerId': user?['_id'],
        'weight': weight,
        'dimensions': {
          'length': length * 100, // Convert meters to cm
          'width': width * 100,
          'height': height * 100,
        },
        'price': price,
        'priority': priority,
        'autoAssignDriver': true,
        'notes': 'Created via customer app',
      };

      await ApiClient.createShipment(shipmentData);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shipment created successfully!')),
        );
      }
      _loadShipments();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showRequestShipmentDialog() {
    final destinationController = TextEditingController();
    final lengthController = TextEditingController();
    final widthController = TextEditingController();
    final heightController = TextEditingController();
    final weightController = TextEditingController();
    String selectedCategory = 'Other';
    String selectedPriority = 'Normal';
    final categories = ['Agriculture', 'Textiles', 'Electronics', 'Pharmaceuticals', 'Automotive', 'FMCG', 'Construction', 'Other'];
    final priorities = ['Low', 'Normal', 'High', 'Critical'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text('Request New Shipment', style: TextStyle(color: Colors.white)),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Pick your destination:', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 10),
                  Container(height: 100, color: Colors.grey[800], child: const Center(child: Icon(Icons.map, size: 50, color: Colors.white54))),
                  const SizedBox(height: 10),
                  TextField(
                    controller: destinationController,
                    decoration: const InputDecoration(
                      labelText: 'Destination Address',
                      labelStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    dropdownColor: const Color(0xFF334155),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      labelStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24),
                      ),
                    ),
                    items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(color: Colors.white)))).toList(),
                    onChanged: (val) => setState(() => selectedCategory = val!),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedPriority,
                    dropdownColor: const Color(0xFF334155),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Priority',
                      labelStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24),
                      ),
                    ),
                    items: priorities.map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(color: Colors.white)))).toList(),
                    onChanged: (val) => setState(() => selectedPriority = val!),
                  ),
                  const SizedBox(height: 15),
                  const Text('Package Dimensions (in meters)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: lengthController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Length (m)',
                            labelStyle: TextStyle(color: Colors.white70),
                            border: OutlineInputBorder(),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white24),
                            ),
                          ),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: widthController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Width (m)',
                            labelStyle: TextStyle(color: Colors.white70),
                            border: OutlineInputBorder(),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white24),
                            ),
                          ),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: heightController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Height (m)',
                      labelStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: weightController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Expected Weight (kg)',
                      labelStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  _buildPriceEstimate(lengthController, widthController, heightController, weightController, selectedPriority),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            FilledButton(
              onPressed: () async {
                if (destinationController.text.isEmpty ||
                    lengthController.text.isEmpty ||
                    widthController.text.isEmpty ||
                    heightController.text.isEmpty ||
                    weightController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all fields')),
                  );
                  return;
                }

                final length = double.tryParse(lengthController.text) ?? 0;
                final width = double.tryParse(widthController.text) ?? 0;
                final height = double.tryParse(heightController.text) ?? 0;
                final weight = double.tryParse(weightController.text) ?? 0;

                // Calculate price
                final volume = length * width * height; // in cubic meters
                double basePrice = (weight * 10) + (volume * 500) + 500; // Volume * 500 for cubic meters
                
                final priorityMultiplier = {
                  'Low': 0.9,
                  'Normal': 1.0,
                  'High': 1.25,
                  'Critical': 1.5
                };
                basePrice *= priorityMultiplier[selectedPriority] ?? 1.0;
                
                final finalPrice = (basePrice * 100).round() / 100;

                Navigator.pop(context);
                await _createShipment(
                  destination: destinationController.text,
                  category: selectedCategory,
                  length: length,
                  width: width,
                  height: height,
                  weight: weight,
                  price: finalPrice,
                  priority: selectedPriority,
                );
              },
              child: const Text('Create Shipment'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceEstimate(
    TextEditingController lengthController,
    TextEditingController widthController,
    TextEditingController heightController,
    TextEditingController weightController,
    String priority,
  ) {
    final length = double.tryParse(lengthController.text) ?? 0;
    final width = double.tryParse(widthController.text) ?? 0;
    final height = double.tryParse(heightController.text) ?? 0;
    final weight = double.tryParse(weightController.text) ?? 0;

    if (length > 0 && width > 0 && height > 0 && weight > 0) {
      final volume = length * width * height;
      double basePrice = (weight * 10) + (volume * 500) + 500;
      
      final priorityMultiplier = {
        'Low': 0.9,
        'Normal': 1.0,
        'High': 1.25,
        'Critical': 1.5
      };
      basePrice *= priorityMultiplier[priority] ?? 1.0;
      
      final finalPrice = (basePrice * 100).round() / 100;

      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF334155),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Estimated Price:', style: TextStyle(color: Colors.white70)),
            Text(
              '₹$finalPrice',
              style: const TextStyle(
                color: Colors.greenAccent,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Shipments'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: _showRequestShipmentDialog,
            icon: const Icon(Icons.add, color: Colors.white),
            tooltip: 'Request Shipment',
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              padding: const EdgeInsets.all(8),
            ),
          ),
          const SizedBox(width: 16),
        ],
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
    );
  }
}
