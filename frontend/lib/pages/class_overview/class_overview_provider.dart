import 'dart:convert';
import 'package:flutter/material.dart' hide Notifier;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/api_client.dart';

class ClassOverviewState {
  final bool isLoading;
  final String? errorMessage;
  final List<dynamic> groups;

  ClassOverviewState({
    this.isLoading = false,
    this.errorMessage,
    this.groups = const [],
  });

  ClassOverviewState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<dynamic>? groups,
    bool clearError = false,
  }) {
    return ClassOverviewState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      groups: groups ?? this.groups,
    );
  }
}

class ClassOverviewNotifier extends Notifier<ClassOverviewState> {
  @override
  ClassOverviewState build() {
    return ClassOverviewState(isLoading: true);
  }

  Future<void> fetchGroups() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.get('/groups');
      state = state.copyWith(
        groups: response['groups'] ?? [],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString(),
        isLoading: false,
      );
    }
  }

  Future<void> addGroup(String name, String subject, IconData icon) async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      final apiClient = ref.read(apiClientProvider);
      
      final descriptionData = {
        "subject": subject.trim().isEmpty ? 'Předmět neuveden' : subject.trim(),
        "icon": icon.codePoint.toString(),
      };

      await apiClient.post('/groups', {
        'name': name.trim(),
        'description': jsonEncode(descriptionData),
      });

      // Znovu načíst třídy po přidání
      await fetchGroups();
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Chyba při přidávání třídy: $e',
        isLoading: false,
      );
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final classOverviewProvider = NotifierProvider.autoDispose<ClassOverviewNotifier, ClassOverviewState>(() {
  return ClassOverviewNotifier();
});
