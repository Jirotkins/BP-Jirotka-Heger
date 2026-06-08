import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../components/page_header_widget.dart';
import '../../components/question_row_widget.dart';

class QuestionsOverviewWidget extends StatefulWidget {
  const QuestionsOverviewWidget({super.key});

  @override
  State<QuestionsOverviewWidget> createState() => _QuestionsOverviewWidgetState();
}

class _QuestionsOverviewWidgetState extends State<QuestionsOverviewWidget> {
  // Ukázková data
  final List<Map<String, dynamic>> _mockQuestions = [
    {'id': 1, 'question': 'Jaká je přibližná hodnota gravitačního zrychlení na povrchu Země?', 'type': 'Výběr z možností'},
    {'id': 2, 'question': 'Vysvětlete princip gravitačního zákona Isaaca Newtona.', 'type': 'Otevřená'},
    {'id': 3, 'question': 'Vypočítejte gravitační sílu mezi dvěma tělesy o hmotnostech 10 kg a 20 kg...', 'type': 'Krátká odpověď'},
    {'id': 4, 'question': 'Seřaďte planety sluneční soustavy podle velikosti gravitačního zrychlení.', 'type': 'Seřazení'},
    {'id': 5, 'question': 'Přiřaďte správné hodnoty gravitačního zrychlení k jednotlivým planetám.', 'type': 'Párování'},
    {'id': 6, 'question': 'Vyberte všechny faktory, které ovlivňují velikost gravitační síly.', 'type': 'Výběr z možností'},
    {'id': 7, 'question': 'Co se stane s gravitační silou, pokud se vzdálenost mezi tělesy zdvojnásobí?', 'type': 'Krátká odpověď'},
  ];

  @override
  Widget build(BuildContext context) {
    // ZÍSKÁNÍ PARAMETRŮ Z NAVIGACE (Přebírá z BankCardWidget)
    final args = GoRouterState.of(context).extra as Map<String, dynamic>?;
    final String bankName = args?['bankName'] ?? 'Neznámá banka';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        
        // --- DYNAMICKÁ HLAVIČKA ---
        PageHeaderWidget(
          title: bankName, 
          actions: [
            // TLAČÍTKO: Přidat novou otázku 
            ElevatedButton.icon(
              onPressed: () {
                // Přesměrování na tvorbu otázky s předáním názvu banky
                context.push('/addNewQuestion', extra: {
                    'targetName': bankName, 
                  },);
              },
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: Text(
                'Přidat novou otázku',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0056D2),
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 40),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
              ),
            ),
          ],
        ),

        // --- HLAVNÍ PLOCHA (SEZNAM OTÁZEK) ---
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 10.0,
                    color: Colors.black.withOpacity(0.02),
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              // Vnitřní padding kontejneru
              child: ListView.separated(
                padding: const EdgeInsets.all(24.0),
                itemCount: _mockQuestions.length,
                separatorBuilder: (context, index) => const Divider(
                  height: 32.0, // Mezera kolem čáry
                  thickness: 1.0,
                  color: Color(0xFFF3F4F6), 
                ),
                itemBuilder: (context, index) {
                  final questionData = _mockQuestions[index];
                  return QuestionRowWidget(
                    id: questionData['id'],
                    question: questionData['question'],
                    type: questionData['type'],
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}