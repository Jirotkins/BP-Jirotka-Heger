import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/api_client.dart';

class TestEditorState {
  final bool isLoadingBanks;
  final String? errorMessage;
  final List<Map<String, dynamic>> banks;
  
  final Map<int, List<Map<String, dynamic>>> bankQuestionsCache;
  final Map<int, bool> bankQuestionsLoading;
  
  final Set<int> selectedQuestionIds;
  
  final Map<String, dynamic> testSettings;
  final Map<String, dynamic> timeSettings;
  
  final bool isSubmitting;
  final bool submitSuccess;

  TestEditorState({
    this.isLoadingBanks = false,
    this.errorMessage,
    this.banks = const [],
    this.bankQuestionsCache = const {},
    this.bankQuestionsLoading = const {},
    this.selectedQuestionIds = const {},
    this.testSettings = const {},
    this.timeSettings = const {},
    this.isSubmitting = false,
    this.submitSuccess = false,
  });

  TestEditorState copyWith({
    bool? isLoadingBanks,
    String? errorMessage,
    List<Map<String, dynamic>>? banks,
    Map<int, List<Map<String, dynamic>>>? bankQuestionsCache,
    Map<int, bool>? bankQuestionsLoading,
    Set<int>? selectedQuestionIds,
    Map<String, dynamic>? testSettings,
    Map<String, dynamic>? timeSettings,
    bool? isSubmitting,
    bool? submitSuccess,
    bool clearError = false,
  }) {
    return TestEditorState(
      isLoadingBanks: isLoadingBanks ?? this.isLoadingBanks,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      banks: banks ?? this.banks,
      bankQuestionsCache: bankQuestionsCache ?? this.bankQuestionsCache,
      bankQuestionsLoading: bankQuestionsLoading ?? this.bankQuestionsLoading,
      selectedQuestionIds: selectedQuestionIds ?? this.selectedQuestionIds,
      testSettings: testSettings ?? this.testSettings,
      timeSettings: timeSettings ?? this.timeSettings,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitSuccess: submitSuccess ?? false,
    );
  }
}

class TestEditorNotifier extends Notifier<TestEditorState> {
  @override
  TestEditorState build() {
    return TestEditorState();
  }

