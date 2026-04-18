import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core (Shared logic, themes, constants)/api_config.dart';

class ApiService {
  final String baseUrl;
  final Duration _timeout = const Duration(seconds: 15);

  ApiService({String? baseUrl}) : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Future<dynamic> get(String path) async {
    final response = await http
        .get(Uri.parse('$baseUrl$path'), headers: _headers)
        .timeout(_timeout);
    return _processResponse(response);
  }

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl$path'),
          headers: _headers,
          body: jsonEncode(body),
        )
        .timeout(_timeout);
    return _processResponse(response);
  }

  Future<Map<String, dynamic>> put(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await http
        .put(
          Uri.parse('$baseUrl$path'),
          headers: _headers,
          body: jsonEncode(body),
        )
        .timeout(_timeout);
    return _processResponse(response);
  }

  Future<Map<String, dynamic>> delete(String path) async {
    final response = await http
        .delete(Uri.parse('$baseUrl$path'), headers: _headers)
        .timeout(_timeout);
    return _processResponse(response);
  }

  dynamic _processResponse(http.Response response) {
    final decoded = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }
    final message = (decoded is Map && decoded.containsKey('detail'))
        ? decoded['detail'].toString()
        : 'HTTP ${response.statusCode}';
    throw ApiException(message, response.statusCode);
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  const ApiException(this.message, this.statusCode);

  @override
  String toString() => 'ApiException($statusCode): $message';
}
