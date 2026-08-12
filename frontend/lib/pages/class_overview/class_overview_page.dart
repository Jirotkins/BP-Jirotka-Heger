import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'class_overview_provider.dart';
import '../../components/page_header_widget.dart';
import '../../components/add_new_class_popup_widget.dart';
import '../../components/class_card_widget.dart';

/// Úvodní obrazovka učitele (Moje třídy).
/// 
/// Zobrazuje přehled všech vytvořených tříd ve formě gridu (karet).
/// Umožňuje přidávat, upravovat a mazat třídy. Kliknutí na třídu vede do jejího detailu.
class ClassOverviewPage extends ConsumerStatefulWidget {
  /// Vytvoří instanci stránky s přehledem tříd.
  const ClassOverviewPage({super.key});

  @override
  ConsumerState<ClassOverviewPage> createState() => _ClassOverviewPageState();
}

/// Stav obrazovky [ClassOverviewPage] zajišťující načítání a operace se třídami.
class _ClassOverviewPageState extends ConsumerState<ClassOverviewPage> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(classOverviewProvider.notifier).fetchGroups();
    });
  }

  /// Zobrazí dialogové okno pro potvrzení smazání a následně smaže třídu.
  Future<void> _deleteGroup(int groupId, ClassOverviewNotifier notifier) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Smazat třídu?'),
        content: const Text('Opravdu chcete tuto třídu smazat? Smazáním přijdete o všechny přiřazené studenty a historii testů v této třídě.'),
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
      await notifier.deleteGroup(groupId);
    }
  }

  /// Zpracuje řetězec z databáze a pokusí se z něj extrahovat předmět a ikonu.
  /// 
  /// Pokud je [descriptionRaw] platný JSON, pokusí se z něj vyčíst `subject` a `icon`.
  /// V opačném případě vrací hrubý text jako předmět a výchozí ikonu knihy.
  ({String subject, IconData icon}) _parseGroupDescription(dynamic descriptionRaw) {
    String subject = 'Neznámý předmět';
    IconData displayIcon = Icons.menu_book_outlined;

    if (descriptionRaw == null) {
      return (subject: subject, icon: displayIcon);
    }

    final descString = descriptionRaw.toString().trim();
    if (descString.isEmpty) {
      return (subject: subject, icon: displayIcon);
    }

    try {
      if (descString.startsWith('{')) {
        final descMap = jsonDecode(descString);
        if (descMap['subject'] != null) {
          subject = descMap['subject'];
        }
        if (descMap['icon'] != null) {
          int codePoint = int.tryParse(descMap['icon'].toString()) ?? 0;
          if (codePoint != 0) {
            displayIcon = IconData(codePoint, fontFamily: 'MaterialIcons');
          }
        }
      } else {
        // Zpětná kompatibilita pro staré textové popisky bez JSON struktury
        subject = descString;
      }
    } catch (e) {
      debugPrint('Nelze rozparsovat JSON z description: $e');
    }

    return (subject: subject, icon: displayIcon);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(classOverviewProvider);
    final notifier = ref.read(classOverviewProvider.notifier);

    // Posluchač pro zobrazení případných chybových hlášek ze StateManageru
    ref.listen<ClassOverviewState>(classOverviewProvider, (previous, next) {
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
        // HLAVIČKA STRÁNKY
        PageHeaderWidget(
          title: 'Moje třídy',
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
                    child: const AddNewClassPopupWidget(),
                  ),
                );
              },
              icon: const Icon(Icons.add_circle_outline, size: 18.0),
              label: Text(
                'Přidat novou třídu',
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

        // SEZNAM KARET TŘÍD
        Expanded(
          child: state.isLoading && state.groups.isEmpty
              ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
              : state.groups.isEmpty
                  ? Center(
                      child: Text(
                        'Zatím nemáte vytvořenou žádnou třídu.\nKlikněte na tlačítko "Přidat novou třídu" vpravo nahoře.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 16.0),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async => notifier.fetchGroups(),
                      child: GridView.builder(
                        padding: const EdgeInsets.all(32.0),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 400.0,
                          mainAxisExtent: 230.0,
                          crossAxisSpacing: 24.0,
                          mainAxisSpacing: 24.0,
                        ),
                        itemCount: state.groups.length,
                        itemBuilder: (context, index) {
                          final g = state.groups[index];
                          final parsedData = _parseGroupDescription(g['description']);

                          return ClassCardWidget(
                            groupId: g['group_id'],
                            title: g['name'] ?? 'Neznámý název',
                            subject: parsedData.subject,
                            icon: Icon(parsedData.icon, color: Theme.of(context).colorScheme.primary, size: 28),
                            studentCount: g['student_count'] ?? 0,
                            activeTestCount: g['active_assignment_count'] ?? 0,
                            testsToControl: g['pending_grade_count'] ?? 0,
                            onEdit: () {
                              int iconIndex = AddNewClassPopupWidget.availableIcons.indexWhere((icon) => icon.codePoint == parsedData.icon.codePoint);
                              if (iconIndex == -1) iconIndex = 0;
                              
                              showDialog(
                                context: context,
                                barrierColor: Colors.black54,
                                builder: (dialogContext) => Dialog(
                                  elevation: 0,
                                  backgroundColor: Colors.transparent,
                                  insetPadding: EdgeInsets.zero,
                                  child: AddNewClassPopupWidget(
                                    groupId: g['group_id'],
                                    initialName: g['name'] ?? '',
                                    initialSubject: parsedData.subject,
                                    initialIconIndex: iconIndex,
                                  ),
                                ),
                              );
                            },
                            onDelete: () => _deleteGroup(g['group_id'], notifier),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}