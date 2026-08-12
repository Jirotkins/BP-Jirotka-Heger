import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/api_client.dart';

/// Představuje stav obrazovky "Moje třídy" (Class Overview).
class ClassOverviewState {
  /// Určuje, zda aktuálně probíhá načítání nebo komunikace s API.
  final bool isLoading;
  
  /// Chybová zpráva, pokud nějaká operace selhala. Jinak null.
  final String? errorMessage;
  
  /// Seznam načtených tříd (skupin).
  final List<dynamic> groups;

  ClassOverviewState({
    this.isLoading = false,
    this.errorMessage,
    this.groups = const [],
  });

  /// Vytvoří kopii aktuálního stavu s možností změnit vybrané hodnoty.
  /// Pomocí [clearError] lze explicitně vymazat aktuální chybu.
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

/// Správce stavu (Notifier) pro obrazovku "Moje třídy".
/// Zajišťuje načítání, přidávání, úpravu a mazání tříd pomocí volání [apiClientProvider].
class ClassOverviewNotifier extends Notifier<ClassOverviewState> {
  @override
  ClassOverviewState build() {
    return ClassOverviewState(isLoading: true);
  }

  /// Stáhne seznam všech tříd (skupin) z API a uloží je do stavu.
  /// 
  /// Třídy jsou po stažení seřazeny vzestupně podle svého `group_id`.
  Future<void> fetchGroups() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.get('/groups');
      final List<dynamic> fetchedGroups = response['groups'] ?? [];
      fetchedGroups.sort((a, b) => (a['group_id'] as int).compareTo(b['group_id'] as int));

      state = state.copyWith(
        groups: fetchedGroups,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString(),
        isLoading: false,
      );
    }
  }

  /// Vytvoří novou třídu v systému.
  /// 
  /// [name] je primární název třídy.
  /// [subject] a [icon] se zakódují do JSON řetězce a uloží do atributu `description`.
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

      // Znovu načíst třídy po úspěšném přidání
      await fetchGroups();
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Chyba při přidávání třídy: $e',
        isLoading: false,
      );
    }
  }

  /// Smaže třídu s daným [groupId].
  Future<void> deleteGroup(int groupId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.delete('/groups/$groupId');
      
      // Znovu načíst třídy po úspěšném smazání
      await fetchGroups();
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Chyba při mazání třídy: $e',
        isLoading: false,
      );
    }
  }

  /// Upraví existující třídu identifikovanou pomocí [groupId].
  /// 
  /// Pokud je třída upravena úspěšně, seznam tříd se znovu načte.
  Future<void> updateGroup(int groupId, String name, String subject, IconData icon) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final descriptionData = {
        "subject": subject.trim().isEmpty ? 'Předmět neuveden' : subject.trim(),
        "icon": icon.codePoint.toString(),
      };
      
      await apiClient.put('/groups/$groupId', {
        'name': name.trim(),
        'description': jsonEncode(descriptionData),
      });

      await fetchGroups();
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Chyba při úpravě třídy: $e',
        isLoading: false,
      );
    }
  }

  /// Vymaže chybovou hlášku ve stavu (např. poté, co byla zobrazena uživateli).
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

/// Globálně dostupný provider pro [ClassOverviewNotifier].
final classOverviewProvider = NotifierProvider.autoDispose<ClassOverviewNotifier, ClassOverviewState>(() {
  return ClassOverviewNotifier();
});
