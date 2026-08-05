import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'test_attempts_provider.dart';

class TestAttemptsPage extends ConsumerStatefulWidget {
  final int assignmentId;
  final String testTitle;

  const TestAttemptsPage({
    super.key,
    required this.assignmentId,
    this.testTitle = 'Seznam odevzdání',
  });

  @override
  ConsumerState<TestAttemptsPage> createState() => _TestAttemptsPageState();
}

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
      appBar: AppBar(
        title: Text(widget.testTitle, style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.errorMessage != null
              ? Center(child: Text(state.errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)))
              : _buildBody(context, state),
    );
  }

  Widget _buildBody(BuildContext context, TestAttemptsState state) {
    if (state.attempts.isEmpty) {
      return Center(
        child: Text('Zatím nejsou žádná odevzdání.', style: GoogleFonts.inter(fontSize: 16)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24.0),
      itemCount: state.attempts.length,
      itemBuilder: (context, index) {
        final attempt = state.attempts[index];
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
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      attempt['statusText'],
                      style: GoogleFonts.inter(fontSize: 12, color: statusColor, fontWeight: FontWeight.w600),
                    ),
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
            onTap: () {
              context.push('/testEvaluation', extra: {
                'assignmentId': widget.assignmentId,
                'attemptId': attempt['attempt_id'],
                'isStudent': false,
              });
            },
          ),
        );
      },
    );
  }
}
