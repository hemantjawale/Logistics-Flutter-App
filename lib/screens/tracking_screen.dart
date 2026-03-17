import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_client.dart';

class TrackingScreen extends StatefulWidget {
  final Map<String, dynamic> shipment;

  const TrackingScreen({super.key, required this.shipment});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  Map<String, dynamic>? _prediction;
  bool _isPredicting = true;

  @override
  void initState() {
    super.initState();
    _getPrediction();
  }

  Future<void> _getPrediction() async {
    try {
      final res = await ApiClient.predictDelay(widget.shipment['_id']);
      if (mounted) {
        setState(() {
          _prediction = res;
          _isPredicting = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isPredicting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final eta = widget.shipment['eta'] != null 
        ? DateTime.parse(widget.shipment['eta']).difference(DateTime.now()).inMinutes 
        : 0;

    return Scaffold(
      appBar: AppBar(
        title: Text('Track ${widget.shipment['trackingNumber']}'),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Map Placeholder
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(16),
                image: const DecorationImage(
                  image: NetworkImage('https://maps.googleapis.com/maps/api/staticmap?center=20.5937,78.9629&zoom=5&size=600x300&sensor=false&key=YOUR_API_KEY'), // Mock image
                  fit: BoxFit.cover,
                  opacity: 0.5,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.map, size: 48, color: Colors.white54),
                    const SizedBox(height: 8),
                    const Text('Live Tracking Map', style: TextStyle(color: Colors.white)),
                    if (widget.shipment['status'] == 'In Transit')
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ElevatedButton.icon(
                          onPressed: () {
                             _launchMaps(28.7041, 77.1025); 
                          },
                          icon: const Icon(Icons.navigation),
                          label: const Text('Open in Google Maps'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // AI Prediction Card
            _buildAIAlert(),
            const SizedBox(height: 16),

            // ETA Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer, color: Colors.blueAccent, size: 32),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Estimated Arrival', style: TextStyle(color: Colors.white70)),
                      Text(
                        eta > 0 ? '$eta Minutes' : 'Arrived / Unknown',
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.circle, size: 10, color: (widget.shipment['lastUpdated'] != null && DateTime.now().difference(DateTime.parse(widget.shipment['lastUpdated'])).inMinutes < 15) ? Colors.green : Colors.red),
                          const SizedBox(width: 6),
                          Text(
                            (widget.shipment['lastUpdated'] != null && DateTime.now().difference(DateTime.parse(widget.shipment['lastUpdated'])).inMinutes > 15) 
                              ? 'Driver Offline' 
                              : 'Driver Online',
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Driver Info
            if (widget.shipment['driverName'] != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(widget.shipment['driverName'], style: const TextStyle(color: Colors.white)),
                subtitle: const Text('Assigned Driver', style: TextStyle(color: Colors.white54)),
                trailing: IconButton(
                  icon: const Icon(Icons.phone, color: Colors.green),
                  onPressed: () => launchUrl(Uri.parse('tel:1234567890')),
                ),
              ),

            const SizedBox(height: 30),
            
            // Actions
            const Text('Documents', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.picture_as_pdf, size: 16),
                  label: const Text('Download Invoice'),
                  onPressed: () => _generateInvoice(context, widget.shipment),
                ),
                ActionChip(
                  avatar: const Icon(Icons.description, size: 16),
                  label: const Text('Dispatch Manifest'),
                  onPressed: () => _generateManifest(context, widget.shipment),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIAlert() {
    if (_isPredicting) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.purpleAccent.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 12),
            Text('AI Analyzing shipment for delay risks...', style: TextStyle(fontSize: 12, color: Colors.white60)),
          ],
        ),
      );
    }

    if (_prediction == null) return const SizedBox();

    final prob = _prediction!['probability'] ?? 0;
    final isHighRisk = prob > 40;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHighRisk ? Colors.redAccent.withOpacity(0.1) : Colors.greenAccent.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isHighRisk ? Colors.redAccent.withOpacity(0.3) : Colors.greenAccent.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(isHighRisk ? Icons.auto_graph_rounded : Icons.auto_awesome_rounded, 
               color: isHighRisk ? Colors.redAccent : Colors.greenAccent),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isHighRisk ? 'AI Delay Risk: $prob%' : 'On-Time Probability: ${100-prob}%',
                  style: TextStyle(fontWeight: FontWeight.bold, color: isHighRisk ? Colors.redAccent : Colors.greenAccent),
                ),
                Text(
                  _prediction!['reason'] ?? 'Normal shipment flow detected.',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchMaps(double lat, double lng) async {
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _generateInvoice(BuildContext context, Map<String, dynamic> data) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              children: [
                pw.Text('INVOICE', style: pw.TextStyle(fontSize: 40, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 20),
                pw.Text('Tracking #: ${data['trackingNumber']}'),
                pw.Text('Customer: ${data['customerName'] ?? 'Guest'}'),
                pw.Divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Description'),
                    pw.Text('Amount'),
                  ],
                ),
                pw.Divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Shipping Charges (${data['weight'] ?? 0} kg)'),
                    pw.Text('INR ${data['price'] ?? 0}'),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Text('Total: INR ${data['price'] ?? 0}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 20)),
              ],
            ),
          );
        },
      ),
    );
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  Future<void> _generateManifest(BuildContext context, Map<String, dynamic> data) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('DISPATCH MANIFEST', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Text('Origin: ${data['origin']}'),
              pw.Text('Destination: ${data['destination']}'),
              pw.Text('Driver: ${data['driverName'] ?? 'Unassigned'}'),
              pw.SizedBox(height: 20),
              pw.Text('Goods Description:'),
              pw.Text('Weight: ${data['weight']} kg'),
            ],
          );
        },
      ),
    );
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }
}
