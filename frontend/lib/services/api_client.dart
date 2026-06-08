import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

// URL adresa backendu.
const String baseUrl = 'http://127.0.0.1:8000';

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}

class ApiClient {
  final String? token;

  ApiClient({this.token});

  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    // Pokud máme k dispozici token, přidáme ho do hlavičky (Bearer)
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    try {
      final response = await http.post(
        uri,
        headers: _headers,
        body: json.encode(body),
      );
      
      return _processResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Chyba síťového připojení k API', 0);
    }
  }

  Future<dynamic> get(String endpoint) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    try {
      final response = await http.get(
        uri,
        headers: _headers,
      );
      
      return _processResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Chyba síťového připojení k API', 0);
    }
  }

  dynamic _processResponse(http.Response response) {
    dynamic body;
    try {
      body = response.body.isNotEmpty ? json.decode(utf8.decode(response.bodyBytes)) : {};
    } catch (e) {
      body = response.body;
    }

    // Status 200-299 je úspěch
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    } else {
      // Backend FastAPI standardně vrací chyby pod klíčem "detail"
      String errorMessage = 'Neznámá chyba serveru';
      if (body is Map<String, dynamic> && body.containsKey('detail')) {
        errorMessage = body['detail'].toString();
      }
      throw ApiException(errorMessage, response.statusCode);
    }
  }
}

// Provider pro ApiClienta, který je závislý na AuthProvideru
// Díky tomuto přístupu se do ApiClienta automaticky propíše token hned, jakmile se uživatel přihlásí
final apiClientProvider = Provider<ApiClient>((ref) {
  final authState = ref.watch(authProvider);
  return ApiClient(token: authState.token);
});
