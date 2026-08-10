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

  final bool showImmediateFeedback;
  final Map<String, String> questionFeedback;
  final bool canGoBack;

  TestActiveState({
    this.isLoading = true,
    this.errorMessage,
    this.questions = const [],
    this.currentIndex = 0,
    this.selectedAnswers = const {},
    this.remainingSeconds = 0,
    this.isExiting = false,
    this.submitSuccess = false,
    this.showImmediateFeedback = false,
    this.questionFeedback = const {},
    this.canGoBack = true,
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
    bool? showImmediateFeedback,
    Map<String, String>? questionFeedback,
    bool? canGoBack,
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
      showImmediateFeedback: showImmediateFeedback ?? this.showImmediateFeedback,
      questionFeedback: questionFeedback ?? this.questionFeedback,
      canGoBack: canGoBack ?? this.canGoBack,
    );
  }
}

class TestActiveNotifier extends Notifier<TestActiveState> {
  Timer? _timer;
  StreamSubscription? _sseSubscription;


  int? _attemptId;
  @override
  TestActiveState build() {
    ref.onDispose(() {
      _timer?.cancel();
      _sseSubscription?.cancel();
    });
    return TestActiveState();
  }

  Future<void> fetchTest(int? assignmentId) async {

    if (assignmentId == null) {
      _showError('Chybí ID přiřazení testu.');
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.post('/api/student/assignments/$assignmentId/start', {});
      
      _attemptId = response['attempt_id'];
      final rawQuestions = List<Map<String, dynamic>>.from(response['questions_snapshot'] ?? []);
      final questions = rawQuestions.map((q) {
        var mapped = Map<String, dynamic>.from(q);
        var answers = List<Map<String, dynamic>>.from(mapped['answers'] ?? []);
        
        if (mapped['type'] == 'SINGLE_CHOICE' || mapped['type'] == 'MULTI_CHOICE') {
          int letterCode = 65; // Začínáme od 'A'
          mapped['options'] = answers.map((a) {
            final res = {
              'id': a['answer_id'].toString(), // ID odpovědi pro uložení
              'letter': String.fromCharCode(letterCode), // 'A', 'B', 'C' atd.
              'text': a['text'],
            };
            letterCode++;
            return res;
          }).toList();
        } else if (mapped['type'] == 'ORDERING') {
          mapped['items'] = answers.map((a) => a['text'].toString()).toList();
          (mapped['items'] as List).shuffle();
        } else if (mapped['type'] == 'MATCHING' || mapped['type'] == 'match') {
          List<String> left = [];
          List<String> right = [];
          for (var a in answers) {
            final t = a['text'].toString();
            if (t.contains('|||')) {
              final parts = t.split('|||');
              left.add(parts[0].trim());
              right.add(parts[1].trim());
            } else {
              left.add(t);
              right.add(t);
            }
          }
          mapped['leftItems'] = left;
          right.shuffle();
          mapped['rightItems'] = right;
        }
        
        return mapped;
      }).toList();
      
      // Pokusí se najít časový limit z původního assignmentu
      // Pokud ho backend v 'response' neposílá, tak tu dá fallback
      int limitMinutes = response['time_limit_minutes'] ?? 0;
      int remaining = limitMinutes > 0 ? limitMinutes * 60 : 0;
      
      if (limitMinutes > 0 && response['started_at'] != null) {
        String startedStr = response['started_at'];
        if (!startedStr.endsWith('Z')) startedStr += 'Z';
        final startedAt = DateTime.parse(startedStr).toLocal();
        final now = DateTime.now();
        final elapsed = now.difference(startedAt).inSeconds;
        remaining = remaining - elapsed;
        if (remaining < 0) remaining = 0;
      }
      
      bool showFeedback = response['show_immediate_feedback'] ?? false;
      bool canGoBack = response['can_go_back'] ?? true;

      state = state.copyWith(
        questions: questions,
        remainingSeconds: remaining,
        isLoading: false,
        showImmediateFeedback: showFeedback,
        canGoBack: canGoBack,
      );

      if (showFeedback && _attemptId != null) {
        _startSseListener();
      }

      _startTimer();
    } catch (e) {
      _showError('Nepodařilo se načíst test ze serveru: $e');
    }
  }

