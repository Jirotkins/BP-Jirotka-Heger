import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'class_overview_provider.dart';
import '../../components/page_header_widget.dart';
import '../../components/add_new_class_popup_widget.dart';
import '../../components/class_card_widget.dart';

class ClassOverviewPage extends ConsumerStatefulWidget {
  const ClassOverviewPage({super.key});

  @override
  ConsumerState<ClassOverviewPage> createState() => _ClassOverviewPageState();
}

class _ClassOverviewPageState extends ConsumerState<ClassOverviewPage> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(classOverviewProvider.notifier).fetchGroups();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(classOverviewProvider);
    final notifier = ref.read(classOverviewProvider.notifier);

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
        
        // --- HLAVIČKA ---
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

        // --- SEKCE S KARTAMI ---
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
                          mainAxisExtent: 210.0,
                          crossAxisSpacing: 24.0,
                          mainAxisSpacing: 24.0,
                        ),
                        itemCount: state.groups.length,
                        itemBuilder: (context, index) {
                          final g = state.groups[index];

                          // Pokus o rozparsování description jako JSON, kvůli uložení ikony a předmětu
                          String subject = 'Neznámý předmět';
                          IconData displayIcon = Icons.menu_book_outlined;

                          try {
                            if (g['description'] != null && g['description'].toString().startsWith('{')) {
                              final descMap = jsonDecode(g['description']);
                              if (descMap['subject'] != null) {
                                subject = descMap['subject'];
                              }
                              if (descMap['icon'] != null) {
                                int codePoint = int.tryParse(descMap['icon'].toString()) ?? 0;
                                if (codePoint != 0) {
                                  displayIcon = IconData(codePoint, fontFamily: 'MaterialIcons');
                                }
                              }
                            } else if (g['description'] != null && g['description'].toString().trim().isNotEmpty) {
                              subject = g['description'];
                            }
                          } catch (e) {
                            print('Nelze rozparsovat JSON z description: $e');
                          }

                          return ClassCardWidget(
                            groupId: g['group_id'],
                            title: g['name'] ?? 'Neznámý název',
                            subject: subject,
                            icon: Icon(displayIcon, color: Theme.of(context).colorScheme.primary, size: 28),
                            studentCount: g['student_count'] ?? 0,
                            activeTestCount: g['active_assignment_count'] ?? 0,
                            testsToControl: g['pending_grade_count'] ?? 0,
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}