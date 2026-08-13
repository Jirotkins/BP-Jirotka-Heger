import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'class_manager_provider.dart';
import '../../components/active_test_card_widget.dart';
import '../../components/control_test_card_widget.dart';
import '../../components/page_header_widget.dart';
import '../../components/add_new_students_popup_widget.dart';
import '../../components/student_row_widget.dart';

/// Hlavní stránka pro správu konkrétní třídy (Class Manager).
/// 
/// Zobrazuje rozbalitelný seznam studentů patřících do třídy,
/// a také přehled všech testů (aktivní, naplánované a ukončené ke kontrole).
/// Umožňuje přidávání nových studentů, spouštění naplánovaných testů
/// a navigaci do editoru testů nebo vyhodnocení.
class ClassManagerPage extends ConsumerStatefulWidget {
  const ClassManagerPage({super.key});

  @override
  ConsumerState<ClassManagerPage> createState() => _ClassManagerPageState();
}

/// Stav stránky správy třídy řídící načítání dat podle ID z url (go_router extra parametrů).
class _ClassManagerPageState extends ConsumerState<ClassManagerPage> {
  int? _lastGroupId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = GoRouterState.of(context).extra as Map<String, dynamic>?;
    final groupId = args?['groupId'] as int?;
    
    if (groupId != null && groupId != _lastGroupId) {
      _lastGroupId = groupId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(classManagerProvider.notifier).fetchData(groupId);
      });
    } else if (groupId == null && _lastGroupId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(classManagerProvider.notifier).setGroupMissingError();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(classManagerProvider);
    final notifier = ref.read(classManagerProvider.notifier);
    
    final args = GoRouterState.of(context).extra as Map<String, dynamic>?;
    final String className = args?['className'] ?? 'Neznámá třída';

    // Ošetření zobrazení chyb přes SnackBar, aby UI nezůstalo zamrzlé v chybě napořád
    ref.listen<ClassManagerState>(classManagerProvider, (previous, next) {
      if (next.errorMessage != null && next.errorMessage != previous?.errorMessage) {
        if (next.errorMessage != 'Nebylo zadáno ID třídy (groupId).') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.errorMessage!),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
        notifier.clearError();
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeaderWidget(
          title: className,
          showBackButton: true,
          actions: [
            ElevatedButton.icon(
              onPressed: () {
                if (_lastGroupId != null) {
                  showDialog(
                    context: context,
                    barrierColor: Colors.black54,
                    builder: (dialogContext) => Dialog(
                      elevation: 0,
                      backgroundColor: Colors.transparent,
                      insetPadding: EdgeInsets.zero,
                      child: AddNewStudentsPopupWidget(
                        groupId: _lastGroupId!,
                        onSuccess: () => notifier.refresh(),
                      ),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: Text('Přidat studenty', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.surface,
                minimumSize: const Size(0, 40),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
              ),
            ),
            const SizedBox(width: 12.0),
            ElevatedButton.icon(
              onPressed: () async {
                await context.push('/testEditor', extra: {'targetName': className, 'groupId': _lastGroupId});
                if (_lastGroupId != null) {
                  notifier.refresh();
                }
              },
              icon: const Icon(Icons.post_add, size: 18),
              label: Text('Vytvořit test', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.surface,
                minimumSize: const Size(0, 40),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
              ),
            ),
          ],
        ),
        
        Expanded(
          child: state.isLoading 
              ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
              : (state.errorMessage != null && state.errorMessage == 'Nebylo zadáno ID třídy (groupId).')
                  ? Center(child: Text(state.errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)))
                  : _buildContent(state, notifier),
        ),
      ],
    );
  }

  /// Pomocná metoda pro formátování ISO data do čitelné podoby.
  String _formatDate(String? isoDate) {
    if (isoDate == null) return 'Neurčito';
    try {
      final date = DateTime.parse(isoDate.endsWith('Z') ? isoDate : '${isoDate}Z').toLocal();
      return DateFormat('dd. MM. yyyy HH:mm').format(date);
    } catch (e) {
      return isoDate;
    }
  }

  /// Zobrazí potvrzovací dialog před manuální aktivací (spuštěním) naplánovaného testu.
  void _showActivateDialog(int assignmentId, ClassManagerNotifier notifier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Spustit test?', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text('Přejete si tento test ručně zpřístupnit studentům ihned?', style: GoogleFonts.inter()),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Zrušit', style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              notifier.activateTest(assignmentId);
            },
            child: const Text('Spustit nyní'),
          ),
        ],
      ),
    );
  }

  /// Zobrazí dialogové okno pro potvrzení a následně odebere studenta ze třídy.
  Future<void> _removeStudent(int studentId, String studentEmail, ClassManagerNotifier notifier) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Odebrat studenta?'),
        content: Text('Opravdu chcete odebrat studenta $studentEmail z této třídy?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Zrušit')),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Odebrat'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await notifier.removeStudent(studentId);
    }
  }

  /// Sestaví hlavní tělo obsahu – rozbalovací seznam studentů a sekce s kartami testů.
  Widget _buildContent(ClassManagerState state, ClassManagerNotifier notifier) {
    final activeTests = (state.overviewData?['active'] as List?) ?? [];
    final upcomingTests = (state.overviewData?['upcoming'] as List?) ?? [];
    final finishedTests = (state.overviewData?['finished'] as List?) ?? [];
    final gradedTests = ((state.overviewData?['graded'] as List?) ?? []).reversed.toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SEZNAM STUDENTŮ (ExpansionTile)
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: Theme.of(context).colorScheme.outline, width: 1.0), 
              boxShadow: [
                BoxShadow(blurRadius: 10.0, color: Colors.black.withValues(alpha: 0.02), offset: const Offset(0, 4))
              ],
            ),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                title: Row(
                  children: [
                    Icon(Icons.people_outline, color: Theme.of(context).colorScheme.secondary, size: 20),
                    const SizedBox(width: 12),
                    Text('STUDENTI', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.secondary, letterSpacing: 1.1)),
                    const SizedBox(width: 12),
                    Container(
                      width: 24, height: 24,
                      decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Text(state.studentsData.length.toString(), style: GoogleFonts.inter(color: Theme.of(context).colorScheme.surface, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6.0, left: 32.0),
                  child: Text('Rozklikněte pro rozbalení seznamu studentů', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.secondary, fontSize: 12)),
                ),
                children: [
                  if (state.studentsData.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('Zatím nejsou přidáni žádní studenti.', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.secondary)),
                    )
                  else
                    Column(
                      children: state.studentsData.asMap().entries.map((entry) {
                        final index = entry.key;
                        final student = entry.value;
                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4.0),
                              child: StudentRowWidget(
                                id: student['student_id'] ?? 0,
                                studentName: student['email'] ?? 'Neznámý student',
                                onDelete: () => _removeStudent(
                                  student['student_id'] ?? 0,
                                  student['email'] ?? 'Neznámý student',
                                  notifier,
                                ),
                              ),
                            ),
                            if (index < state.studentsData.length - 1)
                              Divider(height: 1, color: Theme.of(context).colorScheme.outline, indent: 20, endIndent: 20),
                          ],
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24.0),

          _buildTestSection(
            context: context,
            title: 'AKTIVNÍ TESTY',
            badgeColor: Theme.of(context).colorScheme.error,
            iconData: Icons.play_circle_outline,
            tests: activeTests,
            initiallyExpanded: true,
            itemBuilder: (test) => ActiveTestCard(
              title: test['template_name'] ?? 'Neznámý test',
              subtitle: 'Spuštěno do: ${_formatDate(test['activate_to'] as String?)}',
              submittedCount: test['submitted_count'] ?? 0,
              totalStudents: test['total_students'] ?? 0,
              onTap: () async {
                await context.push('/testAttempts', extra: {
                  'assignmentId': test['assignment_id'] ?? 999,
                  'testTitle': test['template_name'] ?? 'Neznámý test'
                });
                notifier.refresh();
              },
            ),
          ),

          _buildTestSection(
            context: context,
            title: 'PŘIPRAVENÉ A NAPLÁNOVANÉ',
            badgeColor: Theme.of(context).colorScheme.tertiary,
            iconData: Icons.schedule,
            tests: upcomingTests,
            initiallyExpanded: true,
            itemBuilder: (test) => ActiveTestCard( 
              title: test['template_name'] ?? 'Neznámý test',
              subtitle: test['activate_from'] != null 
                ? (test['activate_to'] != null 
                    ? 'Termín: ${_formatDate(test['activate_from'] as String?)} – ${_formatDate(test['activate_to'] as String?)}' 
                    : 'Naplánováno na: ${_formatDate(test['activate_from'] as String?)}') 
                : 'Čeká na manuální spuštění',
              submittedCount: test['submitted_count'] ?? 0,
              totalStudents: test['total_students'] ?? 0,
              isScheduled: true,
              onTap: () => _showActivateDialog(test['assignment_id'], notifier),
            ),
          ),

          _buildTestSection(
            context: context,
            title: 'KE KONTROLE',
            badgeColor: Theme.of(context).colorScheme.primary,
            iconData: Icons.fact_check_outlined,
            tests: finishedTests,
            initiallyExpanded: true,
            itemBuilder: (test) => ControlTestCard(
              title: test['template_name'] ?? 'Neznámý test',
              subtitle: '${test['submitted_count'] ?? 0}/${test['total_students'] ?? 0} odevzdalo',
              onTap: () async {
                await context.push('/testAttempts', extra: {
                  'assignmentId': test['assignment_id'] ?? 999,
                  'testTitle': test['template_name'] ?? 'Neznámý test'
                });
                notifier.refresh();
              },
            ),
          ),

          _buildTestSection(
            context: context,
            title: 'OHODNOCENO',
            badgeColor: Theme.of(context).colorScheme.secondary,
            iconData: Icons.done_all,
            tests: gradedTests,
            initiallyExpanded: false,
            itemBuilder: (test) => ControlTestCard(
              title: test['template_name'] ?? 'Neznámý test',
              subtitle: '${test['submitted_count'] ?? 0}/${test['total_students'] ?? 0} odevzdalo (Hodnocení dokončeno)',
              onTap: () async {
                await context.push('/testAttempts', extra: {
                  'assignmentId': test['assignment_id'] ?? 999,
                  'testTitle': test['template_name'] ?? 'Neznámý test'
                });
                notifier.refresh();
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Pomocná metoda pro vykreslení rozbalovací sekce s testy
  Widget _buildTestSection({
    required BuildContext context,
    required String title,
    required Color badgeColor,
    required IconData iconData,
    required List<dynamic> tests,
    required bool initiallyExpanded,
    required Widget Function(dynamic) itemBuilder,
  }) {
    if (tests.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: Theme.of(context).colorScheme.outline, width: 1.0), 
          boxShadow: [
            BoxShadow(blurRadius: 10.0, color: Colors.black.withValues(alpha: 0.02), offset: const Offset(0, 4))
          ],
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: initiallyExpanded,
            tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            title: Row(
              children: [
                Icon(iconData, color: badgeColor, size: 20),
                const SizedBox(width: 12),
                Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: badgeColor, letterSpacing: 1.1)),
                const SizedBox(width: 12),
                Container(
                  width: 24, height: 24,
                  decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text(tests.length.toString(), style: GoogleFonts.inter(color: Theme.of(context).colorScheme.surface, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  children: tests.map((test) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: itemBuilder(test),
                  )).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}