import 'package:flutter/material.dart' hide Notifier;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/api_client.dart';

class StudentOverviewState {
  final bool isLoading;
  final String? errorMessage;
  final List<Map<String, dynamic>> activeTests;
  final List<Map<String, dynamic>> mySubjects;

  StudentOverviewState({
    this.isLoading = false,
    this.errorMessage,
    this.activeTests = const [],
    this.mySubjects = const [],
  });

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

class StudentOverviewNotifier extends Notifier<StudentOverviewState> {
  @override
  StudentOverviewState build() {
    return StudentOverviewState(isLoading: true);
  }

  Future<void> fetchDashboardData() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final apiClient = ref.read(apiClientProvider);
      
      // Pokus o stažení dat z backendu (endpoint momentálně neexistuje)
      final response = await apiClient.get('/student/dashboard');
      
      state = state.copyWith(
        activeTests: List<Map<String, dynamic>>.from(response['active_tests'] ?? []),
        mySubjects: List<Map<String, dynamic>>.from(response['subjects'] ?? []),
        isLoading: false,
      );
    } catch (e) {
      // Fallback
      _useFallbackMockData();
    }
  }

  void _useFallbackMockData() {
    state = state.copyWith(
      activeTests: [
        {
          'id': 999, // ID přiřazení (assignmentId)
          'title': 'Matematika – Funkce',
          'deadline': 'Dnes 23:59',
          'expiresIn': '45 min',
        }
      ],
      mySubjects: [
        {
          'id': 'sub_1', 'code': 'MA', 'name': 'Matematika', 'teacher': 'Ing. Petr Svoboda', 
          'color': const Color(0xFF4285F4), 'testCount': 3, 'status': 'active', 'timeText': 'Vyprší 45 min'
        },
        {
          'id': 'sub_2', 'code': 'FY', 'name': 'Fyzika', 'teacher': 'doc. Jana Horáková', 
          'color': const Color(0xFF34A853), 'testCount': 2, 'status': 'upcoming', 'timeText': 'Za 2 dny'
        },
        {
          'id': 'sub_3', 'code': 'CH', 'name': 'Chemie', 'teacher': 'Mgr. Tomáš Blažek', 
          'color': const Color(0xFFAB47DB), 'testCount': 4, 'status': 'none', 'timeText': 'Vše ohodnoceno'
        },
      ],
      isLoading: false,
      errorMessage: 'Nepodařilo se načíst data z API, používám ukázková data.',
    );
  }
}

final studentOverviewProvider = NotifierProvider.autoDispose<StudentOverviewNotifier, StudentOverviewState>(() {
  return StudentOverviewNotifier();
});
