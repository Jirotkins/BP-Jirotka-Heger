import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'bank_overview_provider.dart';
import '../../components/page_header_widget.dart';
import '../../components/add_new_bank_popup_widget.dart';
import '../../components/bank_card_widget.dart';

class BankOverviewPage extends ConsumerStatefulWidget {
  const BankOverviewPage({super.key});

  @override
  ConsumerState<BankOverviewPage> createState() => _BankOverviewPageState();
}

class _BankOverviewPageState extends ConsumerState<BankOverviewPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bankOverviewProvider.notifier).fetchBanks();
    });
  }

  Future<void> _deleteBank(int bankId, BankOverviewNotifier notifier) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Smazat banku?'),
        content: const Text('Opravdu chcete tuto banku otázek smazat? Přijdete o všechny otázky v ní uložené.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Zrušit')),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Smazat'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final error = await notifier.deleteBank(bankId);
      if (error == 'IN_USE') {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Nelze smazat banku'),
            content: const Text('Tuto banku nelze smazat, protože obsahuje otázky, které jsou aktuálně použity v některém z testů. Nejprve smažte příslušné otázky nebo je odeberte z testů.'),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Rozumím')),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bankOverviewProvider);
    final notifier = ref.read(bankOverviewProvider.notifier);

    ref.listen<BankOverviewState>(bankOverviewProvider, (previous, next) {
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
          title: 'Banky otázek',
          actions: [
            ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  barrierColor: Colors.black54,
                  builder: (dialogContext) => Dialog(
                    elevation: 0,
                    backgroundColor: Colors.transparent,
                    insetPadding: EdgeInsets.zero,
                    child: const AddNewBankPopupWidget(),
                  ),
                );
              },
              icon: const Icon(Icons.add_circle_outline, size: 18.0),
              label: Text(
                'Přidat novou banku',
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

        // --- SEKCE S KARTAMI ---
        Expanded(
          child: state.isLoading && state.banks.isEmpty
              ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
              : state.banks.isEmpty
                  ? Center(
                      child: Text(
                        'Zatím nemáte vytvořenou žádnou banku.\nKlikněte na tlačítko "Přidat novou banku" vpravo nahoře.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 16.0),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async => notifier.fetchBanks(),
                      child: GridView.builder(
                        padding: const EdgeInsets.all(32.0),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 400.0,
                          mainAxisExtent: 230.0,
                          crossAxisSpacing: 24.0,
                          mainAxisSpacing: 24.0,
                        ),
                        itemCount: state.banks.length,
                        itemBuilder: (context, index) {
                          final bank = state.banks[index];
                          return BankCardWidget(
                            id: bank['id'],
                            title: bank['title'],
                            subject: bank['subject'],
                            icon: Icon(bank['icon'] as IconData? ?? Icons.help_outline, color: Theme.of(context).colorScheme.primary, size: 28),
                            questionCount: bank['questionCount'],
                            onEdit: () {
                              showDialog(
                                context: context,
                                barrierColor: Colors.black54,
                                builder: (dialogContext) => Dialog(
                                  elevation: 0,
                                  backgroundColor: Colors.transparent,
                                  insetPadding: EdgeInsets.zero,
                                  child: AddNewBankPopupWidget(
                                    bankId: bank['id'],
                                    initialName: bank['title'],
                                    initialSubject: bank['subject'],
                                    initialIconIndex: bank['iconIndex'],
                                  ),
                                ),
                              );
                            },
                            onDelete: () => _deleteBank(bank['id'], notifier),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}