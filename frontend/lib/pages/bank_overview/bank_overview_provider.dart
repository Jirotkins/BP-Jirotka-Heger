import 'dart:convert';
import 'package:flutter/material.dart' hide Notifier;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/api_client.dart';

class BankOverviewState {
  final bool isLoading;
  final String? errorMessage;
  final List<Map<String, dynamic>> banks;

  BankOverviewState({
    this.isLoading = false,
    this.errorMessage,
    this.banks = const [],
  });

  BankOverviewState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<Map<String, dynamic>>? banks,
    bool clearError = false,
  }) {
    return BankOverviewState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      banks: banks ?? this.banks,
    );
  }
}

class BankOverviewNotifier extends Notifier<BankOverviewState> {
  final List<IconData> availableIcons = [
    Icons.menu_book_outlined,
    Icons.calculate_outlined,
    Icons.science_outlined,
    Icons.history_edu_outlined,
    Icons.public_outlined,
  ];

  @override
  BankOverviewState build() {
    return BankOverviewState(isLoading: true);
  }

  Future<void> fetchBanks() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final apiClient = ref.read(apiClientProvider);
      final data = await apiClient.get('/banks');
      
      final banksList = data['banks'] as List;
      final banksData = <Map<String, dynamic>>[];
      
      for (var b in banksList) {
        String subject = 'Neznámý předmět';
        int iconIndex = 0;
        try {
          final desc = json.decode(b['description'] ?? '{}');
          subject = desc['subject'] ?? 'Neznámý předmět';
          iconIndex = desc['iconIndex'] ?? 0;
        } catch (_) {
          subject = b['description'] ?? 'Neznámý předmět';
        }
        
        if (iconIndex < 0 || iconIndex >= availableIcons.length) {
          iconIndex = 0;
        }

        banksData.add({
          'id': b['bank_id'],
          'title': b['name'] ?? 'Neznámý název',
          'subject': subject,
          'icon': availableIcons[iconIndex],
          'questionCount': 0, // Backend zatím nevrací počet otázek v tomto endpointu
        });
      }

      state = state.copyWith(
        banks: banksData,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Chyba při načítání bank: $e',
        isLoading: false,
      );
    }
  }

  Future<void> addBank(String name, String subject, int iconIndex) async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      final apiClient = ref.read(apiClientProvider);
      
      final descriptionData = {
        "subject": subject.trim().isEmpty ? 'Předmět neuveden' : subject.trim(),
        "iconIndex": iconIndex,
      };

      await apiClient.post('/banks', {
        'name': name.trim(),
        'description': jsonEncode(descriptionData),
        'is_public': false
      });

      // Znovu načíst po přidání
      await fetchBanks();
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Chyba při přidávání banky: $e',
        isLoading: false,
      );
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final bankOverviewProvider = NotifierProvider.autoDispose<BankOverviewNotifier, BankOverviewState>(() {
  return BankOverviewNotifier();
});
