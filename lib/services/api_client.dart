import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'user_session.dart';

class ApiClient {
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? 'https://flutter-pnvo.onrender.com/api';

  static Future<Map<String, String>> _getHeaders() async {
    final user = await UserSession.getUser();
    final token = user?['token'];
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else {
      dynamic body;
      try {
        body = jsonDecode(response.body);
      } catch (e) {
        throw 'Error: ${response.statusCode}';
      }
      throw body['message'] ?? 'An error occurred';
    }
  }

  // Auth Methods
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    return Map<String, dynamic>.from(_handleResponse(response));
  }

  static Future<void> sendOtp(String phone) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/send-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone}),
    );
    _handleResponse(response);
  }

  static Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
    String role, {
    String? phone,
    String? otp,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'role': role,
        if (phone != null) 'phone': phone,
        if (otp != null) 'otp': otp,
      }),
    );
    return Map<String, dynamic>.from(_handleResponse(response));
  }

  static Future<void> resetPassword(String phone, String otp, String newPassword) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'phone': phone,
        'otp': otp,
        'newPassword': newPassword,
      }),
    );
    _handleResponse(response);
  }

  // Shipment Methods
  static Future<List<Map<String, dynamic>>> fetchShipments({String? status}) async {
    String url = '$baseUrl/shipments';
    if (status != null && status != 'All') {
      url += '?status=$status';
    }
    final response = await http.get(Uri.parse(url), headers: await _getHeaders());
    final data = _handleResponse(response);
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<Map<String, dynamic>> createShipment(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/shipments'),
      headers: await _getHeaders(),
      body: jsonEncode(data),
    );
    return Map<String, dynamic>.from(_handleResponse(response));
  }

  static Future<Map<String, dynamic>> updateShipment(String id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/shipments/$id'),
      headers: await _getHeaders(),
      body: jsonEncode(data),
    );
    return Map<String, dynamic>.from(_handleResponse(response));
  }

  static Future<void> deleteShipment(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/shipments/$id'),
      headers: await _getHeaders(),
    );
    _handleResponse(response);
  }

  static Future<void> requestDeliveryOtp(String shipmentId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/shipments/$shipmentId/request-otp'),
      headers: await _getHeaders(),
    );
    _handleResponse(response);
  }

  static Future<void> completeDeliveryWithOtp(String shipmentId, String otp) async {
    final response = await http.post(
      Uri.parse('$baseUrl/shipments/$shipmentId/complete-otp'),
      headers: await _getHeaders(),
      body: jsonEncode({'otp': otp}),
    );
    _handleResponse(response);
  }

  // Fleet Methods
  static Future<List<Map<String, dynamic>>> fetchFleet() async {
    final response = await http.get(Uri.parse('$baseUrl/fleet'), headers: await _getHeaders());
    final data = _handleResponse(response);
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<Map<String, dynamic>> createVehicle(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/fleet'),
      headers: await _getHeaders(),
      body: jsonEncode(data),
    );
    return Map<String, dynamic>.from(_handleResponse(response));
  }

  static Future<void> deleteVehicle(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/fleet/$id'),
      headers: await _getHeaders(),
    );
    _handleResponse(response);
  }

  // Payment Methods
  static Future<List<Map<String, dynamic>>> fetchPayments() async {
    final response = await http.get(Uri.parse('$baseUrl/payments'), headers: await _getHeaders());
    final data = _handleResponse(response);
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<Map<String, dynamic>> createPayment(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/payments'),
      headers: await _getHeaders(),
      body: jsonEncode(data),
    );
    return Map<String, dynamic>.from(_handleResponse(response));
  }

  // Analytics Methods
  static Future<Map<String, dynamic>> fetchSummaryAnalytics() async {
    final response = await http.get(Uri.parse('$baseUrl/analytics/summary'), headers: await _getHeaders());
    return Map<String, dynamic>.from(_handleResponse(response));
  }

  // User/Client Methods
  static Future<List<Map<String, dynamic>>> fetchDrivers() async {
    final response = await http.get(Uri.parse('$baseUrl/users/drivers'), headers: await _getHeaders());
    final data = _handleResponse(response);
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<List<Map<String, dynamic>>> fetchCustomers() async {
    final response = await http.get(Uri.parse('$baseUrl/users/customers'), headers: await _getHeaders());
    final data = _handleResponse(response);
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<Map<String, dynamic>> updateUser(String id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/$id'),
      headers: await _getHeaders(),
      body: jsonEncode(data),
    );
    return Map<String, dynamic>.from(_handleResponse(response));
  }
}
