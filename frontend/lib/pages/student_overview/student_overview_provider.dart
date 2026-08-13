import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../services/api_client.dart';

/// Reprezentuje stav domovské obrazovky studenta (StudentOverviewPage).
/// Uchovává seznam testů, zapsaných předmětů a stav načítání.
class StudentOverviewState {
  /// Indikuje, zda právě probíhá asynchronní načítání dat.
  final bool isLoading;
  /// Případná chybová hláška zobrazená uživateli.
  final String? errorMessage;
  /// Seznam všech aktuálních testů, které studentovi poslal backend.
  final List<Map<String, dynamic>> activeTests;
  /// Seznam předmětů (skupin), ve kterých je student zapsán.
  final List<Map<String, dynamic>> mySubjects;

  StudentOverviewState({
    this.isLoading = false,
    this.errorMessage,
    this.activeTests = const [],
    this.mySubjects = const [],
  });

  /// Dynamicky vrací pouze ty testy, které jsou **v tento okamžik** reálně přístupné 
  /// k vypracování. Vyřazuje ty, které ještě nezačaly, nebo už skončily 
  /// (a nejsou ve stavu STARTED).
  List<Map<String, dynamic>> get trulyActiveTests {
    final now = DateTime.now();
    return activeTests.where((test) {
      final String? activateTo = test['rawActivateTo'];
      final String? activateFrom = test['rawActivateFrom'];
      
      if (activateFrom != null) {
        final fromDate = DateTime.parse(activateFrom.endsWith('Z') ? activateFrom : '${activateFrom}Z').toLocal();
        if (now.isBefore(fromDate)) return false;
      }
      if (activateTo != null) {
        final toDate = DateTime.parse(activateTo.endsWith('Z') ? activateTo : '${activateTo}Z').toLocal();
        if (now.isAfter(toDate)) return false;
      }

      // Test se zobrazí, pokud už byl zahájen (STARTED).
      if (test['status'] == 'STARTED') return true;
      // Pokud test už má jakýkoliv jiný stav (např. odevzdán), zobrazí se zde
      // pouze pokud má student ještě další pokusy.
      if (test['status'] != null) {
        if (test['max_attempts'] != null && test['attempts_count'] != null) {
          return (test['attempts_count'] as int) < (test['max_attempts'] as int);
        }
        return true; // Neomezeno pokusů
      } 
      
      return true;
    }).toList();
  }

  StudentOverviewState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<Map<String, dynamic>>? activeTests,
    List<Map<String, dynamic>>? mySubjects,
  }) {
    return StudentOverviewState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      activeTests: activeTests ?? this.activeTests,
      mySubjects: mySubjects ?? this.mySubjects,
    );
  }
}

/// Riverpod Notifier, který spravuje stav úvodní stránky studenta.
/// Komunikuje s API a transformuje data pro zobrazení (formátování dat, výpočty testů na předmět atd.).
class StudentOverviewNotifier extends Notifier<StudentOverviewState> {
  @override
  StudentOverviewState build() {
    return StudentOverviewState(isLoading: true);
  }

  /// Stáhne z backendu všechny potřebné údaje (testy a předměty) a transformuje je pro UI.
  Future<void> fetchDashboardData() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final apiClient = ref.read(apiClientProvider);
      
      // Pokus o stažení dat z backendu
      final response = await apiClient.get('/api/student/assignments');
      final groupsResponse = await apiClient.get('/api/student/groups');
      
      // Backend vrací list objektů
      final List<dynamic> assignmentList = response;
      final List<dynamic> groupsList = groupsResponse;
      
      final activeTestsList = assignmentList.map((assignment) {
        return {
          'id': assignment['assignment_id'],
          'title': assignment['template_name'] ?? 'Neznámý test',
          'deadline': assignment['activate_to'] != null 
              ? DateFormat('dd. MM. yyyy HH:mm').format(DateTime.parse(assignment['activate_to'].endsWith('Z') ? assignment['activate_to'] : '${assignment['activate_to']}Z').toLocal())
              : 'Bez termínu',
          'formattedActivateFrom': assignment['activate_from'] != null
              ? DateFormat('dd. MM. yyyy HH:mm').format(DateTime.parse(assignment['activate_from'].endsWith('Z') ? assignment['activate_from'] : '${assignment['activate_from']}Z').toLocal())
              : null,
          'rawActivateFrom': assignment['activate_from'],
          'rawActivateTo': assignment['activate_to'],
          'expiresIn': '${assignment['time_limit_minutes'] ?? 0} min',
          'status': assignment['status'],
          'groupName': assignment['group_name'] ?? '',
          'groupId': assignment['group_id']?.toString() ?? '',
          'questions': assignment['question_count'] ?? 0,
          'attempt_id': assignment['attempt_id'],
          'score_percent': assignment['score_percent'],
          'max_attempts': assignment['max_attempts'],
          'attempts_count': assignment['attempts_count'],
        };
      }).toList();

      final colors = [const Color(0xFF4285F4), const Color(0xFF34A853), const Color(0xFFAB47DB), const Color(0xFFF4B400)];
      final mySubjectsList = groupsList.asMap().entries.map((entry) {
        final idx = entry.key;
        final group = entry.value;
        final name = group['name'] as String? ?? 'Neznámá třída';
        final groupId = group['group_id'].toString();
        
        final now = DateTime.now();
        final testCount = activeTestsList.where((t) {
          if (t['groupId'] != groupId) return false;
          if (!(t['status'] == null || t['status'] == 'STARTED')) return false;
          
          final String? activateFrom = t['rawActivateFrom'];
          if (activateFrom != null) {
            final fromDate = DateTime.parse(activateFrom.endsWith('Z') ? activateFrom : '${activateFrom}Z').toLocal();
            if (now.isBefore(fromDate)) return false;
          }
          return true;
        }).length;
        
        return {
          'id': groupId,
          'code': name.length >= 2 ? name.substring(0, 2).toUpperCase() : name.toUpperCase(),
          'name': name,
          'teacher': group['teacher_name'] ?? 'Neznámý učitel',
          'color': colors[idx % colors.length],
          'testCount': testCount,
          'status': testCount > 0 ? 'active' : 'none',
          'timeText': '',
        };
      }).toList();

      state = state.copyWith(
        activeTests: activeTestsList,
        mySubjects: mySubjectsList,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        activeTests: [],
        mySubjects: [],
        isLoading: false,
        errorMessage: 'Nepodařilo se načíst data z API: $e',
      );
    }
  }
}

final studentOverviewProvider = NotifierProvider.autoDispose<StudentOverviewNotifier, StudentOverviewState>(() {
  return StudentOverviewNotifier();
});