  void _showError(String message) {
    state = state.copyWith(
      questions: [],
      remainingSeconds: 0,
      isLoading: false,
      errorMessage: message,
    );
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

  void _startSseListener() {
    final apiClient = ref.read(apiClientProvider);
    _sseSubscription?.cancel();
    _sseSubscription = apiClient.listenSse('/api/sse/student/attempts/$_attemptId/feedback').listen((event) {
      if (event['event'] == 'immediate_feedback' && event['feedback'] != null) {
        final Map<String, dynamic> feedbackMap = event['feedback'];
        final Map<String, String> newFeedback = Map<String, String>.from(state.questionFeedback);
        
        feedbackMap.forEach((qId, result) {
          newFeedback[qId] = result.toString();
        });
        
        state = state.copyWith(questionFeedback: newFeedback);
      }
    }, onError: (e) {
      // Ignorovat SSE chyby
    });
  }

  void updateAnswer(dynamic answerData) {
    final newAnswers = Map<int, dynamic>.from(state.selectedAnswers);
    newAnswers[state.currentIndex] = answerData;
    state = state.copyWith(selectedAnswers: newAnswers);
  }

  Future<void> checkCurrentAnswer() async {
    if (_attemptId == null) return;
    
    final currentQ = state.questions[state.currentIndex];
    final questionId = (currentQ['id'] ?? currentQ['question_id']).toString();
    
    // Pokud už feedback má, nepotřebujeme to kontrolovat znovu
    if (state.questionFeedback.containsKey(questionId)) return;

    final answerData = state.selectedAnswers[state.currentIndex];
    if (answerData == null) return; // Nemá smysl kontrolovat prázdnou

    state = state.copyWith(isLoading: true);
    try {
      final apiClient = ref.read(apiClientProvider);
      dynamic payloadData = answerData;
      
      if (currentQ['type'] == 'ORDERING' && answerData is List) {
         List<String> idList = [];
         for (var text in answerData) {
             var matchingAnswer = (currentQ['answers'] as List).firstWhere((a) => a['text'].toString() == text.toString(), orElse: () => null);
             if (matchingAnswer != null) {
                 idList.add(matchingAnswer['answer_id'].toString());
             } else {
                 idList.add(text.toString());
             }
         }
         if (idList.isNotEmpty) {
             payloadData = idList;
         }
      }

      await apiClient.put('/api/student/attempts/$_attemptId/answers', {
        "answers": { questionId: payloadData }
      });
      // SSE backend by teď měl poslat `immediate_feedback` přes kanál
    } catch (e) {
      state = state.copyWith(errorMessage: 'Nelze zkontrolovat odpověď: $e');
    } finally {
      state = state.copyWith(isLoading: false);
    }
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
    
    if (_attemptId != null) {
      try {
        final apiClient = ref.read(apiClientProvider);
        
        Map<String, dynamic> answersPayload = {};
        state.selectedAnswers.forEach((index, answerData) {
          final q = state.questions[index];
          final questionId = q['id'] ?? q['question_id'];
          
          if (q['type'] == 'ORDERING' && answerData is List) {
             // Map selected texts to answer_ids
             List<String> idList = [];
             for (var text in answerData) {
                 var matchingAnswer = (q['answers'] as List).firstWhere((a) => a['text'].toString() == text.toString(), orElse: () => null);
                 if (matchingAnswer != null) {
                     idList.add(matchingAnswer['answer_id'].toString());
                 } else {
                     idList.add(text.toString());
                 }
             }
             if (idList.isNotEmpty) {
                 answersPayload[questionId.toString()] = idList;
             } else {
                 answersPayload[questionId.toString()] = answerData;
             }
          } else {
            answersPayload[questionId.toString()] = answerData;
          }
        });

        // Uloží odpovědi
        if (answersPayload.isNotEmpty) {
          await apiClient.put('/api/student/attempts/$_attemptId/answers', {
            "answers": answersPayload
          });
        }
        
        // Odevzdá test
        await apiClient.post('/api/student/attempts/$_attemptId/submit', {
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
          errorMessage: 'Chyba při odevzdání: $e',
          isLoading: false,
        );
      }
    } else {
      state = state.copyWith(isExiting: true, isLoading: false, errorMessage: 'Není známo ID pokusu.');
    }
  }
}

final testActiveProvider = NotifierProvider.autoDispose<TestActiveNotifier, TestActiveState>(() {
  return TestActiveNotifier();
});
