import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/api_client.dart';

class ClassManagerState {
  final bool isLoading;
  final String? errorMessage;
  final Map<String, dynamic>? overviewData;
  final List<dynamic> studentsData;
  final int? groupId;

  ClassManagerState({
    this.isLoading = false,
    this.errorMessage,
    this.overviewData,
    this.studentsData = const [],
    this.groupId,
  });

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

class ClassManagerNotifier extends Notifier<ClassManagerState> {
  @override
  ClassManagerState build() {
    return ClassManagerState(isLoading: true);
  }

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

  void setGroupMissingError() {
    state = state.copyWith(
      isLoading: false,
      errorMessage: 'Nebylo zadáno ID třídy (groupId).',
    );
  }
  
  void clearError() {
    state = state.copyWith(clearError: true);
  }
  
  void refresh() {
    if (state.groupId != null) {
      fetchData(state.groupId!);
    }
  }
}

final classManagerProvider = NotifierProvider.autoDispose<ClassManagerNotifier, ClassManagerState>(() {
  return ClassManagerNotifier();
});
