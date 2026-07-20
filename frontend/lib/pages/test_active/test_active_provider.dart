import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/api_client.dart';

class TestActiveState {
  final bool isLoading;
  final String? errorMessage;
  
  final List<Map<String, dynamic>> questions;
  final int currentIndex;
  final Map<int, dynamic> selectedAnswers;
  
  final int remainingSeconds;
  
  final bool isExiting;
  final bool submitSuccess;

  TestActiveState({
    this.isLoading = true,
    this.errorMessage,
    this.questions = const [],
    this.currentIndex = 0,
    this.selectedAnswers = const {},
    this.remainingSeconds = 0,
    this.isExiting = false,
    this.submitSuccess = false,
  });

  TestActiveState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<Map<String, dynamic>>? questions,
    int? currentIndex,
    Map<int, dynamic>? selectedAnswers,
    int? remainingSeconds,
    bool? isExiting,
    bool? submitSuccess,
    bool clearError = false,
  }) {
    return TestActiveState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      selectedAnswers: selectedAnswers ?? this.selectedAnswers,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isExiting: isExiting ?? this.isExiting,
      submitSuccess: submitSuccess ?? false,
    );
  }
}

class TestActiveNotifier extends Notifier<TestActiveState> {
  Timer? _timer;
  int? _assignmentId;

  // Mock fallback
  final List<Map<String, dynamic>> _mockQuestions = [
    {
      "id": "q1",
      "type": "choice",
      "text": "Co je energetickým centrem buňky?",
      "options": [
        {"letter": "A", "text": "Jádro"},
        {"letter": "B", "text": "Mitochondrie"},
        {"letter": "C", "text": "Ribozom"},
        {"letter": "D", "text": "Chloroplast"}
      ]
    },
    {
      "id": "q2",
      "type": "open",
      "text": "Stručně popište funkci buněčné membrány.",
    },
    {
      "id": "q3",
      "type": "short_answer",
      "text": "Jak se nazývá proces dělení tělních buněk?",
    },
    {
      "id": "q4",
      "type": "order",
      "text": "Seřaďte fáze buněčného cyklu (mitózy) ve správném pořadí.",
      "items": ["Telofáze", "Profáze", "Anafáze", "Metafáze"],
    },
    {
      "id": "q5",
      "type": "match",
      "text": "Přiřaďte buněčné organely k jejich správným funkcím.",
      "leftItems": ["Ribozom", "Chloroplast", "Jádro"],
      "rightItems": ["Uchování DNA", "Syntéza bílkovin", "Fotosyntéza"],
    }
  ];

  @override
  TestActiveState build() {
    ref.onDispose(() {
      _timer?.cancel();
    });
    return TestActiveState();
  }

  Future<void> fetchTest(int? assignmentId) async {
    _assignmentId = assignmentId;
    if (assignmentId == null) {
      _useFallbackMockData('Chybí ID přiřazení testu.');
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.get('/exam-assignments/$assignmentId/take');
      
      final questions = List<Map<String, dynamic>>.from(response['questions'] ?? []);
      int limitMinutes = response['time_limit_minutes'] ?? 0;
      
      state = state.copyWith(
        questions: questions,
        remainingSeconds: limitMinutes > 0 ? limitMinutes * 60 : 0,
        isLoading: false,
      );

      _startTimer();
    } catch (e) {
      _useFallbackMockData('Nepodařilo se načíst test ze serveru ($e). Používám ukázková data.');
    }
  }

  void _useFallbackMockData(String message) {
    state = state.copyWith(
      questions: List<Map<String, dynamic>>.from(_mockQuestions),
      remainingSeconds: 5 * 60, // 5 minut fallback
      isLoading: false,
      errorMessage: message,
    );
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    if (state.remainingSeconds <= 0) return;
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingSeconds > 0) {
        state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
      } else {
        _timer?.cancel();
        submitTest(autoSubmit: true);
      }
    });
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void updateAnswer(dynamic answerData) {
    final newAnswers = Map<int, dynamic>.from(state.selectedAnswers);
    newAnswers[state.currentIndex] = answerData;
    state = state.copyWith(selectedAnswers: newAnswers);
  }

  void nextQuestion() {
    if (state.currentIndex < state.questions.length - 1) {
      state = state.copyWith(currentIndex: state.currentIndex + 1);
    }
  }

  void previousQuestion() {
    if (state.currentIndex > 0) {
      state = state.copyWith(currentIndex: state.currentIndex - 1);
    }
  }

  void setExiting(bool isExiting) {
    state = state.copyWith(isExiting: isExiting);
  }

  Future<void> submitTest({bool autoSubmit = false}) async {
    state = state.copyWith(isLoading: true); 
    
    if (_assignmentId != null) {
      try {
        final apiClient = ref.read(apiClientProvider);
        
        List<Map<String, dynamic>> answersPayload = [];
        state.selectedAnswers.forEach((index, answerData) {
          final questionId = state.questions[index]['id'] ?? state.questions[index]['question_id'];
          answersPayload.add({
            "question_id": questionId,
            "answer_data": answerData,
          });
        });

        await apiClient.post('/exam-assignments/$_assignmentId/attempts', {
          "answers": answersPayload
        });

        state = state.copyWith(
          isExiting: true, 
          submitSuccess: true, 
          isLoading: false
        );
      } catch (e) {
        state = state.copyWith(
          isExiting: true,
          errorMessage: 'Endpoint pro odevzdání chybí. Odpovědi: ${state.selectedAnswers}',
          isLoading: false,
        );
      }
    } else {
      state = state.copyWith(isExiting: true, isLoading: false);
    }
  }
}

final testActiveProvider = NotifierProvider.autoDispose<TestActiveNotifier, TestActiveState>(() {
  return TestActiveNotifier();
});
