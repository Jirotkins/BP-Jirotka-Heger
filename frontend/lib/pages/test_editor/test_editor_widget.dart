import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../components/page_header_widget.dart';
import '../../components/question_select_row_widget.dart';
import '../../components/test_settings_widget.dart';
import '../../components/time_settings_widget.dart';
import '../../theme/app_themes.dart';
import 'test_editor_provider.dart';

class TestEditorWidget extends ConsumerStatefulWidget {
  const TestEditorWidget({super.key});

  @override
  ConsumerState<TestEditorWidget> createState() => _TestEditorWidgetState();
}

class _TestEditorWidgetState extends ConsumerState<TestEditorWidget> {
  late TextEditingController _testNameController;
  late FocusNode _testNameFocusNode;

  @override
  void initState() {
    super.initState();
    _testNameController = TextEditingController();
    _testNameFocusNode = FocusNode();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(testEditorProvider.notifier).fetchBanks();
    });
  }

  @override
  void dispose() {
    _testNameController.dispose();
    _testNameFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(testEditorProvider);
    final notifier = ref.read(testEditorProvider.notifier);

    final args = GoRouterState.of(context).extra as Map<String, dynamic>?;
    final String targetClass = args?['targetName'] ?? 'Neznámá třída';
    final int groupId = args?['groupId'] ?? 0;

    // Listen for side effects (errors, success navigation)
    ref.listen<TestEditorState>(testEditorProvider, (previous, next) {
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
        final customColors = Theme.of(context).extension<CustomColors>();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Test byl úspěšně zadán!'),
            backgroundColor: customColors?.greenBg ?? Colors.green,
          ),
        );
        context.pop(true);
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeaderWidget(
          title: 'Nový test — $targetClass',
          actions: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Vybráno: ${state.selectedQuestionIds.length}',
                style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
              ),
            )
          ],
        ),
        Expanded(
          child: state.isLoadingBanks 
            ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTestNameInput(),
                    const SizedBox(height: 24.0),

                    Text('VÝBĚR OTÁZEK Z BANEK', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.secondary, letterSpacing: 1.1)),
                    const SizedBox(height: 8.0),
                    ...state.banks.map((bank) => _buildBankExpansionTile(bank, state, notifier)).toList(),
                    if (state.banks.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Text('Zatím nemáte vytvořené žádné banky.', style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
                      ),

                    const SizedBox(height: 24.0),
                    TestSettingsWidget(onChanged: (settings) => notifier.updateTestSettings(settings)),
                    const SizedBox(height: 24.0),
                    TimeSettingsWidget(onChanged: (settings) => notifier.updateTimeSettings(settings)),
                    const SizedBox(height: 48.0),

                    Center(
                      child: ElevatedButton.icon(
                        onPressed: state.isSubmitting || groupId == 0 
                          ? null 
                          : () => notifier.submitTest(groupId, _testNameController.text),
                        icon: state.isSubmitting 
                          ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Theme.of(context).colorScheme.onPrimary, strokeWidth: 2))
                          : const Icon(Icons.send_rounded, size: 20),
                        label: Text('Zadat test', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.surface,
                          minimumSize: const Size(240, 56),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
        ),
      ],
    );
  }

  Widget _buildBankExpansionTile(Map<String, dynamic> bank, TestEditorState state, TestEditorNotifier notifier) {
    int bankId = bank['id'];
    bool isLoading = state.bankQuestionsLoading[bankId] == true;
    List<Map<String, dynamic>>? questions = state.bankQuestionsCache[bankId];

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Theme.of(context).colorScheme.outline, width: 1.0),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: Icon(Icons.folder_open_rounded, color: Theme.of(context).colorScheme.primary),
          title: Text(bank['name'], style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
          onExpansionChanged: (expanded) {
            if (expanded) {
              notifier.fetchQuestionsForBank(bankId);
            }
          },
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          children: [
            if (isLoading)
              const Padding(padding: EdgeInsets.all(16.0), child: Center(child: CircularProgressIndicator()))
            else if (questions == null || questions.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0), 
                child: Text('Tato banka neobsahuje žádné otázky.', style: TextStyle(color: Theme.of(context).colorScheme.secondary))
              )
            else
              ...questions.map((q) {
                int qId = q['id'];
                bool isSelected = state.selectedQuestionIds.contains(qId);
                return QuestionSelectRowWidget(
                  question: q['question'],
                  type: q['type'],
                  isSelected: isSelected,
                  onToggle: () => notifier.toggleQuestionSelection(qId),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTestNameInput() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Theme.of(context).colorScheme.outline, width: 1.0),
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
}