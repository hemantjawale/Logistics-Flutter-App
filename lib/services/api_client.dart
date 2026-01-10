import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Simple API client for the logistics backend.
///
/// When you deploy to Render, set [baseUrl] to your live backend URL,
/// e.g. https://your-backend.onrender.com/api
class ApiClient {
  // For local emulator use: http://10.0.2.2:3000/api
  // For real device on same Wi-Fi use: http://<your_pc_ip>:3000/api
  // For Render deployment use: https://your-service.onrender.com/api
  static String baseUrl = dotenv.env['API_BASE_URL'] ?? 'https://flutter-pnvo.onrender.com/api';

  static Future<List<Map<String, dynamic>>> _getList(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 15));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final List data = jsonDecode(res.body) as List;
        return data.cast<Map<String, dynamic>>();
      }
      throw Exception('GET $path failed: ${res.statusCode} ${res.body}');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> _get(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 15));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      throw Exception('GET $path failed: ${res.statusCode} ${res.body}');
    } catch (e) {
      throw Exception('Network error: $e');
    }
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

    try {
      switch (method) {
        case 'POST':
          res = await http.post(uri, headers: headers, body: jsonBody).timeout(const Duration(seconds: 15));
          break;
        case 'PUT':
          res = await http.put(uri, headers: headers, body: jsonBody).timeout(const Duration(seconds: 15));
          break;
        default:
          throw ArgumentError('Unsupported method $method');
      }

      if (res.statusCode >= 200 && res.statusCode < 300) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      throw Exception('Request failed: ${res.statusCode} ${res.body}');
    } catch (e) {
      throw Exception('Network error: $e');
    }
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

  static Future<Map<String, dynamic>> login(String email, String password) {
    return _send('POST', '/users/login', {
      'email': email,
      'password': password,
    });
  }

  // OTP & Password -----------------------------------------------------------

  static Future<void> sendOtp(String phone) async {
    final res = await _send('POST', '/users/send-otp', {'phone': phone});
    // Check message?
  }

  static Future<void> resetPassword(String phone, String otp, String newPassword) {
    return _send('POST', '/users/reset-password', {
      'phone': phone,
      'otp': otp,
      'newPassword': newPassword,
    });
  }
  
  static Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
    String role, {
    String? phone,
    String? otp,
  }) {
    return _send('POST', '/users/register', {
      'name': name,
      'email': email,
      'password': password,
      'role': role,
      if (phone != null) 'phone': phone,
      if (otp != null) 'otp': otp,
    });
  }

  // Razorpay -----------------------------------------------------------------

  static Future<Map<String, dynamic>> createRazorpayOrder(double amount) {
    return _send('POST', '/payments/create-order', {
      'amount': amount,
      'currency': 'INR',
      'receipt': 'rcpt_${DateTime.now().millisecondsSinceEpoch}',
    });
  }

  static Future<void> verifyRazorpayPayment(
    String orderId,
    String paymentId,
    String signature,
    Map<String, dynamic> paymentData,
  ) {
    return _send('POST', '/payments/verify-payment', {
      'orderId': orderId,
      'paymentId': paymentId,
      'signature': signature,
      'paymentData': paymentData,
    });
  }

  static Future<List<Map<String, dynamic>>> fetchDrivers() {
    return _getList('/users/drivers');
  }
}
