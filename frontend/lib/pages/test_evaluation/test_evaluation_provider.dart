import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/api_client.dart';

class TestEvaluationState {
  final bool isLoading;
  final String? errorMessage;
  final Map<String, dynamic> testData;
  final Map<String, String> teacherFeedbacks;
  final Map<String, String> awardedPoints;
  final Set<String> expandedQuestions;
  
  final bool isSubmitting;
  final bool submitSuccess;

  TestEvaluationState({
    this.isLoading = true,
    this.errorMessage,
    this.testData = const {},
    this.teacherFeedbacks = const {},
    this.awardedPoints = const {},
    this.expandedQuestions = const {},
    this.isSubmitting = false,
    this.submitSuccess = false,
  });

  TestEvaluationState copyWith({
    bool? isLoading,
    String? errorMessage,
    Map<String, dynamic>? testData,
    Map<String, String>? teacherFeedbacks,
    Map<String, String>? awardedPoints,
    Set<String>? expandedQuestions,
    bool? isSubmitting,
    bool? submitSuccess,
    bool clearError = false,
  }) {
    return TestEvaluationState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      testData: testData ?? this.testData,
      teacherFeedbacks: teacherFeedbacks ?? this.teacherFeedbacks,
      awardedPoints: awardedPoints ?? this.awardedPoints,
      expandedQuestions: expandedQuestions ?? this.expandedQuestions,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitSuccess: submitSuccess ?? this.submitSuccess,
    );
  }

  double get currentTotalScore {
    if (testData.isEmpty || testData['questions'] == null) return 0.0;
    
    double total = 0;
    for (var question in testData['questions']) {
      if (question['isAutoGraded'] == true) {
        total += (question['awardedPoints'] ?? 0).toDouble();
      } else {
        String? pointsText = awardedPoints[question['id']];
        if (pointsText != null && pointsText.isNotEmpty) {
          total += double.tryParse(pointsText.replaceAll(',', '.')) ?? 0;
        }
      }
    }
    return total;
  }
}

class TestEvaluationNotifier extends Notifier<TestEvaluationState> {
  int? _assignmentId;
  int? _attemptId;

  @override
  TestEvaluationState build() {
    return TestEvaluationState();
  }

