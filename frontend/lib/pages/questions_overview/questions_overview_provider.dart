import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/api_client.dart';

class QuestionsOverviewState {
  final bool isLoading;
  final String? errorMessage;
  final List<Map<String, dynamic>> questions;
  final int bankId;

  QuestionsOverviewState({
    this.isLoading = false,
    this.errorMessage,
    this.questions = const [],
    this.bankId = 0,
  });

  QuestionsOverviewState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<Map<String, dynamic>>? questions,
    int? bankId,
    bool clearError = false,
  }) {
    return QuestionsOverviewState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      questions: questions ?? this.questions,
      bankId: bankId ?? this.bankId,
    );
  }
}

class QuestionsOverviewNotifier extends Notifier<QuestionsOverviewState> {
  @override
  QuestionsOverviewState build() {
    return QuestionsOverviewState(isLoading: true);
  }

  Future<void> fetchQuestions(int bankId) async {
    if (bankId == 0) {
      state = state.copyWith(isLoading: false, bankId: 0);
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true, bankId: bankId);

    try {
      final apiClient = ref.read(apiClientProvider);
      final data = await apiClient.get('/banks/$bankId/questions');
      
      final questionsList = data['questions'] as List? ?? [];
      final questionsData = questionsList.map((q) {
        return {
          'id': q['question_id'],
          'question': q['text'] ?? 'Prázdná otázka',
          'type': q['type'] ?? 'Neznámý typ',
          'raw': q,
        };
      }).toList();

      state = state.copyWith(
        questions: questionsData,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Chyba při načítání otázek: $e',
        isLoading: false,
      );
    }
  }

  Future<String?> deleteQuestion(int questionId, {bool force = false}) async {
    if (state.bankId == 0) return 'Banka nenalezena';
    
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.delete('/banks/${state.bankId}/questions/$questionId${force ? '?force=true' : ''}');
      
      // Znovu načíst seznam
      await fetchQuestions(state.bankId);
      return null;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      
      if (e is ApiException && e.statusCode == 409) {
        return 'IN_USE';
      }
      
      state = state.copyWith(errorMessage: 'Chyba při mazání otázky: $e');
      return e.toString();
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
  
  void refresh() {
    if (state.bankId != 0) {
      fetchQuestions(state.bankId);
    }
  }
}

final questionsOverviewProvider = NotifierProvider.autoDispose<QuestionsOverviewNotifier, QuestionsOverviewState>(() {
  return QuestionsOverviewNotifier();
});
