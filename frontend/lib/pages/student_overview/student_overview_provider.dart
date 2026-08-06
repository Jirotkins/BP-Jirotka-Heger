import 'package:flutter/material.dart' hide Notifier;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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
          'rawActivateFrom': assignment['activate_from'],
          'rawActivateTo': assignment['activate_to'],
          'expiresIn': '${assignment['time_limit_minutes'] ?? 0} min',
          'status': assignment['status'],
          'groupName': assignment['group_name'] ?? '',
          'groupId': assignment['group_id']?.toString() ?? '',
          'questions': assignment['question_count'] ?? 0,
          'attempt_id': assignment['attempt_id'],
        };
      }).toList();

      final colors = [const Color(0xFF4285F4), const Color(0xFF34A853), const Color(0xFFAB47DB), const Color(0xFFF4B400)];
      final mySubjectsList = groupsList.asMap().entries.map((entry) {
        final idx = entry.key;
        final group = entry.value;
        final name = group['name'] as String? ?? 'Neznámá třída';
        final groupId = group['group_id'].toString();
        
        final testCount = activeTestsList.where((t) => t['groupId'] == groupId).length;
        
        return {
          'id': groupId,
          'code': name.length >= 2 ? name.substring(0, 2).toUpperCase() : name.toUpperCase(),
          'name': name,
          'teacher': group['teacher_name'] ?? 'Neznámý učitel',
          'color': colors[idx % colors.length],
          'testCount': testCount,
          'status': 'active',
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
