import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../components/test_submit_popup_widget.dart';
import '../../components/test_exit_popup_widget.dart';

// Hlavní obrazovka pro vyplňování testu studentem.
// Dynamicky renderuje různé typy otázek a spravuje lokální stav odpovědí.
class TestActiveWidget extends StatefulWidget {
  const TestActiveWidget({super.key});

  @override
  State<TestActiveWidget> createState() => _TestActiveWidgetState();
}

class _TestActiveWidgetState extends State<TestActiveWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  // --- STAVOVÉ PROMĚNNÉ ---
  
  // Index aktuálně zobrazené otázky (od 0 do _mockQuestions.length - 1)
  int _currentIndex = 0;
  
  // Lokální úložiště odpovědí studenta.
  // Klíč = index otázky, Hodnota = dynamická (String, List, nebo Map podle typu otázky).
  // Tento objekt se po dokončení serializuje do JSONu a pošle na server.
  final Map<int, dynamic> _selectedAnswers = {};

  // Kontroler pro textová pole (otevřené a krátké odpovědi).
  final TextEditingController _textController = TextEditingController();

  // --- DATOVÝ MODEL (MOCK) ---
  
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
      // API pošle položky náhodně zamíchané
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
  void initState() {
    super.initState();
    // Načte případnou textovou odpověď do kontroleru při prvním spuštění
    _loadAnswerForCurrentQuestion();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  // --- NAVIGAČNÍ A OBSLUŽNÁ LOGIKA ---

  // Zajistí, že při posunu vpřed/vzad se textové pole správně předvyplní uloženou odpovědí.
  void _loadAnswerForCurrentQuestion() {
    var qType = _mockQuestions[_currentIndex]['type'];
    if (qType == 'open' || qType == 'short_answer') {
      _textController.text = _selectedAnswers[_currentIndex] ?? '';
    }
  }

  // Přechod na další otázku nebo odevzdání testu, pokud jsme na konci.
  void _nextQuestion() {
    if (_currentIndex < _mockQuestions.length - 1) {
      setState(() {
        _currentIndex++;
        _loadAnswerForCurrentQuestion();
      });
    } else {
      _submitTest();
    }
  }

  // Návrat na předchozí otázku.
  void _previousQuestion() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _loadAnswerForCurrentQuestion();
      });
    }
  }

  // Zobrazí popup pro finální odevzdání a po potvrzení odesílá data na API.
  void _submitTest() {
    int answeredCount = _selectedAnswers.length;

    showDialog(
      context: context,
      barrierDismissible: false, // Nelze zavřít kliknutím mimo okno
      builder: (dialogContext) => TestSubmitPopupWidget(
        answeredQuestions: answeredCount,
        totalQuestions: _mockQuestions.length,
        onSubmit: () {
          // Odesíláme mapu '_selectedAnswers'.
          print('Odesláno na backend: $_selectedAnswers');
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Test byl úspěšně odevzdán!'), backgroundColor: Color(0xFF16A34A)),
          );
          Navigator.pop(context); // Návrat do přehledu předmětu
        },
      ),
    );
  }

  // Zobrazí varování před opuštěním rozepsaného testu (např. při kliknutí na křížek).
  void _showExitWarning() {
    showDialog(
      context: context,
      builder: (dialogContext) => TestExitPopupWidget(
        onExit: () {
          Navigator.pop(context); 
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. Zpracování argumentů z navigace
    final args = GoRouterState.of(context).extra as Map<String, dynamic>?;
    final String testTitle = args?['testTitle'] ?? 'Biologie - Buňka 1';

    // 2. Výpočet pro progress bar
    int totalQuestions = _mockQuestions.length;
    double progress = (_currentIndex + 1) / totalQuestions;

    // Aktuální otázka pro vykreslení
    var currentQuestion = _mockQuestions[_currentIndex];

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      
      body: SafeArea(
        child: Column(
          children: [
            // --- SJEDNOCENÁ HLAVIČKA TESTU ---
            // Obsahuje křížek, název testu, odpočet a plynulý progress bar.
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
                        onTap: _showExitWarning,
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(padding: const EdgeInsets.all(4.0), child: Icon(Icons.close_rounded, color: Theme.of(context).colorScheme.onSurface, size: 24)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(testTitle, style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface, fontSize: 18)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Otázka ${_currentIndex + 1} z $totalQuestions', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600, fontSize: 14.0)),
                      Row(
                        children: [
                          Icon(Icons.timer_outlined, color: Theme.of(context).colorScheme.error, size: 18),
                          const SizedBox(width: 6),
                          Text('14:10', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.bold, fontSize: 16.0)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12.0),
                  // Progress Bar
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
            // ------------------------------------

            // --- OBLAST OTÁZKY A ODPOVĚDÍ ---
            // Zde se dynamicky renderuje obsah podle typu otázky v JSONu.
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Znění otázky
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16.0),
                        border: Border.all(color: Theme.of(context).colorScheme.outline),
                        boxShadow: [BoxShadow(color: Theme.of(context).shadowColor.withValues(alpha: 0.04), blurRadius: 10.0, offset: const Offset(0, 4))],
                      ),
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        currentQuestion['text'],
                        style: GoogleFonts.inter(fontSize: 18.0, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface, height: 1.4),
                      ),
                    ),
                    const SizedBox(height: 32.0),

                    // Dynamický renderovač odpovědí
                    if (currentQuestion['type'] == 'choice')
                      _buildChoiceQuestion(currentQuestion)
                    else if (currentQuestion['type'] == 'open' || currentQuestion['type'] == 'short_answer')
                      _buildTextQuestion(currentQuestion)
                    else if (currentQuestion['type'] == 'order')
                      _buildOrderQuestion(currentQuestion)
                    else if (currentQuestion['type'] == 'match')
                      _buildMatchQuestion(currentQuestion),

                    const SizedBox(height: 24.0),
                  ],
                ),
              ),
            ),

            // --- SPODNÍ NAVIGAČNÍ TLAČÍTKA ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outline)), boxShadow: [BoxShadow(color: Theme.of(context).shadowColor.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))]),
              child: SafeArea(
                top: false, // Safe area řešíme jen pro spodní lištu (notch na iPhonech)
                child: Row(
                  children: [
                    // Tlačítko zpět (schované na první otázce)
                    if (_currentIndex > 0) ...[
                      InkWell(
                        onTap: _previousQuestion,
                        borderRadius: BorderRadius.circular(24.0),
                        child: Container(
                          height: 52, width: 52,
                          decoration: BoxDecoration(border: Border.all(color: Theme.of(context).colorScheme.outline, width: 1.5), shape: BoxShape.circle),
                          child: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
                        ),
                      ),
                      const SizedBox(width: 16.0),
                    ],
                    // Hlavní tlačítko (Další otázka / Odevzdat test)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _nextQuestion,
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
                              _currentIndex == totalQuestions - 1 ? 'Odevzdat test' : 'Další otázka', 
                              style: GoogleFonts.inter(fontSize: 16.0, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimary)
                            ),
                            const SizedBox(width: 8),
                            Icon(_currentIndex == totalQuestions - 1 ? Icons.check_circle_outline : Icons.arrow_forward, color: Theme.of(context).colorScheme.onPrimary, size: 20),
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
    );
  }

  // =========================================================
  // WIDGETY PRO JEDNOTLIVÉ TYPY OTÁZEK
  // =========================================================

  // 1. VÝBĚR Z MOŽNOSTÍ (Single Choice)
  // Ukládá do state vybrané písmeno (např. 'A').
  Widget _buildChoiceQuestion(Map<String, dynamic> question) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Vyberte jednu správnou odpověď:', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.bold, fontSize: 13.0)),
        const SizedBox(height: 12.0),
        ...List.generate(question['options'].length, (index) {
          var option = question['options'][index];
          bool isSelected = _selectedAnswers[_currentIndex] == option['letter'];
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: InkWell(
              onTap: () => setState(() => _selectedAnswers[_currentIndex] = option['letter']),
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

  // 2. TEXTOVÁ ODPOVĚĎ (Open / Short Answer)
  // Ukládá do state napsaný text (String).
  Widget _buildTextQuestion(Map<String, dynamic> question) {
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
            // Ukládá potichu bez setState, aby nezmizela klávesnice při psaní!
            _selectedAnswers[_currentIndex] = val;
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

  // 3. SEŘAZENÍ (Drag & Drop)
  // Ukládá do state nové pole s aktuálním pořadím prvků (List<String>).
  Widget _buildOrderQuestion(Map<String, dynamic> question) {
    // Pokud žák ještě nic nepřesunul, použijeme výchozí pole od serveru
    List<String> items = _selectedAnswers[_currentIndex] ?? List<String>.from(question['items']);
    
    // Pro jistotu uložíme výchozí stav rovnou, pokud by žák jen kliknul na "Další"
    _selectedAnswers[_currentIndex] = items;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Seřaďte položky (podržte a přetáhněte):', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.bold, fontSize: 13.0)),
        const SizedBox(height: 12.0),
        
        // ReorderableListView nativně řeší plynulé animace přesunů
        ReorderableListView.builder(
          shrinkWrap: true, // Nutné uvnitř ScrollView
          physics: const NeverScrollableScrollPhysics(), 
          itemCount: items.length,
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (newIndex > oldIndex) {
                newIndex -= 1;
              }
              final String item = items.removeAt(oldIndex);
              items.insert(newIndex, item);
              _selectedAnswers[_currentIndex] = items; // Uložíme nové pořadí
            });
          },
          itemBuilder: (context, index) {
            return Container(
              key: ValueKey(items[index]), // Klíč je vyžadován frameworkem pro správný drag & drop
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

  // 4. PÁROVÁNÍ (Dropdowny)
  // Ukládá do state slovník vytvořených párů, např. {"Ribozom": "Syntéza bílkovin", ...} (Map<String, String>).
  Widget _buildMatchQuestion(Map<String, dynamic> question) {
    List<String> leftItems = List<String>.from(question['leftItems']);
    List<String> rightOptions = List<String>.from(question['rightItems']);
    
    // Načteme dosud vytvořené páry, nebo vytvoříme novou prázdnou mapu
    Map<String, String> pairs = _selectedAnswers[_currentIndex] ?? {};
    _selectedAnswers[_currentIndex] = pairs;

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
                
                // Roletka pro výběr pravé části páru
                DropdownButtonFormField<String>(
                  value: pairs[leftItem], 
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
                    setState(() {
                      if (newValue != null) pairs[leftItem] = newValue;
                      _selectedAnswers[_currentIndex] = pairs; // Uložení do globálního stavu testu
                    });
                  },
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
}