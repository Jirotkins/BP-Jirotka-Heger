import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  const AuthState({
    this.role = UserRole.guest,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    UserRole? role,
    bool? isAuthenticated,
  }) {
    return AuthState(
      role: role ?? this.role,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

// Notifier pro správu stavu přihlášení
class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    return const AuthState();
  }

  // Metoda pro přihlášení (zatím mockovaná pro UI)
  void login(bool isStudent) {
    state = state.copyWith(
      isAuthenticated: true,
      role: isStudent ? UserRole.student : UserRole.teacher,
    );
  }

  // Metoda pro odhlášení
  void logout() {
    state = const AuthState();
  }
}

// Globální provider
final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
