import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/api_client.dart';

/// Stav pro obrazovku správy třídy.
class ClassManagerState {
  /// Určuje, zda aktuálně probíhá načítání dat ze serveru.
  final bool isLoading;
  
  /// Chybová zpráva, pokud nějaká operace selhala. Jinak null.
  final String? errorMessage;
  
  /// Mapa obsahující testy roztříděné do kategorií (např. 'active', 'upcoming', 'finished').
  final Map<String, dynamic>? overviewData;
  
  /// Seznam studentů v této třídě.
  final List<dynamic> studentsData;
  
  /// ID aktuálně spravované třídy.
  final int? groupId;

  ClassManagerState({
    this.isLoading = false,
    this.errorMessage,
    this.overviewData,
    this.studentsData = const [],
    this.groupId,
  });

  /// Vytvoří kopii aktuálního stavu s možností změnit vybrané hodnoty.
  /// Pomocí [clearError] lze explicitně vymazat chybovou hlášku.
  ClassManagerState copyWith({
    bool? isLoading,
    String? errorMessage,
    Map<String, dynamic>? overviewData,
    List<dynamic>? studentsData,
    int? groupId,
    bool clearError = false,
  }) {
    return ClassManagerState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      overviewData: overviewData ?? this.overviewData,
      studentsData: studentsData ?? this.studentsData,
      groupId: groupId ?? this.groupId,
    );
  }
}

/// Správce stavu (Notifier) pro obrazovku správy třídy.
class ClassManagerNotifier extends Notifier<ClassManagerState> {
  @override
  ClassManagerState build() {
    return ClassManagerState(isLoading: true);
  }

  /// Načte data studentů a testů pro zadanou třídu [groupId].
  Future<void> fetchData(int groupId) async {
    state = state.copyWith(isLoading: true, groupId: groupId, clearError: true);

    try {
      final apiClient = ref.read(apiClientProvider);
      
      final results = await Future.wait([
        apiClient.get('/groups/$groupId/exam-assignments/overview'),
        apiClient.get('/groups/$groupId/students'),
      ]);
      
      state = state.copyWith(
        overviewData: results[0] as Map<String, dynamic>?,
        studentsData: (results[1] as Map<String, dynamic>)['students'] as List<dynamic>? ?? [],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString(),
        isLoading: false,
      );
    }
  }

  /// Aktivuje (spustí) dříve naplánovaný test s daným [assignmentId].
  Future<void> activateTest(int assignmentId) async {
    if (state.groupId == null) return;
    
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      await ref.read(apiClientProvider).post('/exam-assignments/$assignmentId/activate', {});
      await fetchData(state.groupId!);
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Chyba při aktivaci testu: $e',
        isLoading: false,
      );
    }
  }

  /// Odebere studenta s daným [studentId] ze zobrazené třídy.
  Future<void> removeStudent(int studentId) async {
    if (state.groupId == null) return;
    
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      await ref.read(apiClientProvider).delete('/groups/${state.groupId}/students/$studentId');
      await fetchData(state.groupId!);
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Chyba při odebírání studenta ze třídy: $e',
        isLoading: false,
      );
    }
  }

  /// Nastaví chybu v případě, že chybí [groupId] nutné pro načtení dat.
  void setGroupMissingError() {
    state = state.copyWith(
      isLoading: false,
      errorMessage: 'Nebylo zadáno ID třídy (groupId).',
    );
  }
  
  /// Vymaže chybovou hlášku ve stavu (např. poté, co byla zobrazena uživateli).
  void clearError() {
    state = state.copyWith(clearError: true);
  }
  
  /// Znovu načte data pro právě vybranou třídu.
  void refresh() {
    if (state.groupId != null) {
      fetchData(state.groupId!);
    }
  }
}

/// Globálně dostupný provider pro [ClassManagerNotifier].
final classManagerProvider = NotifierProvider.autoDispose<ClassManagerNotifier, ClassManagerState>(() {
  return ClassManagerNotifier();
});
