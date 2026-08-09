import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_client.dart'; 

// Definice možných rolí uživatele
enum UserRole {
  guest,
  student,
  teacher,
}

// Model představující stav přihlášeného uživatele
class AuthState {
  final UserRole role;
  final bool isAuthenticated;
  final String? token; 
  final String? username;
  final bool isLoading;
  
  const AuthState({
    this.role = UserRole.guest,
    this.isAuthenticated = false,
    this.token,
    this.username,
    this.isLoading = true,
  });

  AuthState copyWith({
    UserRole? role,
    bool? isAuthenticated,
    String? token,
    String? username,
    bool? isLoading,
  }) {
    return AuthState(
      role: role ?? this.role,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      token: token ?? this.token,
      username: username ?? this.username,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// Notifier pro správu stavu přihlášení
class AuthNotifier extends Notifier<AuthState> {
  static const _tokenKey = 'jwt_token';
  static const _roleKey = 'user_role';

  @override
  AuthState build() {
    _loadSavedAuth();
    return const AuthState(isLoading: true);
  }

  Future<void> _loadSavedAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      final roleStr = prefs.getString(_roleKey);
      final username = prefs.getString('username');

      if (token != null && roleStr != null) {
        state = state.copyWith(
          isAuthenticated: true,
          token: token,
          username: username,
          role: roleStr == 'student' ? UserRole.student : UserRole.teacher,
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  // Asynchronní metoda pro přihlášení, komunikuje s Python API
  Future<void> login(String username, String password, bool isStudent) async {
    // Vytvoříme instanci klienta bez tokenu (protože ho ještě nemáme)
    final apiClient = ApiClient();
    
    // Tělo requestu očekávané v Python API
    final payload = {
      "username": username,
      "password": password,
      "is_teacher": !isStudent,
    };

    final endpoint = '/login';

    // Pokud request selže, ApiClient vyhodí ApiException, kterou chytíme v UI
    final response = await apiClient.post(endpoint, payload);

    // Úspěch - vytažení tokenu
    final token = response['access_token'];
    if (token != null) {
      // Uložíme do lokální paměti
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      await prefs.setString(_roleKey, isStudent ? 'student' : 'teacher');
      await prefs.setString('username', username);

      state = state.copyWith(
        isAuthenticated: true,
        role: isStudent ? UserRole.student : UserRole.teacher,
        token: token,
        username: username,
      );
    } else {
      throw Exception('Server nevrátil přístupový token.');
    }
  }

  // Metoda pro odhlášení
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_roleKey);
    await prefs.remove('username');
    state = const AuthState(isLoading: false);
  }
}

// Globální provider
final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
