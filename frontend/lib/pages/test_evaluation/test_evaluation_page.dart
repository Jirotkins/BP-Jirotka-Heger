import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../components/zoomable_image_widget.dart';
import 'test_evaluation_provider.dart';
import '../class_manager/test_attempts/test_attempts_provider.dart';
import '../../theme/app_themes.dart';
import '../../components/page_header_widget.dart';

/// Stránka určená pro zobrazení a manuální ohodnocení již vyplněného testu.
///
/// Vykresluje informace o testu, otázky s odpověďmi studenta a umožňuje
/// učiteli doplnit body a zpětnou vazbu u otevřených otázek. Pokud se na
/// stránku dívá student ([isStudent] = true), je UI pouze pro čtení.
class TestEvaluationPage extends ConsumerStatefulWidget {
  final int? assignmentId;
  final int? attemptId;
  final bool isStudent;

  const TestEvaluationPage({
    super.key,
    this.assignmentId,
    this.attemptId,
    this.isStudent = false,
  });

  @override
  ConsumerState<TestEvaluationPage> createState() => _TestEvaluationPageState();
}

/// Vnitřní stav stránky s lokálními controllery pro textová pole hodnocení.
class _TestEvaluationPageState extends ConsumerState<TestEvaluationPage> {
  final Map<String, TextEditingController> _feedbackControllers = {};
  final Map<String, TextEditingController> _pointsControllers = {};

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(testEvaluationProvider.notifier).fetchEvaluationData(
            widget.assignmentId,
            widget.attemptId,
            isStudent: widget.isStudent,
          );
    });
  }

  void _initializeControllers(TestEvaluationState state) {
    if (state.testData['questions'] == null) return;
    
    for (var question in state.testData['questions']) {
      if (question['type'] == 'open') {
        String qId = question['id'];
        
        if (!_feedbackControllers.containsKey(qId)) {
          _feedbackControllers[qId] = TextEditingController(
            text: state.teacherFeedbacks[qId] ?? '',
          );
        }
        
        if (!_pointsControllers.containsKey(qId)) {
          _pointsControllers[qId] = TextEditingController(
            text: state.awardedPoints[qId] ?? '',
          );
        }
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _feedbackControllers.values) {
      controller.dispose();
    }
    for (var controller in _pointsControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(testEvaluationProvider);
    final notifier = ref.read(testEvaluationProvider.notifier);


    ref.listen<TestEvaluationState>(testEvaluationProvider, (previous, next) {
      if (previous?.isLoading == true && next.isLoading == false) {
        _initializeControllers(next);
      }
      
      if (next.errorMessage != null && next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        notifier.clearError();
      }

      if (next.submitSuccess && (previous == null || !previous.submitSuccess)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hodnocení bylo úspěšně uloženo.'),
            backgroundColor: Color(0xFF16A34A),
          ),
        );
        Future.delayed(const Duration(milliseconds: 500), () {
          if (context.mounted) {
            if (widget.assignmentId != null) {
              ref.read(testAttemptsProvider.notifier).fetchAttempts(widget.assignmentId!);
            }
            Navigator.of(context).pop();
          }
        });
      }
    });

    if (state.isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: widget.isStudent ? _buildStudentAppBar(context) : null,
        body: Column(
          children: [
            if (!widget.isStudent) const PageHeaderWidget(title: 'Načítání...', showBackButton: true),
            Expanded(child: Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))),
          ],
        ),
      );
    }

    if (state.testData.isEmpty) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: widget.isStudent ? _buildStudentAppBar(context) : null,
        body: Column(
          children: [
            if (!widget.isStudent) const PageHeaderWidget(title: 'Chyba načítání', showBackButton: true),
            Expanded(child: Center(child: Text('Data o testu se nepodařilo načíst.', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface)))),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: widget.isStudent ? _buildStudentAppBar(context) : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!widget.isStudent)
            PageHeaderWidget(
              title: 'Hodnocení testu',
              showBackButton: true,
              actions: [
                state.isSubmitting
                    ? SizedBox(
                        width: 24, height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.primary),
                      )
                    : ElevatedButton.icon(
                        onPressed: () => notifier.submitEvaluation(),
                        icon: const Icon(Icons.save_rounded, size: 20),
                        label: const Text('Uložit hodnocení'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
              ],
            ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeaderInfo(context, state),
                  _buildQuestionsList(
                    context, 
                    state, 
                    notifier,
                    hideCorrectAnswers: widget.isStudent && !(state.testData['show_results_after_submit'] ?? true),
                  ),
                  const SizedBox(height: 60), 
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildStudentAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor ?? Theme.of(context).colorScheme.surface,
      surfaceTintColor: Colors.transparent, // Zabrání zešednutí při rolování
      scrolledUnderElevation: 0,
      elevation: 0,
      toolbarHeight: 80, 
      centerTitle: false,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_rounded, color: Theme.of(context).colorScheme.onSurface),
        onPressed: () => Navigator.of(context).pop(), 
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Hodnocení testu',
            style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface, fontSize: 24),
          ),
          const SizedBox(height: 2),
          Text(
            'Detail výsledků',
            style: GoogleFonts.inter(color: Theme.of(context).colorScheme.secondary, fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  /// Vykreslí horní informační panel s detaily o odevzdaném testu
  /// (Jméno studenta, předmět, stav, datum a maximální skóre).
  Widget _buildHeaderInfo(BuildContext context, TestEvaluationState state) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        
        final infoColumn = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              state.testData['studentName'] ?? 'Neznámý student',
              style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.book_rounded, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text(state.testData['subject'] ?? 'Předmět', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500)),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.people_alt_rounded, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text(state.testData['classGroup'] ?? 'Třída', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today_rounded, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Text('Odevzdáno: ${state.testData['submittedAt'] ?? '-'}', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        );

        final scoreBox = Container(
          width: isMobile ? double.infinity : null,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Text('CELKOVÉ SKÓRE', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.primary, letterSpacing: 0.5)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    state.currentTotalScore.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), ''),
                    style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.primary, height: 1),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '/ ${state.testData['maxScore'] ?? 0} b.',
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ],
          ),
        );

        return Container(
          color: Theme.of(context).colorScheme.surface,
          padding: const EdgeInsets.all(24.0),
          child: isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    infoColumn,
                    const SizedBox(height: 24),
                    scoreBox,
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: infoColumn),
                    const SizedBox(width: 24),
                    scoreBox,
                  ],
                ),
        );
      },
    );
  }

  /// Vykreslí seznam otázek
  Widget _buildQuestionsList(BuildContext context, TestEvaluationState state, TestEvaluationNotifier notifier, {bool hideCorrectAnswers = false}) {
    if (state.testData['questions'] == null || (state.testData['questions'] as List).isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detail odpovědí',
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
            ),
            const SizedBox(height: 20),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40.0),
                child: Text(
                  'Tento test neobsahuje žádné otázky.',
                  style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ),
            ),
          ],
        ),
      );
    }

    List<dynamic> questionsList = state.testData['questions'];
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 4,
            children: [
              Text(
                'Detail odpovědí',
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
              ),
              if (hideCorrectAnswers)
                Text(
                  '(U tohoto testu učitel zakázal zobrazení správných odpovědí)',
                  style: GoogleFonts.inter(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant, fontStyle: FontStyle.italic),
                ),
            ],
          ),
          const SizedBox(height: 20),
          ...questionsList.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: _buildDynamicEvaluationCard(entry.value, entry.key, state, notifier, hideCorrectAnswers: hideCorrectAnswers),
            );
          }),
        ],
      ),
    );
  }

  Map<String, Color> _getFeedbackColors(BuildContext context, double awarded, double max) {
    final customColors = Theme.of(context).extension<CustomColors>();

    if (awarded == max) {
      return {
        'bg': customColors?.greenBg ?? const Color(0xFFF0FDF4),
        'border': customColors?.greenText?.withValues(alpha: 0.3) ?? const Color(0xFF86EFAC),
        'icon': customColors?.greenText ?? const Color(0xFF16A34A),
      };
    } else if (awarded <= 0) {
      return {
        'bg': Theme.of(context).colorScheme.errorContainer,
        'border': Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
        'icon': customColors?.redText ?? Theme.of(context).colorScheme.error,
      };
    } else {
      return {
        'bg': customColors?.orangeBg ?? const Color(0xFFFFFBEB),
        'border': customColors?.orangeText?.withValues(alpha: 0.3) ?? const Color(0xFFFCD34D),
        'icon': customColors?.orangeText ?? const Color(0xFFD97706),
      };
    }
  }

  /// Vykreslí univerzální kartu (Card) pro danou otázku.
  /// 
  /// Zajišťuje zobrazení znění, obrázků a hlavičky s body. Volá další pod-metody
  /// (`_buildAutoGradedAnswerView` apod.) podle typu otázky.
  Widget _buildDynamicEvaluationCard(Map<String, dynamic> question, int index, TestEvaluationState state, TestEvaluationNotifier notifier, {bool hideCorrectAnswers = false}) {
    String qId = question['id'];
    bool isExpanded = state.expandedQuestions.contains(qId);
    bool isAutoGraded = question['isAutoGraded'] ?? false;
    final customColors = Theme.of(context).extension<CustomColors>();

    String typeLabel = "";
    switch (question['type']) {
      case 'choice': typeLabel = "Výběr z možností"; break;
      case 'open': typeLabel = "Otevřená otázka"; break;
      case 'short_answer': typeLabel = "Krátká odpověď"; break;
      case 'order': typeLabel = "Seřazení"; break;
      case 'match': typeLabel = "Párování"; break;
      default: typeLabel = "Neznámý typ";
    }

    String title = "${question['number'] ?? '?'}. $typeLabel";

    String scoreDisplay;
    if (isAutoGraded) {
      scoreDisplay = "${question['awardedPoints'] ?? 0} / ${question['maxPoints'] ?? 0} b.";
    } else {
      scoreDisplay = (_pointsControllers[qId]?.text.isEmpty ?? true)
          ? "- / ${question['maxPoints'] ?? 0} b."
          : "${_pointsControllers[qId]!.text} / ${question['maxPoints'] ?? 0} b.";
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: isAutoGraded
              ? Theme.of(context).colorScheme.outline
              : Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          width: isAutoGraded ? 1.0 : 2.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => notifier.toggleExpanded(qId),
            borderRadius: BorderRadius.circular(16.0),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Wrap(
                spacing: 16,
                runSpacing: 12,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.onSurface),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isAutoGraded
                              ? Theme.of(context).scaffoldBackgroundColor
                              : customColors?.orangeBg ?? Theme.of(context).colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isAutoGraded ? 'Automaticky opraveno' : 'Vyžaduje kontrolu',
                          style: GoogleFonts.inter(
                            fontSize: 12, fontWeight: FontWeight.w600,
                            color: isAutoGraded
                                ? Theme.of(context).colorScheme.onSurfaceVariant
                                : customColors?.orangeText ?? Theme.of(context).colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        scoreDisplay,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold, fontSize: 16,
                          color: isAutoGraded ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(isExpanded ? Icons.expand_less : Icons.expand_more, color: Theme.of(context).colorScheme.secondary),
                    ],
                  ),
                ],
              ),
            ),
          ),

          if (isExpanded) ...[
            Divider(height: 1, color: Theme.of(context).colorScheme.outline),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (question['image_url'] != null && question['image_url'].toString().isNotEmpty) ...[
                    ZoomableImageWidget(imageUrl: question['image_url'].toString()),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    question['text'] ?? '',
                    style: GoogleFonts.inter(fontSize: 16, color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 20),

                  if (question['type'] == 'choice' || question['type'] == 'short_answer')
                    _buildAutoGradedAnswerView(question, hideCorrectAnswers)
                  else if (question['type'] == 'open')
                    _buildOpenQuestionEvaluation(question, notifier, hideCorrectAnswers)
                  else if (question['type'] == 'order')
                    _buildOrderAnswerView(question, hideCorrectAnswers)
                  else if (question['type'] == 'match')
                    _buildMatchAnswerView(question, hideCorrectAnswers),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Vykreslí vizuální zhodnocení u automaticky opravovaných otázek
  /// (např. multiple choice, short answer), kde se jen zobrazuje odpověď žáka
  /// a správná odpověď s ikonami pro úspěch/neúspěch.
  Widget _buildAutoGradedAnswerView(Map<String, dynamic> question, bool hideCorrectAnswers) {
    bool isCorrect = question['isCorrect'] == true;
    final customColors = Theme.of(context).extension<CustomColors>();

    Color bgColor = isCorrect ? (customColors?.greenBg ?? Colors.green.withValues(alpha: 0.1)) : Theme.of(context).colorScheme.errorContainer;
    Color borderColor = isCorrect ? (customColors?.greenText?.withValues(alpha: 0.3) ?? Colors.transparent) : Theme.of(context).colorScheme.error.withValues(alpha: 0.3);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Odpověď studenta:', style: GoogleFonts.inter(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                const SizedBox(height: 4),
                Text(question['studentAnswer'] ?? '', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
                
                if (!hideCorrectAnswers && !isCorrect && question['correctAnswer'] != null && question['correctAnswer'].toString().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Správně: ${question['correctAnswer']}', style: GoogleFonts.inter(fontSize: 12, color: customColors?.greenText ?? Colors.green, fontWeight: FontWeight.w600)),
                ],
              ],
            ),
          ),
          Icon(
            isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: isCorrect ? customColors?.greenText ?? Colors.green : Theme.of(context).colorScheme.error,
            size: 28,
          ),
        ],
      ),
    );
  }

  /// Vykreslí detail seřazovací (ORDER) otázky – jak žák položky poskládal.
  /// (Tato implementace se spoléhá na backend ohledně logiky částečných bodů).
  Widget _buildOrderAnswerView(Map<String, dynamic> question, bool hideCorrectAnswers) {
    double awarded = (question['awardedPoints'] ?? 0).toDouble();
    double max = (question['maxPoints'] ?? 1).toDouble();
    var colors = _getFeedbackColors(context, awarded, max);
    final customColors = Theme.of(context).extension<CustomColors>();

    List<String> items = List<String>.from(question['studentAnswer'] ?? []);
    List<String> correctItems = List<String>.from(question['correctOrder'] ?? items);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors['bg'],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors['border']!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Odpověď studenta (seřazeno):', style: GoogleFonts.inter(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              Icon(
                awarded == max ? Icons.check_circle_rounded : (awarded <= 0 ? Icons.cancel_rounded : Icons.warning_rounded),
                color: colors['icon'], size: 24,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...items.asMap().entries.map((entry) {
            int index = entry.key;
            String text = entry.value;
            bool isItemCorrect = (index < correctItems.length) ? text == correctItems[index] : false;
            
            Color badgeBg = isItemCorrect ? (customColors?.greenBg ?? Theme.of(context).colorScheme.primaryContainer) : Theme.of(context).colorScheme.errorContainer;
            Color badgeText = isItemCorrect ? (customColors?.greenText ?? Theme.of(context).colorScheme.primary) : Theme.of(context).colorScheme.error;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: badgeBg,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${index + 1}.',
                      style: GoogleFonts.inter(
                        color: badgeText,
                        fontWeight: FontWeight.bold, fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          text,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface,
                            decoration: (!isItemCorrect) ? TextDecoration.lineThrough : TextDecoration.none,
                          ),
                        ),
                        if (!hideCorrectAnswers && !isItemCorrect && index < correctItems.length)
                          Text(
                            'Správně: ${correctItems[index]}',
                            style: GoogleFonts.inter(fontSize: 12, color: customColors?.greenText ?? Colors.green, fontWeight: FontWeight.w600),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Vykreslí detail spojovací (MATCHING) otázky – zobrazení párů levé a pravé strany,
  /// jak je student propojil.
  Widget _buildMatchAnswerView(Map<String, dynamic> question, bool hideCorrectAnswers) {
    double awarded = (question['awardedPoints'] ?? 0).toDouble();
    double max = (question['maxPoints'] ?? 1).toDouble();
    var colors = _getFeedbackColors(context, awarded, max);
    final customColors = Theme.of(context).extension<CustomColors>();

    List<Map<String, dynamic>> pairs = List<Map<String, dynamic>>.from(question['studentPairs'] ?? []);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors['bg'],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors['border']!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Odpověď studenta (vytvořené páry):', style: GoogleFonts.inter(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              Icon(
                awarded == max ? Icons.check_circle_rounded : (awarded <= 0 ? Icons.cancel_rounded : Icons.warning_rounded),
                color: colors['icon'], size: 24,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...pairs.map((pair) {
            bool isPairCorrect = pair['isCorrect'] ?? false;
            
            Color rightBoxBg = isPairCorrect ? Theme.of(context).colorScheme.surface : Theme.of(context).colorScheme.errorContainer;
            Color rightBoxBorder = isPairCorrect ? Theme.of(context).colorScheme.outline : Theme.of(context).colorScheme.error.withValues(alpha: 0.3);
            Color rightBoxText = isPairCorrect ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.error;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Theme.of(context).colorScheme.outline),
                      ),
                      child: Text(pair['left'] ?? '', style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Icon(
                      isPairCorrect ? Icons.check_rounded : Icons.close_rounded,
                      color: isPairCorrect ? customColors?.greenText ?? Colors.green : Theme.of(context).colorScheme.error,
                      size: 20,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: rightBoxBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: rightBoxBorder),
                          ),
                          child: Text(
                            pair['right'] ?? '',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w500,
                              color: rightBoxText,
                              decoration: (!isPairCorrect) ? TextDecoration.lineThrough : TextDecoration.none,
                            ),
                          ),
                        ),
                        if (!hideCorrectAnswers && !isPairCorrect && pair['correctRight'] != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0, left: 4.0),
                            child: Text(
                              'Správně: ${pair['correctRight']}',
                              style: GoogleFonts.inter(fontSize: 12, color: customColors?.greenText ?? Colors.green, fontWeight: FontWeight.w600),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Sekce pro manuální (otevřené) otázky (např. 'open'). Zobrazí textové
  /// pole pro zpětnou vazbu učitele a input pro manuální udělení bodů.
  Widget _buildOpenQuestionEvaluation(Map<String, dynamic> question, TestEvaluationNotifier notifier, bool hideCorrectAnswers) {
    String qId = question['id'] ?? '';
    if (!_pointsControllers.containsKey(qId)) return const SizedBox();
    
    double maxPoints = (question['maxPoints'] ?? 0).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).colorScheme.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Odpověď studenta:', style: GoogleFonts.inter(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 8),
              Text(
                question['studentAnswer'] ?? '',
                style: GoogleFonts.inter(fontStyle: FontStyle.italic, color: Theme.of(context).colorScheme.onSurface, height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 4,
              child: TextFormField(
                controller: _feedbackControllers[qId],
                readOnly: widget.isStudent,
                maxLines: 3,
                style: GoogleFonts.inter(fontSize: 14, color: Theme.of(context).colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: 'Zpětná vazba pro studenta (volitelné)',
                  labelStyle: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).colorScheme.outline)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).colorScheme.outline)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary)),
                ),
                onChanged: (val) {
                  if (!widget.isStudent) {
                    notifier.updateFeedback(qId, val);
                  }
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: TextFormField(
                controller: _pointsControllers[qId],
                readOnly: widget.isStudent,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*([.,]\d{0,2})?'))],
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: 'Body',
                  labelStyle: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  suffixText: '/ $maxPoints',
                  suffixStyle: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).colorScheme.outline)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).colorScheme.outline)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary)),
                ),
                onChanged: (val) {
                  if (widget.isStudent) return;
                  double? enteredPoints = double.tryParse(val.replaceAll(',', '.'));
                  if (enteredPoints != null) {
                    if (enteredPoints > maxPoints) {
                      String clampedStr = maxPoints.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
                      _pointsControllers[qId]!.text = clampedStr;
                      _pointsControllers[qId]!.selection = TextSelection.fromPosition(TextPosition(offset: clampedStr.length));
                      notifier.updatePoints(qId, clampedStr);
                    } else if (enteredPoints < 0) {
                      _pointsControllers[qId]!.text = '0';
                      _pointsControllers[qId]!.selection = const TextSelection.collapsed(offset: 1);
                      notifier.updatePoints(qId, '0');
                    } else {
                      notifier.updatePoints(qId, val);
                    }
                  } else {
                    notifier.updatePoints(qId, '');
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
