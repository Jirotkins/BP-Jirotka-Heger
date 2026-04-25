import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import '../../components/sidebar_teacher_widget.dart';

// Obrazovka pro kontrolu a hodnocení odevzdaného testu učitelem.
// Přijímá (zatím z mock dat, později přes API) detaily o testu a odpovědích studenta.
class TestEvaluationWidget extends StatefulWidget {
  const TestEvaluationWidget({super.key});

  @override
  State<TestEvaluationWidget> createState() => _TestEvaluationWidgetState();
}

class _TestEvaluationWidgetState extends State<TestEvaluationWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();


  Map<String, dynamic> _testData = {
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
        "studentAnswer": [
          "Profáze",
          "Metafáze",
          "Anafáze",
          "Telofáze"
        ],
        "correctOrder": [
          "Profáze",
          "Metafáze",
          "Anafáze",
          "Telofáze"
        ],
        "isCorrect": true,
        "awardedPoints": 4, // Zelená (vše správně)
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
          {"left": "Ribozom", "right": "Uchování DNA", "isCorrect": false, "correctRight": "Syntéza bílkovin"},
          {"left": "Chloroplast", "right": "Fotosyntéza", "isCorrect": true},
          {"left": "Jádro", "right": "Syntéza bílkovin", "isCorrect": false, "correctRight": "Uchování DNA"} 
        ],
        "isCorrect": false,
        "awardedPoints": 1, // Oranžová - Částečně správně (1 ze 3)
        "maxPoints": 3,
        "isAutoGraded": true,
        "isExpanded": true,
      }
    ]
  };

  // Lokální kontrolery pro textová pole (udržují rozepsané body a feedback učitele)
  final Map<String, TextEditingController> _feedbackControllers = {};
  final Map<String, TextEditingController> _pointsControllers = {};

  @override
  void initState() {
    super.initState();
    // Inicializace textových polí předvyplněnými daty z API
    for (var question in _testData['questions']) {
      if (question['type'] == 'open') {
        _feedbackControllers[question['id']] = TextEditingController(text: question['teacherFeedback'] ?? '');
        _pointsControllers[question['id']] = TextEditingController(text: question['awardedPoints']?.toString() ?? '');
      }
    }
  }

  @override
  void dispose() {
    // Uvolnění paměti pro všechny vytvořené kontrolery
    for (var controller in _feedbackControllers.values) {
      controller.dispose();
    }
    for (var controller in _pointsControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }


  double _calculateCurrentTotal() {
    double total = 0;
    for (var question in _testData['questions']) {
      if (question['isAutoGraded'] == true) {
        total += (question['awardedPoints'] ?? 0).toDouble();
      } else {
        var controller = _pointsControllers[question['id']];
        if (controller != null && controller.text.isNotEmpty) {
          total += double.tryParse(controller.text.replaceAll(',', '.')) ?? 0;
        }
      }
    }
    return total;
  }


  void _submitEvaluation() {
    List<Map<String, dynamic>> gradedAnswers = [];
    for (var question in _testData['questions']) {
      if (question['type'] == 'open') {
        gradedAnswers.add({
          "question_id": question['id'],
          "awarded_points": double.tryParse(_pointsControllers[question['id']]!.text.replaceAll(',', '.')) ?? 0,
          "feedback": _feedbackControllers[question['id']]!.text,
        });
      }
    }

    print("Odesílám na backend payload: $gradedAnswers");
    
    // Potvrzení uložení a návrat zpět
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Hodnocení bylo úspěšně uloženo.'),
        backgroundColor: Color(0xFF16A34A),
        duration: Duration(seconds: 2),
      ),
    );
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Zobrazení desetinného čísla bez zbytečné '.0' na konci (např. 14.0 -> 14)
    String currentTotalDisplay = _calculateCurrentTotal().toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 85.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // HORNÍ HLAVIČKA (Základní info o studentovi a testu)
                  Container(
                    margin: const EdgeInsets.all(32.0).copyWith(bottom: 16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.0),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_testData['studentName'] ?? 'Neznámý', style: GoogleFonts.inter(fontSize: 26.0, fontWeight: FontWeight.w800, color: const Color(0xFF111827))),
                            const SizedBox(height: 4),
                            Text('${_testData['subject']} • Odevzdáno: ${_testData['submittedAt']}', style: GoogleFonts.inter(fontSize: 14.0, color: const Color(0xFF6B7280))),
                          ],
                        ),
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(_testData['classGroup'] ?? '', style: GoogleFonts.inter(fontSize: 16.0, fontWeight: FontWeight.bold, color: const Color(0xFF374151))),
                                const SizedBox(height: 4),
                                Text('Průběžně: $currentTotalDisplay / ${_testData['maxScore']} b.', style: GoogleFonts.inter(fontSize: 14.0, fontWeight: FontWeight.w600, color: const Color(0xFF0056D2))),
                              ],
                            ),
                            const SizedBox(width: 32.0),
                            ElevatedButton.icon(
                              onPressed: _submitEvaluation,
                              icon: const Icon(Icons.check_circle_outline, size: 18),
                              label: Text('Dokončit hodnocení', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0056D2),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                                elevation: 0,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // DYNAMICKÝ SEZNAM OTÁZEK
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 8.0),
                      itemCount: _testData['questions']?.length ?? 0,
                      itemBuilder: (context, index) {
                        var question = _testData['questions'][index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: _buildDynamicEvaluationCard(question, index),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SidebarTeacherWidget(activePage: 'classes'),
          ],
        ),
      ),
    );
  }

  // Helper pro vizuální podbarvení celého bloku otázky (zelená = plný počet, červená = 0, oranžová = částečné)
  Map<String, Color> _getFeedbackColors(double awarded, double max) {
    if (awarded == max) {
      return {'bg': const Color(0xFFF0FDF4), 'border': const Color(0xFF86EFAC), 'icon': const Color(0xFF16A34A)}; 
    } else if (awarded <= 0) {
      return {'bg': const Color(0xFFFEF2F2), 'border': const Color(0xFFFCA5A5), 'icon': const Color(0xFFDC2626)}; 
    } else {
      return {'bg': const Color(0xFFFFFBEB), 'border': const Color(0xFFFCD34D), 'icon': const Color(0xFFD97706)}; 
    }
  }

  // Univerzální obal (hlavička karty) pro libovolnou otázku
  Widget _buildDynamicEvaluationCard(Map<String, dynamic> question, int index) {
    // BEZPEČNOSTNÍ POJISTKY PROTI PÁDU APLIKACE (Fallback hodnoty v případě chybějících dat)
    bool isExpanded = question['isExpanded'] ?? false;
    bool isAutoGraded = question['isAutoGraded'] ?? false;
    
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
      String id = question['id'] ?? '';
      scoreDisplay = (_pointsControllers[id]?.text.isEmpty ?? true)
          ? "- / ${question['maxPoints'] ?? 0} b." 
          : "${_pointsControllers[id]!.text} / ${question['maxPoints'] ?? 0} b.";
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: isAutoGraded ? const Color(0xFFE5E7EB) : const Color(0xFFBFDBFE), width: isAutoGraded ? 1.0 : 2.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => question['isExpanded'] = !isExpanded),
            borderRadius: BorderRadius.circular(16.0),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF111827))),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isAutoGraded ? const Color(0xFFF3F4F6) : const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isAutoGraded ? 'Automaticky opraveno' : 'Vyžaduje kontrolu', 
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: isAutoGraded ? const Color(0xFF4B5563) : const Color(0xFFD97706))
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(scoreDisplay, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: isAutoGraded ? const Color(0xFF374151) : const Color(0xFF0056D2))),
                      const SizedBox(width: 16),
                      Icon(isExpanded ? Icons.expand_less : Icons.expand_more, color: const Color(0xFF9CA3AF)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          if (isExpanded) ...[
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(question['text'] ?? '', style: GoogleFonts.inter(fontSize: 16, color: const Color(0xFF111827), fontWeight: FontWeight.w500)),
                  const SizedBox(height: 20),
                  
                  // Distribuce vykreslení obsahu na základě 'type' z JSONu
                  if (question['type'] == 'choice' || question['type'] == 'short_answer') 
                    _buildAutoGradedAnswerView(question)
                  else if (question['type'] == 'open')
                    _buildOpenQuestionEvaluation(question)
                  else if (question['type'] == 'order')
                    _buildOrderAnswerView(question)
                  else if (question['type'] == 'match')
                    _buildMatchAnswerView(question),
                ],
              ),
            )
          ]
        ],
      ),
    );
  }

  // Obyčejný Single/Multi Choice a Krátká odpověď
  Widget _buildAutoGradedAnswerView(Map<String, dynamic> question) {
    bool isCorrect = question['isCorrect'] ?? false;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCorrect ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2), 
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isCorrect ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Odpověď studenta:', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280))),
                const SizedBox(height: 4),
                Text(question['studentAnswer'] ?? '', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF111827))),
              ],
            )
          ),
          Icon(isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded, color: isCorrect ? const Color(0xFF16A34A) : const Color(0xFFDC2626), size: 28),
        ],
      ),
    );
  }

  // Zobrazení seřazení s podporou částečných bodů
  Widget _buildOrderAnswerView(Map<String, dynamic> question) {
    double awarded = (question['awardedPoints'] ?? 0).toDouble();
    double max = (question['maxPoints'] ?? 1).toDouble();
    var colors = _getFeedbackColors(awarded, max);
    
    List<String> items = List<String>.from(question['studentAnswer'] ?? []);
    List<String> correctItems = List<String>.from(question['correctOrder'] ?? items);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors['bg'], borderRadius: BorderRadius.circular(12), border: Border.all(color: colors['border']!)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Odpověď studenta (seřazeno):', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280))),
              Icon(awarded == max ? Icons.check_circle_rounded : (awarded <= 0 ? Icons.cancel_rounded : Icons.warning_rounded), color: colors['icon'], size: 24),
            ],
          ),
          const SizedBox(height: 16),
          ...items.asMap().entries.map((entry) {
            int index = entry.key;
            String text = entry.value;
            // Ochrana před chybou IndexOutOfRange
            bool isItemCorrect = (index < correctItems.length) ? text == correctItems[index] : false;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: isItemCorrect ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text('${index + 1}.', style: GoogleFonts.inter(color: isItemCorrect ? const Color(0xFF16A34A) : const Color(0xFFDC2626), fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(text, style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: const Color(0xFF111827), decoration: isItemCorrect ? TextDecoration.none : TextDecoration.lineThrough)),
                        if (!isItemCorrect && index < correctItems.length)
                          Text('Správně: ${correctItems[index]}', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF16A34A), fontWeight: FontWeight.w600)),
                      ],
                    )
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // Zobrazení párování s podporou částečných bodů
  Widget _buildMatchAnswerView(Map<String, dynamic> question) {
    double awarded = (question['awardedPoints'] ?? 0).toDouble();
    double max = (question['maxPoints'] ?? 1).toDouble();
    var colors = _getFeedbackColors(awarded, max);

    List<Map<String, dynamic>> pairs = List<Map<String, dynamic>>.from(question['studentPairs'] ?? []);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors['bg'], borderRadius: BorderRadius.circular(12), border: Border.all(color: colors['border']!)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Odpověď studenta (vytvořené páry):', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280))),
              Icon(awarded == max ? Icons.check_circle_rounded : (awarded <= 0 ? Icons.cancel_rounded : Icons.warning_rounded), color: colors['icon'], size: 24),
            ],
          ),
          const SizedBox(height: 16),
          ...pairs.map((pair) {
            bool isPairCorrect = pair['isCorrect'] ?? false;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE5E7EB))),
                      child: Text(pair['left'] ?? '', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Icon(isPairCorrect ? Icons.check_rounded : Icons.close_rounded, color: isPairCorrect ? const Color(0xFF16A34A) : const Color(0xFFDC2626), size: 20),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isPairCorrect ? Colors.white : const Color(0xFFFEF2F2), 
                            borderRadius: BorderRadius.circular(8), 
                            border: Border.all(color: isPairCorrect ? const Color(0xFFE5E7EB) : const Color(0xFFFCA5A5))
                          ),
                          child: Text(pair['right'] ?? '', style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: isPairCorrect ? const Color(0xFF111827) : const Color(0xFFDC2626), decoration: isPairCorrect ? TextDecoration.none : TextDecoration.lineThrough)),
                        ),
                        if (!isPairCorrect && pair['correctRight'] != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0, left: 4.0),
                            child: Text('Správně: ${pair['correctRight']}', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF16A34A), fontWeight: FontWeight.w600)),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // Zobrazení otevřené otázky (Ta jediná obsahuje formulářové prvky pro input učitele)
  Widget _buildOpenQuestionEvaluation(Map<String, dynamic> question) {
    String qId = question['id'] ?? '';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Odpověď studenta:', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280))),
              const SizedBox(height: 8),
              Text(question['studentAnswer'] ?? '', style: GoogleFonts.inter(fontStyle: FontStyle.italic, color: const Color(0xFF374151), height: 1.5)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kontroler pro formativní (slovní) hodnocení
            Expanded(
              flex: 4,
              child: TextFormField(
                controller: _feedbackControllers[qId],
                maxLines: 3,
                style: GoogleFonts.inter(fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Slovní hodnocení (formativní)',
                  hintText: 'Napište zpětnou vazbu...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0056D2))),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Kontroler pro numerické hodnocení
            Expanded(
              flex: 1,
              child: TextFormField(
                controller: _pointsControllers[qId],
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                
                // Formatter pro zajištění pouze 2 desetinných míst a validních znaků
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*([.,]\d{0,2})?')),
                ],
                
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18),
                decoration: InputDecoration(
                  labelText: 'Udělené body',
                  hintText: '0',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0056D2))),
                ),
                onChanged: (val) {
                  // Ochrana před zadáním počtu bodů, které přesahují maximum
                  double maxPoints = (question['maxPoints'] ?? 0).toDouble();
                  double? enteredPoints = double.tryParse(val.replaceAll(',', '.'));
                  if (enteredPoints != null) {
                    if (enteredPoints > maxPoints) {
                      String clampedStr = maxPoints.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
                      _pointsControllers[qId]!.text = clampedStr;
                      _pointsControllers[qId]!.selection = TextSelection.fromPosition(TextPosition(offset: clampedStr.length));
                    } else if (enteredPoints < 0) {
                      _pointsControllers[qId]!.text = '0';
                      _pointsControllers[qId]!.selection = const TextSelection.collapsed(offset: 1);
                    }
                  }
                  // Zavolá překreslení, aby se updatovala horní hlavička scóre
                  setState(() {});
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}