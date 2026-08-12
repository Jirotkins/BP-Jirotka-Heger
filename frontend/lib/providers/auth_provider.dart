import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_client.dart'; 

/// Výčet možných rolí uživatele v systému.
enum UserRole {
  /// Nepřihlášený uživatel.
  guest,
  
  /// Přihlášený student.
  student,
  
  /// Přihlášený učitel.
  teacher,
}

/// Model představující stav přihlášeného uživatele a jeho autentizační údaje.
class AuthState {
  /// Aktuální role uživatele.
  final UserRole role;
  /// Udává, zda je uživatel úspěšně přihlášen a ověřen.
  final bool isAuthenticated;
  
  /// JWT token pro autorizaci požadavků vůči API.
  final String? token; 
  
  /// Zobrazované jméno nebo přihlašovací login.
  final String? username;
  
  /// Indikuje, zda se právě ověřuje uložené přihlášení (při startu aplikace).
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

/// Správce stavu přihlášení. Stará se o komunikaci s backend API při loginu,
/// načítání dříve uloženého stavu ze [SharedPreferences] a bezpečné odhlášení.
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

  /// Asynchronní metoda pro přihlášení komunikující s Python API.
  /// 
  /// V případě úspěchu uloží token a roli do lokální paměti, aktualizuje stav.
  /// V případě neúspěchu propustí vyhozenou výjimku.
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

  /// Bezpečně odhlásí uživatele vymazáním lokálně uložených tokenů a resetem stavu.
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_roleKey);
    await prefs.remove('username');
    state = const AuthState(isLoading: false);
  }
}

/// Globální singleton provider pro autentizaci přístupný napříč aplikací.
final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
