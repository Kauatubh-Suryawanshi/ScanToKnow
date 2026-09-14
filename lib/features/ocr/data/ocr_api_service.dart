import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';

class OCRApiService {
  static String get _baseUrl => '${AppConfig.baseUrl}/v1/ocr/scan';
  static const _timeout = Duration(seconds: 55);

  static Future<Map<String, dynamic>> scanImage(File image) async {
    final request = http.MultipartRequest('POST', Uri.parse(_baseUrl));
    request.files.add(await http.MultipartFile.fromPath('image', image.path));
    return _send(request);
  }

  static Future<Map<String, dynamic>> scanImageBytes(Uint8List bytes) async {
    final request = http.MultipartRequest('POST', Uri.parse(_baseUrl));
    request.files.add(
      http.MultipartFile.fromBytes('image', bytes, filename: 'scan.jpg'),
    );
    return _send(request);
  }

  static Future<Map<String, dynamic>> _send(
    http.MultipartRequest request,
  ) async {
    try {
      final streamed = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamed);

      Map<String, dynamic> decoded = {};
      if (response.body.isNotEmpty) {
        decoded = Map<String, dynamic>.from(jsonDecode(response.body));
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          decoded['error'] ?? 'OCR request failed: ${response.statusCode}',
        );
      }

      final data = decoded['data'];
      if (data is! Map) throw Exception('Empty OCR response');
      return Map<String, dynamic>.from(data);
    } on TimeoutException {
      throw Exception('OCR request timed out');
    } on SocketException {
      throw Exception('No internet / server unreachable');
    } on FormatException {
      throw Exception('Invalid OCR server response');
    }
  }
}