  Future<void> fetchEvaluationData(int? assignmentId, int? attemptId) async {
    _assignmentId = assignmentId;
    _attemptId = attemptId;
    
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final apiClient = ref.read(apiClientProvider);
      final aId = _assignmentId ?? 999;
      final attId = _attemptId ?? 1;
      
      final response = await apiClient.get('/exam-assignments/$aId/attempts/$attId');
      
      _initializeStateFromData(response);
    } catch (e) {
      _useFallbackMockData();
    }
  }

  void _initializeStateFromData(Map<String, dynamic> data) {
    Map<String, String> feedbacks = {};
    Map<String, String> points = {};
    Set<String> expanded = {};
    
    if (data['questions'] != null) {
      for (var question in data['questions']) {
        String qId = question['id'];
        
        if (question['isExpanded'] == true) {
          expanded.add(qId);
        }
        
        if (question['type'] == 'open') {
          if (question['teacherFeedback'] != null) {
            feedbacks[qId] = question['teacherFeedback'];
          }
          if (question['awardedPoints'] != null) {
            points[qId] = question['awardedPoints'].toString();
          }
        }
      }
    }

    state = state.copyWith(
      testData: data,
      teacherFeedbacks: feedbacks,
      awardedPoints: points,
      expandedQuestions: expanded,
      isLoading: false,
    );
  }

  void _useFallbackMockData() {
    final mockData = {
      "studentName": "Jan Zápotocký",
      "subject": "Biologie - Buňka 1",
      "classGroup": "3.C bio",
      "submittedAt": "12.05.2026",
      "maxScore": 15,
      "questions": [
        {
          "id": "q1",
          "number": "1",
          "type": "choice",
          "text": "Co je energetickým centrem buňky?",
          "studentAnswer": "Mitochondrie",
          "isCorrect": true,
          "awardedPoints": 1,
          "maxPoints": 1,
          "isAutoGraded": true,
          "isExpanded": false,
        },
        {
          "id": "q2",
          "number": "2",
          "type": "open",
          "text": "Stručně popište funkci buněčné membrány.",
          "studentAnswer": "Buněčná membrána funguje jako bariéra, která kontroluje vstup a výstup látek do buňky. Zároveň ji chrání.",
          "teacherFeedback": "Skvělý popis! Zkuste příště zahrnout termín 'selektivní propustnost'.",
          "awardedPoints": null,
          "maxPoints": 5,
          "isAutoGraded": false,
          "isExpanded": true,
        },
        {
          "id": "q3",
          "number": "3",
          "type": "short_answer",
          "text": "Jak se nazývá proces dělení tělních buněk?",
          "studentAnswer": "Meióza",
          "isCorrect": false,
          "awardedPoints": 0,
          "maxPoints": 2,
          "isAutoGraded": true,
          "isExpanded": false,
        },
        {
          "id": "q4",
          "number": "4",
          "type": "order",
          "text": "Seřaďte fáze buněčného cyklu (mitózy) ve správném pořadí.",
          "studentAnswer": ["Profáze", "Metafáze", "Anafáze", "Telofáze"],
          "correctOrder": ["Profáze", "Metafáze", "Anafáze", "Telofáze"],
          "isCorrect": true,
          "awardedPoints": 4,
          "maxPoints": 4,
          "isAutoGraded": true,
          "isExpanded": true,
        },
        {
          "id": "q5",
          "number": "5",
          "type": "match",
          "text": "Přiřaďte buněčné organely k jejich správným funkcím.",
          "studentPairs": [
            {
              "left": "Ribozom",
              "right": "Uchování DNA",
              "isCorrect": false,
              "correctRight": "Syntéza bílkovin",
            },
            {"left": "Chloroplast", "right": "Fotosyntéza", "isCorrect": true},
            {
              "left": "Jádro",
              "right": "Syntéza bílkovin",
              "isCorrect": false,
              "correctRight": "Uchování DNA",
            },
          ],
          "isCorrect": false,
          "awardedPoints": 1,
          "maxPoints": 3,
          "isAutoGraded": true,
          "isExpanded": true,
        },
      ],
    };

    _initializeStateFromData(mockData);
    state = state.copyWith(
      errorMessage: "Nepodařilo se stáhnout data ze serveru. Používám ukázková data."
    );
  }

  void toggleExpanded(String questionId) {
    final newExpanded = Set<String>.from(state.expandedQuestions);
    if (newExpanded.contains(questionId)) {
      newExpanded.remove(questionId);
    } else {
      newExpanded.add(questionId);
    }
    state = state.copyWith(expandedQuestions: newExpanded);
  }

  void updateFeedback(String questionId, String feedback) {
    final newFeedbacks = Map<String, String>.from(state.teacherFeedbacks);
    newFeedbacks[questionId] = feedback;
    state = state.copyWith(teacherFeedbacks: newFeedbacks);
  }

  void updatePoints(String questionId, String pointsStr) {
    final newPoints = Map<String, String>.from(state.awardedPoints);
    newPoints[questionId] = pointsStr;
    state = state.copyWith(awardedPoints: newPoints);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  Future<void> submitEvaluation() async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    
    // Zde připravíme data k odeslání
    List<Map<String, dynamic>> evaluations = [];
    state.teacherFeedbacks.forEach((qId, feedback) {
      evaluations.add({
        "question_id": qId,
        "teacher_feedback": feedback,
        "awarded_points": double.tryParse(state.awardedPoints[qId]?.replaceAll(',', '.') ?? '') ?? 0.0,
      });
    });

    try {
      if (_assignmentId != null && _attemptId != null) {
        final apiClient = ref.read(apiClientProvider);
        await apiClient.post('/exam-assignments/$_assignmentId/attempts/$_attemptId/evaluate', {
          "evaluations": evaluations
        });
      }
      
      state = state.copyWith(
        submitSuccess: true, 
        isSubmitting: false
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Endpoint pro odevzdání chybí. Payload: $evaluations',
        isSubmitting: false,
      );
    }
  }
}

final testEvaluationProvider = NotifierProvider.autoDispose<TestEvaluationNotifier, TestEvaluationState>(() {
  return TestEvaluationNotifier();
});
