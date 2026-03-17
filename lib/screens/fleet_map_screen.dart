import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class FleetMapScreen extends StatefulWidget {
  const FleetMapScreen({super.key});

  @override
  State<FleetMapScreen> createState() => _FleetMapScreenState();
}

class _FleetMapScreenState extends State<FleetMapScreen> {
  late GoogleMapController _mapController;
  final Set<Marker> _markers = {};

  final List<Map<String, dynamic>> _mockDrivers = [
    {
      'id': '1',
      'name': 'Rahul Sharma',
      'lat': 28.6139,
      'lng': 77.2090,
      'status': 'On Time',
      'load': 'Electronics (400kg)',
      'vehicle': 'Tata Ace - DL01AB1234',
    },
    {
      'id': '2',
      'name': 'Amit Kumar',
      'lat': 28.5355,
      'lng': 77.3910,
      'status': 'Delayed',
      'load': 'Groceries (200kg)',
      'vehicle': 'Mahindra Bolero - UP16CD5678',
    },
    {
      'id': '3',
      'name': 'Deepak Singh',
      'lat': 28.4595,
      'lng': 77.0266,
      'status': 'Issue',
      'load': 'Furniture (600kg)',
      'vehicle': 'Eicher Pro - HR55EF9012',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadMarkers();
  }

  void _loadMarkers() {
    for (final driver in _mockDrivers) {
      Color hue;
      switch (driver['status']) {
        case 'On Time': hue = Colors.green; break;
        case 'Delayed': hue = Colors.orange; break;
        case 'Issue': hue = Colors.red; break;
        default: hue = Colors.blue;
      }

      _markers.add(
        Marker(
          markerId: MarkerId(driver['id']),
          position: LatLng(driver['lat'], driver['lng']),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            driver['status'] == 'On Time' ? BitmapDescriptor.hueGreen :
            driver['status'] == 'Delayed' ? BitmapDescriptor.hueOrange :
            BitmapDescriptor.hueRed
          ),
          onTap: () => _showDriverDetails(driver),
        ),
      );
    }
  }

  void _showDriverDetails(Map<String, dynamic> driver) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        height: 350,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.indigoAccent.withOpacity(0.1),
                  child: const Icon(Icons.person_rounded, color: Colors.indigoAccent),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(driver['name'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text(driver['vehicle'], style: const TextStyle(color: Colors.white54, fontSize: 13)),
                    ],
                  ),
                ),
                _statusChip(driver['status']),
              ],
            ),
            const SizedBox(height: 24),
            _infoRow(Icons.shopping_bag_outlined, 'Current Load', driver['load']),
            const SizedBox(height: 16),
            _infoRow(Icons.place_outlined, 'Last Seen', '3 minutes ago near Noida Sector 62'),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => launchUrl(Uri.parse('tel:1234567890')),
                    icon: const Icon(Icons.phone),
                    label: const Text('Call Driver'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.route_rounded),
                    label: const Text('View Route'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigoAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    Color color;
    IconData icon;
    switch (status) {
      case 'On Time': color = Colors.greenAccent; icon = Icons.check_circle_rounded; break;
      case 'Delayed': color = Colors.orangeAccent; icon = Icons.info_rounded; break;
      case 'Issue': color = Colors.redAccent; icon = Icons.warning_rounded; break;
      default: color = Colors.blueAccent; icon = Icons.help_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(status, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.indigoAccent),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      appBar: AppBar(
        title: const Text('Fleet Command Center'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: GoogleMap(
        initialCameraPosition: const CameraPosition(
          target: LatLng(28.6139, 77.2090),
          zoom: 11,
        ),
        onMapCreated: (controller) {
          _mapController = controller;
          _mapController.setMapStyle(_darkMapStyle);
        },
        markers: _markers,
        myLocationEnabled: true,
        mapType: MapType.normal,
        style: _darkMapStyle, // Mock application of dark style
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Open filter for active/idle/maintenance vehicles
        },
        label: const Text('Filters'),
        icon: const Icon(Icons.tune_rounded),
        backgroundColor: Colors.indigoAccent,
      ),
    );
  }

  final String _darkMapStyle = '''
[
  {
    "elementType": "geometry",
    "stylers": [{"color": "#242f3e"}]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#746855"}]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [{"color": "#242f3e"}]
  },
  {
    "featureType": "administrative.locality",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#d59563"}]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#d59563"}]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry",
    "stylers": [{"color": "#263c3f"}]
  },
  {
    "featureType": "poi.park",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#6b9a76"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [{"color": "#38414e"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry.stroke",
    "stylers": [{"color": "#212a37"}]
  },
  {
    "featureType": "road",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#9ca5b3"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [{"color": "#746855"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry.stroke",
    "stylers": [{"color": "#1f2835"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#f3d19c"}]
  },
  {
    "featureType": "transit",
    "elementType": "geometry",
    "stylers": [{"color": "#2f3948"}]
  },
  {
    "featureType": "transit.station",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#d59563"}]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [{"color": "#17263c"}]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#515c6d"}]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.stroke",
    "stylers": [{"color": "#17263c"}]
  }
]
''';
}
