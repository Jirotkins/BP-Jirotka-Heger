import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'questions_overview_provider.dart';
import '../../components/page_header_widget.dart';
import '../../components/question_row_widget.dart';

class QuestionsOverviewPage extends ConsumerStatefulWidget {
  final int bankId;
  final String bankName;

  const QuestionsOverviewPage({
    super.key,
    this.bankId = 0,
    this.bankName = 'Neznámá banka',
  });

  @override
  ConsumerState<QuestionsOverviewPage> createState() => _QuestionsOverviewPageState();
}

class _QuestionsOverviewPageState extends ConsumerState<QuestionsOverviewPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(questionsOverviewProvider.notifier).fetchQuestions(widget.bankId);
    });
  }

  Future<void> _deleteQuestion(int questionId, QuestionsOverviewNotifier notifier) async {
    // 1. Zobrazit potvrzovací dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Smazat otázku?'),
          content: const Text('Opravdu chcete tuto otázku smazat? Tuto akci nelze vrátit zpět.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Zrušit'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              child: const Text('Smazat'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      final error = await notifier.deleteQuestion(questionId);
      
      if (error == 'IN_USE') {
        if (!mounted) return;
        // Dialog pro vynucené smazání
        final bool? forceConfirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Otázka je použita v testu'),
            content: const Text('Tato otázka je již přiřazena v nějakém existujícím návrhu testu. Pokud ji smažete, bude z těchto testů odebrána. Opravdu ji chcete smazat?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Zrušit'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
                child: const Text('Přesto smazat'),
              ),
            ],
          ),
        );
        
        if (forceConfirm == true) {
          await notifier.deleteQuestion(questionId, force: true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(questionsOverviewProvider);
    final notifier = ref.read(questionsOverviewProvider.notifier);

    ref.listen<QuestionsOverviewState>(questionsOverviewProvider, (previous, next) {
      if (next.errorMessage != null && next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        notifier.clearError();
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // --- HLAVIČKA ---
        PageHeaderWidget(
          title: 'Úprava banky – ${widget.bankName}',
          showBackButton: true,
          actions: [
            ElevatedButton.icon(
              onPressed: () {
                context.push('/addNewQuestion', extra: {
                  'targetName': widget.bankName,
                  'bankName': widget.bankName,
                  'bankId': widget.bankId,
                });
              },
              icon: const Icon(Icons.add_circle_outline, size: 18.0),
              label: Text(
                'Přidat novou otázku',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.surface,
                minimumSize: const Size(0, 40),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
              ),
            ),
          ],
        ),

        // --- OBSAH (SEZNAM OTÁZEK) ---
        Expanded(
          child: state.isLoading && state.questions.isEmpty
              ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
              : state.questions.isEmpty
                  ? Center(
                      child: Text(
                        'Tato banka zatím neobsahuje žádné otázky.\nKlikněte na tlačítko "Přidat novou otázku" vpravo nahoře.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 16.0),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async => notifier.fetchQuestions(widget.bankId),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(32.0),
                        itemCount: state.questions.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12.0),
                        itemBuilder: (context, index) {
                          final q = state.questions[index];
                          return QuestionRowWidget(
                            id: q['id'] as int,
                            question: q['question'] as String,
                            type: q['type'] as String,
                            bankId: widget.bankId,
                            targetName: widget.bankName,
                            questionData: q['raw'],
                            onDelete: () => _deleteQuestion(q['id'] as int, notifier),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }



  String _getTypeLabel(String rawType) {
    switch (rawType) {
      case 'SINGLE_CHOICE':
      case 'MULTI_CHOICE':
        return 'Výběr možností';
      case 'OPEN_TEXT':
        return 'Otevřená otázka';
      case 'ORDERING':
        return 'Seřazování';
      default:
        return 'Neznámý typ ($rawType)';
    }
  }
}