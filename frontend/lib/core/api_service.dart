import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';

class ApiService {
  static Future<Map<String, String>> _getHeaders({bool requireAuth = false}) async {
    final headers = {
      'Content-Type': 'application/json; charset=UTF-8',
    };

    if (requireAuth) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Token $token';
      } else {
        throw Exception("Authentication token not found.");
      }
    }

    return headers;
  }

  static Future<http.Response> post(String endpoint, Map<String, dynamic> body, {bool requireAuth = false}) async {
    final url = Uri.parse('${Constants.apiBaseUrl}$endpoint');
    final headers = await _getHeaders(requireAuth: requireAuth);
    
    return await http.post(url, headers: headers, body: jsonEncode(body));
  }

  static Future<http.Response> get(String endpoint, {bool requireAuth = false}) async {
    final url = Uri.parse('${Constants.apiBaseUrl}$endpoint');
    final headers = await _getHeaders(requireAuth: requireAuth);
    
    return await http.get(url, headers: headers);
  }
}
