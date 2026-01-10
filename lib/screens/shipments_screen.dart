import 'package:flutter/material.dart';
import '../services/api_client.dart';
import 'tracking_screen.dart';

class ShipmentsScreen extends StatefulWidget {
  const ShipmentsScreen({super.key});

  @override
  State<ShipmentsScreen> createState() => _ShipmentsScreenState();
}

class _ShipmentsScreenState extends State<ShipmentsScreen> {
  String _filter = 'All';
  late Future<List<Map<String, dynamic>>> _shipmentsFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _shipmentsFuture = ApiClient.fetchShipments(status: _filter);
    });
  }

  Future<void> _createShipment() async {
    final formKey = GlobalKey<FormState>();
    String trackingNumber = 'TRK-${DateTime.now().millisecondsSinceEpoch}';
    String origin = '';
    String destination = '';
    String status = 'Pending';
    double weight = 0.0;
    double length = 0.0;
    double width = 0.0;
    double height = 0.0;
    bool autoAssignDriver = false;
    String? selectedDriverId;
    List<Map<String, dynamic>> drivers = [];

    // Fetch drivers for the dropdown
    try {
      drivers = await ApiClient.fetchDrivers();
    } catch (e) {
      debugPrint('Error fetching drivers: $e');
    }

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          double estimatedPrice = 0.0;
          if (weight > 0) {
            double vol = length * width * height;
             // Matches backend logic: (Weight * 10) + (Volume * 0.005) + 500
            estimatedPrice = (weight * 10) + (vol * 0.005) + 500;
          }

          return AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            title: const Text('New Shipment', style: TextStyle(color: Colors.white)),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Tracking #', labelStyle: TextStyle(color: Colors.white70)),
                      style: const TextStyle(color: Colors.white),
                      initialValue: trackingNumber,
                      readOnly: true,
                      onSaved: (v) => trackingNumber = v ?? '',
                    ),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Origin', labelStyle: TextStyle(color: Colors.white70)),
                      style: const TextStyle(color: Colors.white),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      onSaved: (v) => origin = v!,
                    ),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Destination', labelStyle: TextStyle(color: Colors.white70)),
                      style: const TextStyle(color: Colors.white),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      onSaved: (v) => destination = v!,
                    ),
                    const SizedBox(height: 10),
                    const Text('Dimensions & Weight', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            decoration: const InputDecoration(labelText: 'Weight (kg)', labelStyle: TextStyle(color: Colors.white70)),
                            style: const TextStyle(color: Colors.white),
                            keyboardType: TextInputType.number,
                            onChanged: (v) => setState(() => weight = double.tryParse(v) ?? 0),
                            onSaved: (v) => weight = double.tryParse(v ?? '0') ?? 0,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            decoration: const InputDecoration(labelText: 'L (cm)', labelStyle: TextStyle(color: Colors.white70)),
                            style: const TextStyle(color: Colors.white),
                            keyboardType: TextInputType.number,
                            onChanged: (v) => setState(() => length = double.tryParse(v) ?? 0),
                            onSaved: (v) => length = double.tryParse(v ?? '0') ?? 0,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            decoration: const InputDecoration(labelText: 'W (cm)', labelStyle: TextStyle(color: Colors.white70)),
                            style: const TextStyle(color: Colors.white),
                            keyboardType: TextInputType.number,
                            onChanged: (v) => setState(() => width = double.tryParse(v) ?? 0),
                            onSaved: (v) => width = double.tryParse(v ?? '0') ?? 0,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            decoration: const InputDecoration(labelText: 'H (cm)', labelStyle: TextStyle(color: Colors.white70)),
                            style: const TextStyle(color: Colors.white),
                            keyboardType: TextInputType.number,
                            onChanged: (v) => setState(() => height = double.tryParse(v) ?? 0),
                            onSaved: (v) => height = double.tryParse(v ?? '0') ?? 0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Est. Price: ₹${estimatedPrice.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.greenAccent, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    const Text('Driver Assignment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    SwitchListTile(
                      title: const Text('Auto-Assign Driver', style: TextStyle(color: Colors.white)),
                      value: autoAssignDriver,
                      onChanged: (v) => setState(() {
                        autoAssignDriver = v;
                        if (v) selectedDriverId = null;
                      }),
                    ),
                    if (!autoAssignDriver)
                      DropdownButtonFormField<String>(
                        dropdownColor: const Color(0xFF334155),
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Select Driver', labelStyle: TextStyle(color: Colors.white70)),
                        items: drivers.map((d) => DropdownMenuItem(
                          value: d['_id'].toString(),
                          child: Text(d['name'] ?? 'Unknown'),
                        )).toList(),
                        onChanged: (v) => setState(() => selectedDriverId = v),
                        onSaved: (v) => selectedDriverId = v,
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    formKey.currentState!.save();
                    try {
                      await ApiClient.createShipment({
                        'trackingNumber': trackingNumber,
                        'origin': origin,
                        'destination': destination,
                        'status': status,
                        'weight': weight,
                        'dimensions': {'length': length, 'width': width, 'height': height},
                        'autoAssignDriver': autoAssignDriver,
                        'driverId': selectedDriverId,
                        'eta': DateTime.now().add(const Duration(days: 3)).toIso8601String(),
                      });
                      if (mounted) Navigator.pop(ctx);
                      _refresh();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                },
                child: const Text('Create'),
              ),
            ],
          );
        }
      ),
    );
  }

  Future<void> _deleteShipment(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Delete Shipment?', style: TextStyle(color: Colors.white)),
        content: const Text('This action cannot be undone.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiClient.deleteShipment(id);
        _refresh();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shipments'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          DropdownButton<String>(
            dropdownColor: const Color(0xFF1E293B),
            value: _filter,
            underline: Container(),
            style: const TextStyle(color: Colors.white),
            icon: const Icon(Icons.filter_list, color: Colors.white70),
            items: ['All', 'Pending', 'In Transit', 'Delivered']
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (v) {
              if (v != null) {
                setState(() => _filter = v);
                _refresh();
              }
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton(
          onPressed: _createShipment,
          backgroundColor: const Color(0xFF4F46E5),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _shipmentsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
            }
            final shipments = snapshot.data ?? [];
            if (shipments.isEmpty) {
              return const Center(child: Text('No shipments found', style: TextStyle(color: Colors.white54)));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: shipments.length,
              itemBuilder: (context, index) {
                final shipment = shipments[index];
                final id = shipment['_id'];
                final status = shipment['status'] ?? 'Pending';
                final color = _getStatusColor(status);

                return Dismissible(
                  key: Key(id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: Colors.red,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (direction) async {
                    await _deleteShipment(id);
                    return false; // _deleteShipment handles refresh
                  },
                  child: Card(
                    color: const Color(0xFF1E293B),
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.local_shipping, color: color),
                      ),
                      title: Text(
                        shipment['trackingNumber'] ?? 'Unknown',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            '${shipment['origin']} → ${shipment['destination']}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 4),
                          if (shipment['price'] != null)
                             Text('Price: ₹${shipment['price']}', style: const TextStyle(color: Colors.greenAccent, fontSize: 12)),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Track Button
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TrackingScreen(shipment: shipment),
                                ),
                              );
                            },
                            child: const Text('TRACK', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Delivered': return Colors.green;
      case 'In Transit': return Colors.blue;
      case 'Pending': return Colors.orange;
      case 'Delayed': return Colors.red;
      default: return Colors.grey;
    }
  }
}
