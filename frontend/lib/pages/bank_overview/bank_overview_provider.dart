import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/api_client.dart';

/// Reprezentuje aktuální stav seznamu bank (skupin) otázek.
class BankOverviewState {
  /// Udává, zda právě probíhá síťová komunikace (např. stahování).
  final bool isLoading;
  
  /// Chybová hláška v případě selhání HTTP požadavku. Jinak null.
  final String? errorMessage;
  
  /// Seznam bank zformátovaný pro okamžité zobrazení v UI.
  final List<Map<String, dynamic>> banks;

  BankOverviewState({
    this.isLoading = false,
    this.errorMessage,
    this.banks = const [],
  });

  /// Vytvoří kopii aktuálního stavu s možností změnit vybrané hodnoty.
  /// Pomocí [clearError] lze explicitně smazat chybovou hlášku.
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

/// Správce stavu (Notifier) řídící operace nad seznamem bank.
class BankOverviewNotifier extends Notifier<BankOverviewState> {
  /// Předdefinovaný seznam ikon, ze kterých si uživatel může vybrat.
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

  /// Stáhne seznam všech vytvořených bank z backendu a zpracuje metadata.
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
          'iconIndex': iconIndex,
          'questionCount': b['questionCount'] ?? 0,
        });
      }

      banksData.sort((a, b) => (a['id'] as int).compareTo(b['id'] as int));

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

  /// Vytvoří zbrusu novou banku na backendu a znovunačte seznam.
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

  /// Pokusí se smazat banku s daným [bankId]. 
  /// Vrací [null] v případě úspěchu, jinak řetězec s chybou.
  /// Specificky vrací 'IN_USE', pokud backend nahlásí konflikt (HTTP 409).
  Future<String?> deleteBank(int bankId) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.delete('/banks/$bankId');
      
      await fetchBanks();
      return null;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      
      if (e is ApiException && e.statusCode == 409) {
        return 'IN_USE';
      }
      
      state = state.copyWith(errorMessage: 'Chyba při mazání banky: $e');
      return e.toString();
    }
  }

  /// Aktualizuje údaje u stávající banky na backendu a znovunačte seznam.
  Future<void> updateBank(int bankId, String name, String subject, int iconIndex) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final apiClient = ref.read(apiClientProvider);
      final descriptionData = {
        'subject': subject,
        'iconIndex': iconIndex,
      };

      await apiClient.put('/banks/$bankId', {
        'name': name.trim(),
        'description': jsonEncode(descriptionData),
        'is_public': false
      });

      await fetchBanks();
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Chyba při úpravě banky: $e',
        isLoading: false,
      );
    }
  }

  /// Smaže aktuálně nastavenou chybovou hlášku.
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

/// Globálně dostupný provider poskytující přístup ke správci seznamu bank.
final bankOverviewProvider = NotifierProvider.autoDispose<BankOverviewNotifier, BankOverviewState>(() {
  return BankOverviewNotifier();
});
