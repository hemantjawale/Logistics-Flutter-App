import 'dart:convert';
import 'package:http/http.dart' as http;

/// Simple API client for the logistics backend.
///
/// When you deploy to Render, set [baseUrl] to your live backend URL,
/// e.g. https://your-backend.onrender.com/api
class ApiClient {
  // For local emulator use: http://10.0.2.2:3000/api
  // For real device on same Wi-Fi use: http://<your_pc_ip>:3000/api
  // For Render deployment use: https://your-service.onrender.com/api
  static String baseUrl = 'https://flutter-pnvo.onrender.com/api';

  static Future<List<Map<String, dynamic>>> _getList(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    final res = await http.get(uri);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final List data = jsonDecode(res.body) as List;
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('GET $path failed: ${res.statusCode} ${res.body}');
  }

  static Future<Map<String, dynamic>> _get(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    final res = await http.get(uri);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('GET $path failed: ${res.statusCode} ${res.body}');
  }

  static Future<Map<String, dynamic>> _send(
    String method,
    String path,
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = {'Content-Type': 'application/json'};
    late http.Response res;
    final jsonBody = jsonEncode(body);

    switch (method) {
      case 'POST':
        res = await http.post(uri, headers: headers, body: jsonBody);
        break;
      case 'PUT':
        res = await http.put(uri, headers: headers, body: jsonBody);
        break;
      default:
        throw ArgumentError('Unsupported method $method');
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('$method $path failed: ${res.statusCode} ${res.body}');
  }

  static Future<void> _delete(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    final res = await http.delete(uri);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('DELETE $path failed: ${res.statusCode} ${res.body}');
    }
  }

  // Shipments CRUD -----------------------------------------------------------

  static Future<List<Map<String, dynamic>>> fetchShipments({String? status, String? driverId}) {
    String query = '?';
    if (status != null && status != 'All') query += 'status=$status&';
    if (driverId != null) query += 'driverId=$driverId&';
    
    return _getList('/shipments$query');
  }

  static Future<Map<String, dynamic>> createShipment(
    Map<String, dynamic> shipment,
  ) {
    return _send('POST', '/shipments', shipment);
  }

  static Future<Map<String, dynamic>> updateShipment(
    String id,
    Map<String, dynamic> shipment,
  ) {
    return _send('PUT', '/shipments/$id', shipment);
  }

  static Future<void> deleteShipment(String id) {
    return _delete('/shipments/$id');
  }

  // Fleet CRUD ---------------------------------------------------------------

  static Future<List<Map<String, dynamic>>> fetchFleet() {
    return _getList('/fleet');
  }

  static Future<Map<String, dynamic>> createVehicle(
    Map<String, dynamic> vehicle,
  ) {
    return _send('POST', '/fleet', vehicle);
  }

  static Future<void> deleteVehicle(String id) {
    return _delete('/fleet/$id');
  }

  // Payments CRUD ------------------------------------------------------------

  static Future<List<Map<String, dynamic>>> fetchPayments() {
    return _getList('/payments');
  }

  static Future<Map<String, dynamic>> createPayment(
    Map<String, dynamic> payment,
  ) {
    return _send('POST', '/payments', payment);
  }

  static Future<void> deletePayment(String id) {
    return _delete('/payments/$id');
  }
  
  // Analytics ----------------------------------------------------------------
  
  static Future<Map<String, dynamic>> fetchSummaryAnalytics() {
    return _get('/analytics/summary');
  }

  // Users / Drivers ----------------------------------------------------------

  static Future<List<Map<String, dynamic>>> fetchDrivers() {
    return _getList('/users/drivers');
  }
}
