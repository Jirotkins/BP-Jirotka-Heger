import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';

import 'test_active_provider.dart';
import '../../components/test_submit_popup_widget.dart';
import '../../components/test_exit_popup_widget.dart';

/// Hlavní obrazovka pro samotné vyplňování testu studentem (Aktivní test).
/// 
/// Poskytuje rozhraní pro čtení otázek (včetně obrázků), vybírání/psaní
/// odpovědí, hlídá časový odpočet a zpracovává navigaci mezi otázkami.
/// Také obsahuje podporu pro okamžitou zpětnou vazbu (immediate feedback) přes SSE.
class TestActiveWidget extends ConsumerStatefulWidget {
  const TestActiveWidget({super.key});

  @override
  ConsumerState<TestActiveWidget> createState() => _TestActiveWidgetState();
}

class _TestActiveWidgetState extends ConsumerState<TestActiveWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _textController = TextEditingController();
  
  String _testTitle = 'Načítání testu...';
  int? _assignmentId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = GoRouterState.of(context).extra as Map<String, dynamic>?;
      _assignmentId = args?['assignmentId'] as int?;
      if (mounted) {
        setState(() {
          _testTitle = args?['testTitle'] ?? 'Neznámý test';
        });
      }
      ref.read(testActiveProvider.notifier).fetchTest(_assignmentId);
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  /// Sychronizuje textové pole s odpovědí uloženou ve stavu,
  /// pokud je typ aktuální otázky textový. To zajišťuje, že se text
  /// neztratí při přecházení mezi otázkami.
  void _syncTextController(TestActiveState state) {
    if (state.questions.isEmpty) return;
    var qType = state.questions[state.currentIndex]['type'];
    if (qType == 'open' || qType == 'short_answer' || qType == 'OPEN_TEXT' || qType == 'SHORT_ANSWER') {
      _textController.text = state.selectedAnswers[state.currentIndex]?.toString() ?? '';
    }
  }

  /// Zobrazí popup pro finální odevzdání a po potvrzení odesílá data na API.
  /// Pokud [autoSubmit] je true, nedotazuje se a ihned odevzdá (např. při vypršení času).
  void _submitTest(TestActiveState state, TestActiveNotifier notifier, {bool autoSubmit = false}) {
    int answeredCount = state.selectedAnswers.length;

    if (autoSubmit) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Čas vypršel. Test byl automaticky odevzdán.'), backgroundColor: Theme.of(context).colorScheme.error),
      );
      notifier.submitTest(autoSubmit: true);
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => TestSubmitPopupWidget(
        answeredQuestions: answeredCount,
        totalQuestions: state.questions.length,
        onSubmit: () async {
          await notifier.submitTest();
        },
      ),
    );
  }

  /// Zobrazí varovný dialog při pokusu o opuštění rozpracovaného testu.
  void _showExitWarning(TestActiveNotifier notifier) {
    showDialog(
      context: context,
      builder: (dialogContext) => TestExitPopupWidget(
        onExit: () {
          notifier.setExiting(true);
          context.pop(); 
        }
      ),
    );
  }

  /// Převede sekundy na lidově čitelný formát `MM:SS`.
  String _formatTime(int seconds) {
    int m = seconds ~/ 60;
    int s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(testActiveProvider);
    final notifier = ref.read(testActiveProvider.notifier);

    ref.listen<TestActiveState>(testActiveProvider, (previous, next) {
      // Sync text controller on question change or first load
      if ((previous?.isLoading == true && next.isLoading == false) || 
          (previous?.currentIndex != next.currentIndex)) {
        _syncTextController(next);
      }

      // Handle Errors
      if (next.errorMessage != null && next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        notifier.clearError();
      }

      // Handle Success
      if (next.submitSuccess && (previous == null || !previous.submitSuccess)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Test byl úspěšně odevzdán!'), backgroundColor: Color(0xFF16A34A)),
        );
        context.pop();
      }
    });

    if (state.isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)),
      );
    }

    if (state.questions.isEmpty) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(child: Text('Tento test neobsahuje žádné otázky.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface))),
      );
    }

    int totalQuestions = state.questions.length;
    double progress = (state.currentIndex + 1) / totalQuestions;
    var currentQuestion = state.questions[state.currentIndex];
    
    bool isTimeRunningOut = state.remainingSeconds <= 60 && state.remainingSeconds > 0;
    Color timeColor = isTimeRunningOut ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.onSurface;

    return PopScope(
      canPop: state.isExiting,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _showExitWarning(notifier);
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  boxShadow: [BoxShadow(color: Theme.of(context).shadowColor.withValues(alpha: 0.04), blurRadius: 10.0, offset: const Offset(0, 4))],
                ),
                padding: const EdgeInsets.only(top: 16.0, left: 24.0, right: 24.0, bottom: 20.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        InkWell(
                          onTap: () => _showExitWarning(notifier),
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(padding: const EdgeInsets.all(4.0), child: Icon(Icons.close_rounded, color: Theme.of(context).colorScheme.onSurface, size: 24)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(_testTitle, style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface, fontSize: 18)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Otázka ${state.currentIndex + 1} z $totalQuestions', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600, fontSize: 14.0)),
                        Row(
                          children: [
                            Icon(Icons.timer_outlined, color: timeColor, size: 18),
                            const SizedBox(width: 6),
                            Text(_formatTime(state.remainingSeconds), style: GoogleFonts.inter(color: timeColor, fontWeight: FontWeight.bold, fontSize: 16.0)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12.0),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return Container(
                          height: 6.0,
                          width: constraints.maxWidth,
                          decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(6.0)),
                          child: Row(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeOutCubic, 
                                width: constraints.maxWidth * progress,
                                decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(6.0)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16.0),
                          border: Border.all(color: Theme.of(context).colorScheme.outline),
                          boxShadow: [BoxShadow(color: Theme.of(context).shadowColor.withValues(alpha: 0.04), blurRadius: 10.0, offset: const Offset(0, 4))],
                        ),
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (currentQuestion['image_url'] != null && currentQuestion['image_url'].toString().isNotEmpty) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12.0),
                                child: Builder(builder: (context) {
                                  final url = currentQuestion['image_url'].toString();
                                  if (url.startsWith('data:image')) {
                                    try {
                                      String b64 = url.split(',').last.trim();
                                      return ConstrainedBox(
                                        constraints: const BoxConstraints(maxHeight: 300),
                                        child: Image.memory(
                                          base64Decode(base64.normalize(b64)),
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          gaplessPlayback: true,
                                        ),
                                      );
                                    } catch (e) {
                                      debugPrint('Image rendering error in test_active_widget: $e');
                                      return const SizedBox();
                                    }
                                  }
                                  return ConstrainedBox(constraints: const BoxConstraints(maxHeight: 300), child: Image.network(url, fit: BoxFit.cover, width: double.infinity, errorBuilder: (c, e, s) => const SizedBox()));
                                }),
                              ),
                              const SizedBox(height: 16.0),
                            ],
                            Text(
                              currentQuestion['text'],
                              style: GoogleFonts.inter(fontSize: 18.0, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32.0),

                      if (currentQuestion['type'] == 'choice' || currentQuestion['type'] == 'SINGLE_CHOICE' || currentQuestion['type'] == 'MULTI_CHOICE')
                        _buildChoiceQuestion(currentQuestion, state, notifier)
                      else if (currentQuestion['type'] == 'open' || currentQuestion['type'] == 'short_answer' || currentQuestion['type'] == 'OPEN_TEXT' || currentQuestion['type'] == 'SHORT_ANSWER')
                        _buildTextQuestion(currentQuestion, notifier)
                      else if (currentQuestion['type'] == 'order' || currentQuestion['type'] == 'ORDERING')
                        _buildOrderQuestion(currentQuestion, state, notifier)
                      else if (currentQuestion['type'] == 'match' || currentQuestion['type'] == 'MATCHING')
                        _buildMatchQuestion(currentQuestion, state, notifier),

                      const SizedBox(height: 24.0),
                      if (state.showImmediateFeedback) _buildFeedbackBanner(currentQuestion, state),
                      const SizedBox(height: 24.0),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outline)), boxShadow: [BoxShadow(color: Theme.of(context).shadowColor.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))]),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      if (state.currentIndex > 0 && state.canGoBack) ...[
                        InkWell(
                          onTap: notifier.previousQuestion,
                          borderRadius: BorderRadius.circular(24.0),
                          child: Container(
                            height: 52, width: 52,
                            decoration: BoxDecoration(border: Border.all(color: Theme.of(context).colorScheme.outline, width: 1.5), shape: BoxShape.circle),
                            child: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
                          ),
                        ),
                        const SizedBox(width: 16.0),
                      ],
                      if (state.showImmediateFeedback) ...[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: state.isLoading || state.questionFeedback.containsKey((currentQuestion['id'] ?? currentQuestion['question_id']).toString())
                                ? null
                                : () => notifier.checkCurrentAnswer(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16.0),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26.0)),
                              side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
                            ),
                            child: state.isLoading
                                ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.0, color: Theme.of(context).colorScheme.primary))
                                : Text('Zkontrolovat', style: GoogleFonts.inter(fontSize: 16.0, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                          ),
                        ),
                        const SizedBox(width: 16.0),
                      ],
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (state.currentIndex < totalQuestions - 1) {
                              notifier.nextQuestion();
                            } else {
                              _submitTest(state, notifier);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26.0)),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                state.currentIndex == totalQuestions - 1 ? 'Odevzdat test' : 'Další otázka', 
                                style: GoogleFonts.inter(fontSize: 16.0, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimary)
                              ),
                              const SizedBox(width: 8),
                              Icon(state.currentIndex == totalQuestions - 1 ? Icons.check_circle_outline : Icons.arrow_forward, color: Theme.of(context).colorScheme.onPrimary, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ));
  }

  /// Vykreslí banner se zpětnou vazbou pro danou otázku (Správně / Špatně / Čeká na hodnocení).
  /// Používá se v režimu okamžité zpětné vazby (immediate_feedback).
  Widget _buildFeedbackBanner(Map<String, dynamic> question, TestActiveState state) {
    final qId = (question['id'] ?? question['question_id']).toString();
    if (!state.questionFeedback.containsKey(qId)) return const SizedBox.shrink();

    final resultObj = state.questionFeedback[qId];
    final status = resultObj is Map ? resultObj['status'] : resultObj;
    final correctAnswerText = resultObj is Map ? resultObj['correct_answer'] : null;

    final isCorrect = status == 'correct';
    final isPending = status == 'pending';

    Color bgColor = isCorrect ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2);
    Color textColor = isCorrect ? const Color(0xFF166534) : const Color(0xFF991B1B);
    Color borderColor = isCorrect ? const Color(0xFF4ADE80) : const Color(0xFFF87171);
    IconData icon = isCorrect ? Icons.check_circle : Icons.cancel;
    String text = isCorrect ? 'Správně!' : 'Špatně!';

    if (isPending) {
      bgColor = Theme.of(context).colorScheme.surfaceContainerHighest;
      textColor = Theme.of(context).colorScheme.onSurfaceVariant;
      borderColor = Theme.of(context).colorScheme.outline;
      icon = Icons.hourglass_empty;
      text = 'Odpověď uložena (čeká na ruční hodnocení)';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: textColor),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: textColor, fontSize: 15.0)),
                if (!isCorrect && !isPending && correctAnswerText != null && correctAnswerText.toString().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('Správně: $correctAnswerText', style: GoogleFonts.inter(color: textColor.withValues(alpha: 0.8), fontSize: 13.0, fontWeight: FontWeight.w500)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Vykreslí komponenty pro otázky typu "Výběr z možností" (SINGLE_CHOICE / MULTI_CHOICE).
  Widget _buildChoiceQuestion(Map<String, dynamic> question, TestActiveState state, TestActiveNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Vyberte jednu správnou odpověď:', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.bold, fontSize: 13.0)),
        const SizedBox(height: 12.0),
        ...List.generate(question['options'].length, (index) {
          var option = question['options'][index];
          bool isSelected = state.selectedAnswers[state.currentIndex] == option['id'];
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: InkWell(
              onTap: () => notifier.updateAnswer(option['id']),
              borderRadius: BorderRadius.circular(14.0),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(14.0),
                  border: Border.all(color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline, width: isSelected ? 2.0 : 1.0),
                ),
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      width: 36.0, height: 36.0,
                      decoration: BoxDecoration(
                        color: isSelected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1) : Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      alignment: Alignment.center,
                      child: Text(option['letter'], style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant)),
                    ),
                    const SizedBox(width: 16.0),
                    Expanded(child: Text(option['text'], style: GoogleFonts.inter(fontSize: 15.0, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, color: Theme.of(context).colorScheme.onSurface))),
                    Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline, size: 22.0),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  /// Vykreslí komponenty pro otázky typu "Textová odpověď" (OPEN_TEXT / SHORT_ANSWER).
  Widget _buildTextQuestion(Map<String, dynamic> question, TestActiveNotifier notifier) {
    bool isLong = question['type'] == 'open';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(isLong ? 'Zapište svou odpověď (vlastními slovy):' : 'Napište krátkou odpověď:', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.bold, fontSize: 13.0)),
        const SizedBox(height: 12.0),
        TextFormField(
          controller: _textController,
          maxLines: isLong ? 6 : 1,
          onChanged: (val) {
            notifier.updateAnswer(val);
          },
          style: GoogleFonts.inter(fontSize: 16.0, color: Theme.of(context).colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: isLong ? 'Zde se můžete rozepsat...' : 'Vaše odpověď...',
            hintStyle: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurfaceVariant),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16.0), borderSide: BorderSide(color: Theme.of(context).colorScheme.outline)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16.0), borderSide: BorderSide(color: Theme.of(context).colorScheme.outline)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16.0), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5)),
          ),
        ),
      ],
    );
  }

  /// Vykreslí komponenty pro otázky typu "Řazení" (ORDERING).
  /// Umožňuje přetahování položek (ReorderableListView).
  Widget _buildOrderQuestion(Map<String, dynamic> question, TestActiveState state, TestActiveNotifier notifier) {
    List<String> items = state.selectedAnswers[state.currentIndex] != null 
        ? List<String>.from(state.selectedAnswers[state.currentIndex]) 
        : List<String>.from(question['items']);
    
    if (state.selectedAnswers[state.currentIndex] == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifier.updateAnswer(items);
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Seřaďte položky (podržte a přetáhněte):', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.bold, fontSize: 13.0)),
        const SizedBox(height: 12.0),
        ReorderableListView.builder(
          shrinkWrap: true, 
          physics: const NeverScrollableScrollPhysics(), 
          itemCount: items.length,
          proxyDecorator: (Widget child, int index, Animation<double> animation) {
            return Material(
              color: Colors.transparent,
              elevation: 0,
              child: child,
            );
          },
          onReorder: (oldIndex, newIndex) {
            if (newIndex > oldIndex) {
              newIndex -= 1;
            }
            final newItems = List<String>.from(items);
            final String item = newItems.removeAt(oldIndex);
            newItems.insert(newIndex, item);
            notifier.updateAnswer(newItems);
          },
          itemBuilder: (context, index) {
            return Container(
              key: ValueKey(items[index]), 
              margin: const EdgeInsets.only(bottom: 12.0),
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(12.0), border: Border.all(color: Theme.of(context).colorScheme.outline)),
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: Row(
                children: [
                  Icon(Icons.drag_indicator_rounded, color: Theme.of(context).colorScheme.outline),
                  const SizedBox(width: 16.0),
                  Expanded(child: Text(items[index], style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface, fontSize: 15.0))),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  /// Vykreslí komponenty pro otázky typu "Párování" (MATCHING).
  /// Zobrazí levý sloupec termínů a k nim přiřazuje pomocí DropdownMenu odpovídající hodnoty zprava.
  Widget _buildMatchQuestion(Map<String, dynamic> question, TestActiveState state, TestActiveNotifier notifier) {
    List<String> leftItems = List<String>.from(question['leftItems']);
    List<String> rightOptions = List<String>.from(question['rightItems']);
    
    Map<String, String> pairs = state.selectedAnswers[state.currentIndex] != null 
        ? Map<String, String>.from(state.selectedAnswers[state.currentIndex]) 
        : {};

    if (state.selectedAnswers[state.currentIndex] == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifier.updateAnswer(pairs);
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Přiřaďte správný pojem ke každé položce:', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.bold, fontSize: 13.0)),
        const SizedBox(height: 12.0),
        
        ...leftItems.map((leftItem) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16.0),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(16.0), border: Border.all(color: Theme.of(context).colorScheme.outline)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(leftItem, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16.0, color: Theme.of(context).colorScheme.onSurface)),
                const SizedBox(height: 12.0),
                
                DropdownButtonFormField<String>(
                  initialValue: pairs[leftItem], 
                  isExpanded: true,
                  hint: Text('Vyberte správnou možnost', style: GoogleFonts.inter(fontSize: 14.0, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide(color: Theme.of(context).colorScheme.outline)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide(color: Theme.of(context).colorScheme.outline)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary)),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  items: rightOptions.map((String option) {
                    return DropdownMenuItem<String>(
                      value: option,
                      child: Text(option, style: GoogleFonts.inter(fontSize: 14.0, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface)),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      final newPairs = Map<String, String>.from(pairs);
                      newPairs[leftItem] = newValue;
                      notifier.updateAnswer(newPairs);
                    }
                  },
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}