import 'package:flutter/material.dart';
import '../../components/sidebar_teacher_widget.dart';

class TestEvaluationWidget extends StatefulWidget {
  const TestEvaluationWidget({super.key});

  @override
  State<TestEvaluationWidget> createState() => _TestEvaluationWidgetState();
}

class _TestEvaluationWidgetState extends State<TestEvaluationWidget> {
  // Ovladače pro textová pole (zpětná vazba a body)
  late TextEditingController _feedbackController;
  late FocusNode _feedbackFocusNode;
  late TextEditingController _pointsController;
  late FocusNode _pointsFocusNode;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // Inicializace s ukázkovým textem z původního návrhu
    _feedbackController = TextEditingController(
      text: "Skvělý popis! Zkuste příště zahrnout termín 'selektivní propustnost'.",
    );
    _feedbackFocusNode = FocusNode();

    _pointsController = TextEditingController(text: '3');
    _pointsFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    _feedbackFocusNode.dispose();
    _pointsController.dispose();
    _pointsFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: const Color(0xFFF5F7FA), // Světlé pozadí
      body: SafeArea(
        child: Stack(
          children: [
            // HLAVNÍ OBSAH 
            Padding(
              padding: const EdgeInsets.only(left: 85.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // HORNÍ HLAVIČKA S INFO O STUDENTOVI
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.0),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Jan Zápotocký',
                              style: TextStyle(fontSize: 26.0, fontWeight: FontWeight.w800, color: Colors.black87),
                            ),
                            Text('Biologie - Buňka 1', style: TextStyle(fontSize: 16.0, color: Colors.grey)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('3.C bio', style: TextStyle(fontSize: 26.0, fontWeight: FontWeight.w800, color: Colors.black87)),
                            Text('12.05.2025', style: TextStyle(fontSize: 16.0, color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // SEZNAM OTÁZEK K OHODNOCENÍ
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          // 1. OTÁZKA (ROZBALENÁ)
                          _buildEvaluationCard(
                            isExpanded: true,
                            questionNumber: "1. Výběr z možností",
                            status: "Automaticky opraveno",
                            score: "1 / 1",
                            questionText: "Co je energetickým centrem buňky?",
                            child: _buildChoiceAnswerView(),
                          ),
                          
                          const SizedBox(height: 16.0),

                          // 2. OTÁZKA (ROZBALENÁ S FORMULÁŘEM)
                          _buildEvaluationCard(
                            isExpanded: true,
                            questionNumber: "2. Otevřená otázka",
                            status: "", // Ruční oprava
                            score: "Body: 3 / 5",
                            questionText: "Stručně popište funkci buněčné membrány.",
                            child: _buildOpenQuestionEvaluation(),
                          ),

                          const SizedBox(height: 16.0),

                          // 3. OTÁZKA (SBALENÁ)
                          _buildEvaluationCard(
                            isExpanded: false,
                            questionNumber: "3. Krátká odpověď",
                            status: "",
                            score: "Body: - / 2",
                            questionText: "Jak se nazývá...",
                            child: const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // BOČNÍ PANEL
            const SidebarTeacherWidget(activePage: 'classes'),
          ],
        ),
      ),
    );
  }

  // Pomocný widget pro kartu otázky
  Widget _buildEvaluationCard({
    required bool isExpanded,
    required String questionNumber,
    required String status,
    required String score,
    required String questionText,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(questionNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  if (status.isNotEmpty) Text(' · $status', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
              Row(
                children: [
                  Text(score, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0056D2))),
                  const SizedBox(width: 8),
                  Icon(isExpanded ? Icons.expand_less : Icons.expand_more, color: Colors.grey),
                ],
              ),
            ],
          ),
          if (isExpanded) ...[
            const SizedBox(height: 12),
            Text(questionText, style: const TextStyle(fontSize: 16, color: Colors.black87)),
            const SizedBox(height: 16),
            child,
          ]
        ],
      ),
    );
  }

  // Vizuál odpovědi u "Výběru z možností"
  Widget _buildChoiceAnswerView() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9), // Světle zelená (správně)
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: const Row(
        children: [
          Text('A.', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(width: 12),
          Expanded(child: Text('Mitochondrie')),
          Icon(Icons.check_rounded, color: Colors.green),
        ],
      ),
    );
  }

  // Formulář pro hodnocení otevřené otázky
  Widget _buildOpenQuestionEvaluation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Odpověď studenta
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(12)),
          child: const Text(
            'Buněčná membrána funguje jako bariéra, která kontroluje vstup a výstup látek...',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        ),
        const SizedBox(height: 16),
        // Feedback a body
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: _feedbackController,
                maxLines: 3,
                decoration: _inputDecoration('Slovní hodnocení (formativní)', 'Napište zpětnou vazbu...'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: TextFormField(
                controller: _pointsController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration('Body', '0'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: () => print('Hodnocení uloženo'),
            icon: const Icon(Icons.save, size: 18),
            label: const Text('Uložit hodnocení'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3D5AF1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
}