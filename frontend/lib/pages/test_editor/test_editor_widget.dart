import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../components/page_header_widget.dart';
import '../../components/bank_select_row_widget.dart';
import '../../components/question_select_row_widget.dart';
import '../../components/test_settings_widget.dart';
import '../../components/time_settings_widget.dart';

class TestEditorWidget extends StatefulWidget {
  const TestEditorWidget({super.key});

  @override
  State<TestEditorWidget> createState() => _TestEditorWidgetState();
}

class _TestEditorWidgetState extends State<TestEditorWidget> {
  late TextEditingController _testNameController;
  late FocusNode _testNameFocusNode;

  // Ukázková data pro banky
  final List<Map<String, dynamic>> _mockBanks = [
    {'name': 'Fyzika - Gravitační pole', 'icon': Icons.menu_book_outlined, 'count': 8},
    {'name': 'Fyzika - Kinematika hmotného bodu', 'icon': Icons.menu_book_outlined, 'count': 7},
    {'name': 'Fyzika - Veličiny a jednotky', 'icon': Icons.menu_book_outlined, 'count': 20},
    {'name': 'Matematika - Kvadratické rovnice', 'icon': Icons.calculate_outlined, 'count': 15},
    {'name': 'Biologie - Buňka', 'icon': Icons.science_outlined, 'count': 18},
  ];

  // Ukázková data pro otázky
  final List<Map<String, dynamic>> _mockQuestions = [
    {'text': 'Jaká je přibližná hodnota gravitačního zrychlení...', 'type': 'Výběr'},
    {'text': 'Vysvětlete princip gravitačního zákona...', 'type': 'Otevřená'},
    {'text': 'Vypočítejte gravitační sílu mezi dvěma tělesy...', 'type': 'Krátká'},
    {'text': 'Seřaďte planety sluneční soustavy...', 'type': 'Seřazení'},
    {'text': 'Přiřaďte správné hodnoty gravitačního zrychlení...', 'type': 'Párování'},
  ];

  @override
  void initState() {
    super.initState();
    _testNameController = TextEditingController();
    _testNameFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _testNameController.dispose();
    _testNameFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ZÍSKÁNÍ DAT Z NAVIGACE (z ClassManagerWidget)
    final args = GoRouterState.of(context).extra as Map<String, dynamic>?;
    final String targetClass = args?['targetName'] ?? 'Neznámá třída';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        
        // --- DYNAMICKÁ HLAVIČKA ---
        PageHeaderWidget(
          title: 'Nový test — $targetClass',
          actions: const [],
        ),

        // --- SCROLLOVACÍ ČÁST EDITORU ---
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                
                // VSTUP PRO NÁZEV TESTU
                _buildTestNameInput(),
                const SizedBox(height: 24.0),

                // ROZBALOVACÍ SEKCE: VÝBĚR BANEK
                _buildExpandableSection(
                  title: 'BANKY OTÁZEK',
                  subtitle: 'Rozklikněte a vyberte konkrétní banku otázek',
                  icon: Icons.folder_open_rounded,
                  children: _mockBanks.map((bank) => BankSelectRowWidget(
                    bank: bank['name'],
                    icon: Icon(bank['icon'], color: Theme.of(context).colorScheme.primary, size: 28),
                    questions: bank['count'],
                  )).toList(),
                ),
                const SizedBox(height: 24.0),

                // ROZBALOVACÍ SEKCE: VÝBĚR OTÁZEK
                _buildExpandableSection(
                  title: 'VÝBĚR OTÁZEK',
                  subtitle: 'Rozklikněte a vyberte konkrétní otázky z vybraných bank',
                  icon: Icons.list_alt_rounded,
                  children: _mockQuestions.map((q) => QuestionSelectRowWidget(
                    question: q['text'],
                    type: q['type'],
                  )).toList(),
                ),
                const SizedBox(height: 24.0),

                // KOMPONENTY NASTAVENÍ
                const TestSettingsWidget(),
                const SizedBox(height: 24.0),
                const TimeSettingsWidget(),
                const SizedBox(height: 48.0),

                // HLAVNÍ TLAČÍTKO PRO ODESLÁNÍ
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      print('Zadávám test: ${_testNameController.text} pro třídu: $targetClass');
                    },
                    icon: const Icon(Icons.send_rounded, size: 20),
                    label: Text(
                      'Zadat test', 
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.surface,
                      minimumSize: const Size(240, 56), // Velké, dominantní tlačítko
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 60), // Místo dole pro bezpečné scrollování
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Vstupní pole pro název testu
  Widget _buildTestNameInput() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Theme.of(context).colorScheme.outline, width: 1.0),
        boxShadow: [
          BoxShadow(
            blurRadius: 10.0,
            color: Colors.black.withValues(alpha: 0.02),
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: TextFormField(
        controller: _testNameController,
        focusNode: _testNameFocusNode,
        style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
        decoration: InputDecoration(
          hintText: 'Zadejte název testu...',
          hintStyle: GoogleFonts.inter(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.w400),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        ),
      ),
    );
  }

  // Rozbalovací panel
  Widget _buildExpandableSection({required String title, required String subtitle, required IconData icon, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Theme.of(context).colorScheme.outline, width: 1.0),
        boxShadow: [
          BoxShadow(
            blurRadius: 10.0,
            color: Colors.black.withValues(alpha: 0.02),
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent), // Skryje základní čáru
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          leading: Icon(icon, color: Theme.of(context).colorScheme.secondary),
          title: Text(
            title, 
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.secondary, letterSpacing: 1.1)
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: Theme.of(context).colorScheme.secondary)),
          ),
          childrenPadding: const EdgeInsets.all(16),
          expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}