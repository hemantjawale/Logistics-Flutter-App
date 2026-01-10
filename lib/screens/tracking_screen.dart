import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

class TrackingScreen extends StatelessWidget {
  final Map<String, dynamic> shipment;

  const TrackingScreen({super.key, required this.shipment});

  @override
  Widget build(BuildContext context) {
    final eta = shipment['eta'] != null 
        ? DateTime.parse(shipment['eta']).difference(DateTime.now()).inMinutes 
        : 0;

    return Scaffold(
      appBar: AppBar(
        title: Text('Track ${shipment['trackingNumber']}'),
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
                    if (shipment['status'] == 'In Transit')
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ElevatedButton.icon(
                          onPressed: () {
                             // Mock Lat/Lng for demo
                             _launchMaps(28.7041, 77.1025); // Delhi
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
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Driver Info
            if (shipment['driverName'] != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(shipment['driverName'], style: const TextStyle(color: Colors.white)),
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
                  onPressed: () => _generateInvoice(context, shipment),
                ),
                ActionChip(
                  avatar: const Icon(Icons.description, size: 16),
                  label: const Text('Dispatch Manifest'),
                  onPressed: () => _generateManifest(context, shipment),
                ),
              ],
            ),
          ],
        ),
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

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
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
              pw.Text('Dims: ${data['dimensions']?['length']}x${data['dimensions']?['width']}x${data['dimensions']?['height']} cm'),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}
