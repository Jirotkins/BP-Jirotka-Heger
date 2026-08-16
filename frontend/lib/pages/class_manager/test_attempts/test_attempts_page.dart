import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'test_attempts_provider.dart';
import '../../../components/page_header_widget.dart';

/// Stránka zobrazující seznam odevzdání (pokusů) konkrétního testu pro celou třídu.
/// 
/// Poskytuje přehled o všech studentech, kteří test odevzdali, s informací o jejich
/// dosaženém skóre (bodech) a aktuálním stavu (např. automaticky oznámkováno vs. ke kontrole).
/// Kliknutím na vybraný pokus je učitel přesměrován do manuálního hodnocení daného testu.
class TestAttemptsPage extends ConsumerStatefulWidget {
  /// ID konkrétního zadání testu (assignment), pro které chceme načíst pokusy.
  final int assignmentId;
  
  /// Název testu zobrazovaný v hlavičce stránky.
  final String testTitle;

  const TestAttemptsPage({
    super.key,
    required this.assignmentId,
    this.testTitle = 'Seznam odevzdání',
  });

  @override
  ConsumerState<TestAttemptsPage> createState() => _TestAttemptsPageState();
}

/// Stav řídící načítání dat pro [TestAttemptsPage].
class _TestAttemptsPageState extends ConsumerState<TestAttemptsPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(testAttemptsProvider.notifier).fetchAttempts(widget.assignmentId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(testAttemptsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeaderWidget(
            title: widget.testTitle,
            showBackButton: true,
            actions: [
              Tooltip(
                message: 'Data se aktualizují živě',
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.errorMessage != null
                    ? Center(child: Text(state.errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)))
                    : _buildBody(context, state),
          ),
        ],
      ),
    );
  }

  /// Pomocná metoda pro vykreslení hlavního seznamu odevzdání a živých statistik.
  Widget _buildBody(BuildContext context, TestAttemptsState state) {
    if (state.attempts.isEmpty && state.liveStats.isEmpty) {
      return Center(
        child: Text('Zatím nejsou žádná odevzdání ani aktivní pokusy.', style: GoogleFonts.inter(fontSize: 16)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.liveStats.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(left: 24.0, top: 24.0, right: 24.0),
            child: Text('Živý přehled otázek', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              itemCount: state.liveStats.length,
              itemBuilder: (context, index) {
                final stat = state.liveStats[index];
                final int answered = stat['answeredCount'] ?? 0;
                final int total = stat['totalCount'] ?? 1;
                final double progress = total > 0 ? answered / total : 0;
                
                return Container(
                  width: 200,
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Otázka ${stat['index']}', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                      const SizedBox(height: 8),
                      Text(stat['questionText'], maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Odpovědělo:', style: GoogleFonts.inter(fontSize: 12)),
                          Text('$answered / $total', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
        ],
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(24.0),
      itemCount: state.attempts.length,
      itemBuilder: (context, index) {
        final attempt = state.attempts[index];
        final isStarted = attempt['status'] == 'STARTED';
        final isGraded = attempt['status'] == 'GRADED';
        final isSubmitted = attempt['status'] == 'SUBMITTED';

        Color statusColor = Theme.of(context).colorScheme.outline;
        if (isGraded) statusColor = const Color(0xFF16A34A);
        if (isSubmitted) statusColor = const Color(0xFFD97706);

        return Card(
          margin: const EdgeInsets.only(bottom: 12.0),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            title: Text(
              attempt['student_name'],
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(attempt['submitted_at'], style: GoogleFonts.inter(fontSize: 13)),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      attempt['statusText'],
                      style: GoogleFonts.inter(fontSize: 12, color: statusColor, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (attempt['attemptCountLabel'] != null)
                    Text(
                      attempt['attemptCountLabel'],
                      style: GoogleFonts.inter(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                ],
              ),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(attempt['score'], style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(attempt['points'], style: GoogleFonts.inter(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
            onTap: isStarted ? () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Nelze hodnotit – student test ještě neodevzdal.'),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            } : () {
              context.push('/testEvaluation', extra: {
                'assignmentId': widget.assignmentId,
                'attemptId': attempt['attempt_id'],
                'isStudent': false,
              });
            },
          ),
        );
      },
    ),
        ),
      ],
    );
  }
}
