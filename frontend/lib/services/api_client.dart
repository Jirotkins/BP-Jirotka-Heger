import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

/// URL adresa backendu (FastAPI).
const String baseUrl = 'http://127.0.0.1:8000'; //172.20.10.8:8000

/// Vlastní výjimka pro ošetření chyb ze serveru.
/// Uchovává textovou [message] a HTTP [statusCode].
class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}

/// Třída zapouzdřující veškerou HTTP komunikaci (CRUD + SSE) s backendem.
/// Automaticky vkládá autorizační token, ošetřuje chyby a parsuje odpovědi.
class ApiClient {
  /// JWT token vložený (pokud existuje) do hlavičky každého požadavku.
  final String? token;

  ApiClient({this.token});

  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
    };
    // Pokud máme k dispozici token, přidáme ho do hlavičky (Bearer)
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Odešle HTTP POST požadavek na [endpoint] se zadaným [body].
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
      throw ApiException('Chyba síťového připojení k API: $e', 0);
    }
  }

  /// Odešle HTTP PUT požadavek na [endpoint] se zadaným [body].
  Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    try {
      final response = await http.put(
        uri,
        headers: _headers,
        body: json.encode(body),
      );

      return _processResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Chyba síťového připojení k API: $e', 0);
    }
  }

  /// Odešle HTTP DELETE požadavek na [endpoint].
  Future<dynamic> delete(String endpoint) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    try {
      final response = await http.delete(uri, headers: _headers);

      return _processResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Chyba síťového připojení k API: $e', 0);
    }
  }

  /// Odešle HTTP GET požadavek na [endpoint].
  Future<dynamic> get(String endpoint) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    try {
      final response = await http.get(uri, headers: _headers);

      return _processResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Chyba síťového připojení k API: $e', 0);
    }
  }

  /// Interní metoda, která zpracovává surovou odpověď `http.Response`.
  /// Pokud status není `2xx`, pokusí se vyextrahovat hlášku 'detail' a vyhodí [ApiException].
  dynamic _processResponse(http.Response response) {
    dynamic body;
    try {
      body = response.body.isNotEmpty
          ? json.decode(utf8.decode(response.bodyBytes))
          : {};
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

  /// Otevře SSE (Server-Sent Events) spojení na daný endpoint a vrací Stream JSON objektů.
  Stream<Map<String, dynamic>> listenSse(String endpoint) async* {
    final client = http.Client();
    final request = http.Request('GET', Uri.parse('$baseUrl$endpoint'));
    request.headers.addAll(_headers);
    request.headers['Accept'] = 'text/event-stream';
    
    try {
      final response = await client.send(request);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        await for (var line in response.stream.transform(utf8.decoder).transform(const LineSplitter())) {
          if (line.startsWith('data: ')) {
            final dataStr = line.substring(6).trim();
            if (dataStr.isNotEmpty) {
              try {
                yield json.decode(dataStr);
              } catch (e) {
                // Ignore parse errors for single events
              }
            }
          }
        }
      } else {
        throw ApiException('Nelze se připojit k SSE', response.statusCode);
      }
    } catch (e) {
      debugPrint('SSE Error: $e');
    } finally {
      client.close();
    }
  }
}

/// Globální Riverpod provider pro [ApiClient].
/// Reaguje na změny v [authProvider] – tzn. jakmile se uživatel přihlásí,
/// instance se přepíše a získá k dispozici aktuální přístupový `token`.
final apiClientProvider = Provider<ApiClient>((ref) {
  final authState = ref.watch(authProvider);
  return ApiClient(token: authState.token);
});