  Future<void> fetchBanks() async {
    state = state.copyWith(isLoadingBanks: true, clearError: true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final data = await apiClient.get('/banks');
      
      final banksList = data['banks'] as List? ?? [];
      final parsedBanks = banksList.map((b) => {
        'id': b['bank_id'],
        'name': b['name'] ?? 'Neznámá banka',
      }).toList();

      state = state.copyWith(banks: parsedBanks, isLoadingBanks: false);
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Chyba při načítání bank: $e',
        isLoadingBanks: false,
      );
    }
  }

  Future<void> fetchQuestionsForBank(int bankId) async {
    if (state.bankQuestionsCache.containsKey(bankId) || state.bankQuestionsLoading[bankId] == true) {
      return;
    }

    final newLoading = Map<int, bool>.from(state.bankQuestionsLoading);
    newLoading[bankId] = true;
    state = state.copyWith(bankQuestionsLoading: newLoading);

    try {
      final apiClient = ref.read(apiClientProvider);
      final data = await apiClient.get('/banks/$bankId/questions');
      
      final questionsList = data['questions'] as List? ?? [];
      final parsedQuestions = questionsList.map((q) => {
        'id': q['question_id'],
        'question': q['text'] ?? 'Prázdná otázka',
        'type': q['type'] ?? 'Neznámý typ',
      }).toList();

      final newCache = Map<int, List<Map<String, dynamic>>>.from(state.bankQuestionsCache);
      newCache[bankId] = parsedQuestions;
      
      final updatedLoading = Map<int, bool>.from(state.bankQuestionsLoading);
      updatedLoading[bankId] = false;

      state = state.copyWith(
        bankQuestionsCache: newCache,
        bankQuestionsLoading: updatedLoading,
      );
    } catch (e) {
      final updatedLoading = Map<int, bool>.from(state.bankQuestionsLoading);
      updatedLoading[bankId] = false;
      state = state.copyWith(
        bankQuestionsLoading: updatedLoading,
      );
    }
  }

  void toggleQuestionSelection(int questionId) {
    final newSelected = Set<int>.from(state.selectedQuestionIds);
    if (newSelected.contains(questionId)) {
      newSelected.remove(questionId);
    } else {
      newSelected.add(questionId);
    }
    state = state.copyWith(selectedQuestionIds: newSelected);
  }

  void updateTestSettings(Map<String, dynamic> settings) {
    state = state.copyWith(testSettings: settings);
  }

  void updateTimeSettings(Map<String, dynamic> settings) {
    state = state.copyWith(timeSettings: settings);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  Future<void> submitTest(int groupId, String testName) async {
    if (testName.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Zadejte název testu.');
      return;
    }
    if (state.selectedQuestionIds.isEmpty) {
      state = state.copyWith(errorMessage: 'Vyberte alespoň jednu otázku do testu.');
      return;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      final apiClient = ref.read(apiClientProvider);
      
      List<Map<String, dynamic>> questionsPayload = [];
      int pos = 1;
      for (int qId in state.selectedQuestionIds) {
        questionsPayload.add({
          "question_id": qId,
          "position": pos++,
          "points_custom": null 
        });
      }

      final templateData = {
        "name": testName.trim(),
        "description": "",
        "difficulty": "MEDIUM",
        "estimated_duration_minutes": state.timeSettings['durationMinutes'] ?? 45,
        "is_active": true,
        "settings": state.testSettings,
        "questions": questionsPayload
      };

      final templateResponse = await apiClient.post('/test-templates', templateData);
      final templateId = templateResponse['template_id'];

      String? activateFromStr;
      String? activateToStr;

      if (state.timeSettings['isInstant'] == true) {
        final now = DateTime.now().toUtc();
        activateFromStr = "${now.toIso8601String().split('.')[0]}Z";
        
        final durationMinutes = state.timeSettings['durationMinutes'] as int? ?? 45;
        final end = now.add(Duration(minutes: durationMinutes));
        activateToStr = "${end.toIso8601String().split('.')[0]}Z";
      } else {
         if (state.timeSettings['startDate'] != null && state.timeSettings['startTime'] != null) {
             final d = DateTime.parse(state.timeSettings['startDate']);
             final parts = (state.timeSettings['startTime'] as String).split(':');
             final h = int.parse(parts[0]);
             final m = int.parse(parts[1]);
             final combined = DateTime(d.year, d.month, d.day, h, m).toUtc();
             activateFromStr = "${combined.toIso8601String().split('.')[0]}Z";
         }
         if (state.timeSettings['endDate'] != null && state.timeSettings['endTime'] != null) {
             final d = DateTime.parse(state.timeSettings['endDate']);
             final parts = (state.timeSettings['endTime'] as String).split(':');
             final h = int.parse(parts[0]);
             final m = int.parse(parts[1]);
             final combined = DateTime(d.year, d.month, d.day, h, m).toUtc();
             activateToStr = "${combined.toIso8601String().split('.')[0]}Z";
         }
      }

      final assignData = {
        "template_id": templateId,
        "activate_from": activateFromStr,
        "activate_to": activateToStr,
        "time_limit_minutes": state.timeSettings['durationMinutes'] ?? 45,
        "access_password": null
      };

      await apiClient.post('/groups/$groupId/exam-assignments', assignData);

      state = state.copyWith(isSubmitting: false, submitSuccess: true);
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Chyba při zadávání testu: $e',
        isSubmitting: false,
      );
    }
  }
}

final testEditorProvider = NotifierProvider.autoDispose<TestEditorNotifier, TestEditorState>(() {
  return TestEditorNotifier();
});
