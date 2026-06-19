import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/api_client.dart';
import '../test_evaluation/test_evaluation_widget.dart';
import '../../components/active_test_card_widget.dart';
import '../../components/control_test_card_widget.dart';
import '../../components/page_header_widget.dart';
import '../../components/add_new_students_popup_widget.dart';
import '../../components/student_row_widget.dart';

class ClassManagerWidget extends ConsumerStatefulWidget {
  const ClassManagerWidget({super.key});

  @override
  ConsumerState<ClassManagerWidget> createState() => _ClassManagerWidgetState();
}

class _ClassManagerWidgetState extends ConsumerState<ClassManagerWidget> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _overviewData;
  List<dynamic> _studentsData = [];
  int? _lastGroupId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = GoRouterState.of(context).extra as Map<String, dynamic>?;
    final groupId = args?['groupId'] as int?;
    
    if (groupId != null && groupId != _lastGroupId) {
      _lastGroupId = groupId;
      _fetchData(groupId);
    } else if (groupId == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Nebylo zadáno ID třídy (groupId).';
      });
    }
  }

  Future<void> _fetchData(int groupId) async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      try {
        final apiClient = ref.read(apiClientProvider);
        // Spustíme oba požadavky paralelně
        final results = await Future.wait([
          apiClient.get('/groups/$groupId/exam-assignments/overview'),
          apiClient.get('/groups/$groupId/students'),
        ]);
        
        setState(() {
          _overviewData = results[0];
          _studentsData = (results[1] as Map<String, dynamic>)['students'] as List<dynamic>? ?? [];
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final args = GoRouterState.of(context).extra as Map<String, dynamic>?;
    final String className = args?['className'] ?? 'Neznámá třída';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeaderWidget(
          title: className,
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
                        onSuccess: () => _fetchData(_lastGroupId!),
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
                  _fetchData(_lastGroupId!);
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
          child: _isLoading 
              ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
              : _errorMessage != null
                  ? Center(child: Text(_errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)))
                  : _buildContent(),
        ),
      ],
    );
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return 'Neurčito';
    try {
      final date = DateTime.parse(isoDate).toLocal();
      return DateFormat('dd. MM. yyyy HH:mm').format(date);
    } catch (e) {
      return isoDate;
    }
  }

  void _showActivateDialog(int assignmentId) {
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
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              try {
                await ref.read(apiClientProvider).post('/exam-assignments/$assignmentId/activate', {});
                if (_lastGroupId != null) _fetchData(_lastGroupId!);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Chyba: $e'), backgroundColor: Colors.red));
                }
                setState(() => _isLoading = false);
              }
            },
            child: const Text('Spustit nyní'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final activeTests = (_overviewData?['active'] as List?) ?? [];
    final upcomingTests = (_overviewData?['upcoming'] as List?) ?? [];
    final finishedTests = (_overviewData?['finished'] as List?) ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ROZBALOVACÍ PANEL STUDENTŮ
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
                      child: Text(_studentsData.length.toString(), style: GoogleFonts.inter(color: Theme.of(context).colorScheme.surface, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6.0, left: 32.0),
                  child: Text('Rozklikněte pro rozbalení seznamu studentů', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.secondary, fontSize: 12)),
                ),
                children: [
                  if (_studentsData.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('Zatím nejsou přidáni žádní studenti.', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.secondary)),
                    )
                  else
                    Column(
                      children: _studentsData.asMap().entries.map((entry) {
                        final index = entry.key;
                        final student = entry.value;
                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4.0),
                              child: StudentRowWidget(
                                id: student['student_id'] ?? 0,
                                studentName: student['email'] ?? 'Neznámý student',
                              ),
                            ),
                            if (index < _studentsData.length - 1)
                              Divider(height: 1, color: Theme.of(context).colorScheme.outline, indent: 20, endIndent: 20),
                          ],
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ),

          if (activeTests.isNotEmpty) ...[
            const SizedBox(height: 48.0),
            _buildSectionHeader(context, 'Aktivní testy', Theme.of(context).colorScheme.error, activeTests.length.toString()), 
            const SizedBox(height: 16.0),
            ...activeTests.map((test) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: ActiveTestCard(
                  title: test['template_name'] ?? 'Neznámý test',
                  subtitle: 'Spuštěno do: ${_formatDate(test['activate_to'] as String?)}',
                  submittedCount: test['submitted_count'] ?? 0,
                  totalStudents: test['total_students'] ?? 0,
                  onTap: () => print('Otevřít aktivní test'),
                ),
              );
            }).toList(),
          ],

          if (upcomingTests.isNotEmpty) ...[
            const SizedBox(height: 48.0),
            _buildSectionHeader(context, 'Připravené a naplánované testy', Theme.of(context).colorScheme.tertiary ?? Colors.orange, upcomingTests.length.toString()), 
            const SizedBox(height: 16.0),
            ...upcomingTests.map((test) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: ActiveTestCard( // Můžeme zatím použít ActiveTestCard nebo vytvořit novou
                  title: test['template_name'] ?? 'Neznámý test',
                  subtitle: test['activate_from'] != null ? 'Naplánováno na: ${_formatDate(test['activate_from'] as String?)}' : 'Čeká na manuální spuštění',
                  submittedCount: test['submitted_count'] ?? 0,
                  totalStudents: test['total_students'] ?? 0,
                  onTap: () => _showActivateDialog(test['assignment_id']),
                ),
              );
            }).toList(),
          ],

          if (finishedTests.isNotEmpty) ...[
            const SizedBox(height: 48.0),
            _buildSectionHeader(context, 'Testy ke kontrole', Theme.of(context).colorScheme.primary, finishedTests.length.toString()), 
            const SizedBox(height: 16.0),
            ...finishedTests.map((test) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: ControlTestCard(
                  title: test['template_name'] ?? 'Neznámý test',
                  subtitle: '${test['submitted_count'] ?? 0}/${test['total_students'] ?? 0} odevzdalo',
                  onTap: () {
                    context.push('/testEvaluation');
                  },
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, Color badgeColor, String count) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(width: 4, height: 20, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 12),
        Text(title, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
        const Spacer(),
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(count, style: GoogleFonts.inter(color: Theme.of(context).colorScheme.surface, fontSize: 13, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}