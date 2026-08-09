import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/api_client.dart';
import 'package:intl/intl.dart';
class TestAttemptsState {
  final bool isLoading;
  final String? errorMessage;
  final List<Map<String, dynamic>> attempts;
  
  TestAttemptsState({
    this.isLoading = true,
    this.errorMessage,
    this.attempts = const [],
  });

  TestAttemptsState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<Map<String, dynamic>>? attempts,
    bool clearError = false,
  }) {
    return TestAttemptsState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      attempts: attempts ?? this.attempts,
    );
  }
}

class TestAttemptsNotifier extends Notifier<TestAttemptsState> {
  StreamSubscription? _sseSubscription;

  @override
  TestAttemptsState build() {
    ref.onDispose(() {
      _sseSubscription?.cancel();
    });
    return TestAttemptsState();
  }

  Future<void> fetchAttempts(int assignmentId, {bool silent = false}) async {
    if (!silent) {
      state = state.copyWith(isLoading: true, clearError: true);
    }
    
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.get('/exam-assignments/$assignmentId/attempts');
      
      final attemptsRaw = response['attempts'] as List<dynamic>? ?? [];
      
      final attempts = attemptsRaw.map((a) {
        String status = a['status'] ?? 'UNKNOWN';
        String statusText = status;
        if (status == 'STARTED') statusText = 'Probíhá';
        if (status == 'SUBMITTED') statusText = 'Odevzdáno';
        if (status == 'GRADED') statusText = 'Ohodnoceno';
        
        String submittedAtText = '-';
        if (a['finished_at'] != null) {
          String dateStr = a['finished_at'];
          if (!dateStr.endsWith('Z')) dateStr += 'Z';
          final date = DateTime.parse(dateStr).toLocal();
          submittedAtText = DateFormat('dd. MM. yyyy HH:mm').format(date);
        }
        
        return {
          'attempt_id': a['attempt_id'],
          'student_id': a['student_id'],
          'student_name': a['student_name'] ?? 'Student ID: ${a['student_id']}', 
          'status': status,
          'statusText': statusText,
          'submitted_at': submittedAtText,
          'score': a['score_percent'] != null ? '${a['score_percent'].toStringAsFixed(0)} %' : '-',
          'points': a['total_points'] != null ? '${a['total_points']} / ${a['max_points'] ?? '?'}' : '-',
        };
      }).toList();
      
      state = state.copyWith(isLoading: false, attempts: attempts);

      // Pokud jsme ještě nenavázali SSE spojení, uděláme to nyní
      if (_sseSubscription == null) {
        _startSseListener(assignmentId);
      }
    } catch (e) {
      if (!silent) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Nepodařilo se načíst seznam pokusů: $e'
        );
      }
    }
  }

  void _startSseListener(int assignmentId) {
    final apiClient = ref.read(apiClientProvider);
    _sseSubscription = apiClient.listenSse('/api/sse/teacher/assignments/$assignmentId/progress').listen(
      (eventData) {
        final event = eventData['event'];
        if (event == 'ping') return;
        
        // Jakmile zachytíme událost o tom, že student něco udělal, 
        // rovnou tiše načteme celou tabulku znovu
        if (event == 'attempt_started' || event == 'answer_saved' || event == 'attempt_submitted') {
          fetchAttempts(assignmentId, silent: true);
        }
      },
      onError: (e) {
        debugPrint('Chyba SSE: $e');
        // V případě chyby se můžeme pokusit reconnect po chvíli
        Future.delayed(const Duration(seconds: 5), () {
          if (ref.exists(testAttemptsProvider)) {
             _sseSubscription?.cancel();
             _sseSubscription = null;
             _startSseListener(assignmentId);
          }
        });
      },
      cancelOnError: true,
    );
  }
}

final testAttemptsProvider = NotifierProvider.autoDispose<TestAttemptsNotifier, TestAttemptsState>(() {
  return TestAttemptsNotifier();
});
