import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/api_client.dart';

/// Stav reprezentující seznam otázek pro jednu konkrétní banku.
class QuestionsOverviewState {
  /// Indikátor stahování dat ze serveru.
  final bool isLoading;
  
  /// Chybová hláška v případě selhání API volání.
  final String? errorMessage;
  
  /// Seznam otázek načtených z backendu (připravených pro zobrazení).
  final List<Map<String, dynamic>> questions;
  
  /// ID aktuálně otevřené banky otázek.
  final int bankId;

  /// Určuje, zda má být zobrazení otázek obrácené (od nejnovější po nejstarší).
  final bool isReversed;

  QuestionsOverviewState({
    this.isLoading = false,
    this.errorMessage,
    this.questions = const [],
    this.bankId = 0,
    this.isReversed = false,
  });

  /// Vytvoří kopii aktuálního stavu s možností přepsání vybraných hodnot.
  /// Pomocí [clearError] lze cíleně vynulovat chybovou hlášku.
  QuestionsOverviewState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<Map<String, dynamic>>? questions,
    int? bankId,
    bool? isReversed,
    bool clearError = false,
  }) {
    return QuestionsOverviewState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      questions: questions ?? this.questions,
      bankId: bankId ?? this.bankId,
      isReversed: isReversed ?? this.isReversed,
    );
  }
}

/// Správce stavu (Notifier) řídící operace nad seznamem otázek v bance.
class QuestionsOverviewNotifier extends Notifier<QuestionsOverviewState> {
  @override
  QuestionsOverviewState build() {
    return QuestionsOverviewState(isLoading: true);
  }

  /// Načte všechny otázky patřící do banky s daným [bankId].
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
      
      int chronoIndex = 1;
      final questionsData = questionsList.map((q) {
        return {
          'id': q['question_id'],
          'chronological_number': chronoIndex++,
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

  /// Pokusí se smazat otázku z banky podle jejího [questionId].
  /// 
  /// Vrací [null] při úspěchu. Pokud je otázka aktuálně použita v nějakém testu
  /// a parametr [force] je nepravdivý, API vrátí chybu 409 a metoda vrátí 'IN_USE'.
  /// Při [force] = true je otázka z testů odebrána natvrdo a smazána.
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

  /// Vyčistí jakoukoliv probíhající chybu.
  void clearError() {
    state = state.copyWith(clearError: true);
  }
  
  /// Znovu načte otázky pro aktuálně zvolenou banku (pokud nějaká je).
  void refresh() {
    if (state.bankId != 0) {
      fetchQuestions(state.bankId);
    }
  }

  /// Přepne směr zobrazení otázek (od nejstarší po nejnovější a naopak).
  void toggleSortOrder() {
    state = state.copyWith(isReversed: !state.isReversed);
  }
}

/// Globálně dostupný provider pro [QuestionsOverviewNotifier].
final questionsOverviewProvider = NotifierProvider.autoDispose<QuestionsOverviewNotifier, QuestionsOverviewState>(() {
  return QuestionsOverviewNotifier();
});
