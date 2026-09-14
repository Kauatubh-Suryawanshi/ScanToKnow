import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class ApiService {
  static const _timeout = Duration(seconds: 12);

  static Future<dynamic> get(String endpoint) async {
    final uri = Uri.parse('${AppConfig.baseUrl}$endpoint');

    try {
      final response = await http.get(uri).timeout(_timeout);
      final body = response.body;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (body.isEmpty) return null;
        return jsonDecode(body);
      }

      String message = response.reasonPhrase ?? 'Request failed';
      try {
        final decoded = jsonDecode(body);
        if (decoded is Map && decoded['error'] is String) {
          message = decoded['error'] as String;
        }
      } catch (_) {
        // Keep the HTTP reason when the server response is not JSON.
      }

      throw Exception('HTTP ${response.statusCode}: $message');
    } on TimeoutException {
      throw Exception('Request timed out');
    } on SocketException {
      throw Exception('No internet / server unreachable');
    } on FormatException {
      throw Exception('Invalid server response');
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('API error: $e');
    }
  }
}
