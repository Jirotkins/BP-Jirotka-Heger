import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/api_client.dart';
import 'package:intl/intl.dart';

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
  bool _isStudent = false;
  Map<String, dynamic> _rawStudentAnswers = {};

  @override
  TestEvaluationState build() {
    return TestEvaluationState();
  }

  Future<void> fetchEvaluationData(int? assignmentId, int? attemptId, {bool isStudent = false}) async {
    _assignmentId = assignmentId;
    _attemptId = attemptId;
    _isStudent = isStudent;
    
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final apiClient = ref.read(apiClientProvider);
      final aId = _assignmentId ?? 999;
      final attId = _attemptId ?? 1;
      
      final url = _isStudent 
          ? '/api/student/attempts/$attId' 
          : '/exam-assignments/$aId/attempts/$attId';
          
      final response = await apiClient.get(url);
      
      _initializeStateFromData(response);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Chyba pri nacitani dat: $e'
      );
    }
  }

  void _initializeStateFromData(Map<String, dynamic> data) {
    Map<String, String> feedbacks = {};
    Map<String, String> points = {};
    Set<String> expanded = {};
    
    List<dynamic> snapshot = data['questions_snapshot'] ?? [];
    _rawStudentAnswers = data['student_answers'] ?? {};
    
    List<Map<String, dynamic>> mappedQuestions = [];
    int index = 1;
    
    for (var snap in snapshot) {
      String qId = snap['question_id'].toString();
      String rawType = snap['type']?.toString().toUpperCase() ?? 'OPEN_TEXT';
      double maxPoints = (snap['points'] ?? 1).toDouble();
      
      dynamic ansData = _rawStudentAnswers[qId] ?? _rawStudentAnswers[int.tryParse(qId) ?? -1];
      
      dynamic studentAnswerValue = ansData;
      double? awardedPoints;
      String? teacherFeedback;
      
      if (ansData is Map<String, dynamic> && ansData.containsKey('value')) {
        studentAnswerValue = ansData['value'];
        if (ansData['awarded_points'] != null) {
          awardedPoints = (ansData['awarded_points'] as num).toDouble();
        }
        teacherFeedback = ansData['teacher_feedback'];
      }

      String type = 'open';
      if (rawType == 'SINGLE_CHOICE' || rawType == 'MULTI_CHOICE') type = 'choice';
      if (rawType == 'SHORT_ANSWER') type = 'short_answer';
      if (rawType == 'ORDERING') type = 'order';
      if (rawType == 'MATCHING') type = 'match';
      
      bool isAutoGraded = (type != 'open');
      
      if (!isAutoGraded) {
        expanded.add(qId);
        if (teacherFeedback != null) feedbacks[qId] = teacherFeedback;
        if (awardedPoints != null) points[qId] = awardedPoints.toString();
      }

      // Convert student answer to displayable string
      dynamic displayStudentAnswer = studentAnswerValue;
      List<Map<String, dynamic>>? displayStudentPairs;

      if (type == 'choice') {
         if (studentAnswerValue is List) {
            displayStudentAnswer = studentAnswerValue.map((id) => _getAnswerText(snap, id)).join(", ");
         } else if (studentAnswerValue != null) {
            displayStudentAnswer = _getAnswerText(snap, studentAnswerValue);
         }
      } else if (type == 'order') {
         if (studentAnswerValue is List) {
            displayStudentAnswer = studentAnswerValue.map((id) => _getAnswerText(snap, id)).toList();
         }
      } else if (type == 'match') {
         if (studentAnswerValue is Map) {
            displayStudentPairs = studentAnswerValue.entries.map((entry) {
              return {
                "left": entry.key.toString(),
                "right": entry.value.toString(),
                "isCorrect": (awardedPoints ?? 0) > 0, // Zjednodušené hodnocení (pro teď záleží na backend awardedPoints)
              };
            }).toList();
         }
      }

      mappedQuestions.add({
        "id": qId,
        "number": index.toString(),
        "type": type,
        "text": snap['text'] ?? '',
        "studentAnswer": displayStudentAnswer ?? '-',
        "studentPairs": displayStudentPairs,
        "isCorrect": (awardedPoints ?? 0) > 0, 
        "awardedPoints": awardedPoints ?? 0.0,
        "maxPoints": maxPoints,
        "isAutoGraded": isAutoGraded,
        "isExpanded": !isAutoGraded,
        "teacherFeedback": teacherFeedback,
      });
      index++;
    }

    String status = data['status'] ?? 'UNKNOWN';
    String statusText = status;
    if (status == 'STARTED') statusText = 'Probíhá';
    if (status == 'SUBMITTED') statusText = 'Odevzdáno';
    if (status == 'GRADED') statusText = 'Ohodnoceno';

    String submittedAtText = '-';
    if (data['finished_at'] != null) {
      String dateStr = data['finished_at'];
      if (!dateStr.endsWith('Z')) dateStr += 'Z';
      final date = DateTime.parse(dateStr).toLocal();
      submittedAtText = DateFormat('dd. MM. yyyy HH:mm').format(date);
    }

    final mappedData = {
        "studentName": data['student_name'] != null ? data['student_name'] : "Student ID: ${data['student_id']}",
        "subject": "Pokus #${data['attempt_id']}",
      "classGroup": statusText,
      "submittedAt": submittedAtText,
      "maxScore": data['max_points'] ?? 0,
      "questions": mappedQuestions,
    };

    state = state.copyWith(
      testData: mappedData,
      teacherFeedbacks: feedbacks,
      awardedPoints: points,
      expandedQuestions: expanded,
      isLoading: false,
    );
  }

  String _getAnswerText(Map<String, dynamic> snap, dynamic id) {
    if (snap['answers'] != null) {
      for (var a in snap['answers']) {
        if (a['answer_id'].toString() == id.toString()) {
          return a['text'] ?? '';
        }
      }
    }
    return id.toString();
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
    
    // Zde připravíme data k odeslání do dict `student_answers`
    Map<String, dynamic> updatedAnswers = Map.from(_rawStudentAnswers);
    
    Set<String> allEvaluatedQuestionIds = {
      ...state.teacherFeedbacks.keys,
      ...state.awardedPoints.keys,
    };

    for (String qId in allEvaluatedQuestionIds) {
       String feedback = state.teacherFeedbacks[qId] ?? "";
       double pts = double.tryParse(state.awardedPoints[qId]?.replaceAll(',', '.') ?? '') ?? 0.0;
       
       dynamic existing = updatedAnswers[qId] ?? updatedAnswers[int.tryParse(qId) ?? -1];
       if (existing is Map) {
          existing['teacher_feedback'] = feedback;
          existing['awarded_points'] = pts;
       } else {
          updatedAnswers[qId] = {
             "value": existing,
             "teacher_feedback": feedback,
             "awarded_points": pts
          };
       }
    }

    try {
      if (_assignmentId != null && _attemptId != null) {
        final apiClient = ref.read(apiClientProvider);
        await apiClient.put('/exam-assignments/$_assignmentId/attempts/$_attemptId/grade', {
          "total_points": state.currentTotalScore,
          "student_answers": updatedAnswers,
          "teacher_note": "", // Optional global note
        });
      }
      
      state = state.copyWith(
        submitSuccess: true, 
        isSubmitting: false
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Chyba při odesílání hodnocení: $e',
        isSubmitting: false,
      );
    }
  }
}

final testEvaluationProvider = NotifierProvider.autoDispose<TestEvaluationNotifier, TestEvaluationState>(() {
  return TestEvaluationNotifier();
});
