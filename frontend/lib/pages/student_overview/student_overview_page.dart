import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'student_overview_provider.dart';
import '../../components/subject_card_widget.dart';

// Úvodní domovská obrazovka studenta (Dashboard).
// Slouží jako rozcestník pro probíhající testy a přehled zapsaných předmětů.
class StudentOverviewPage extends ConsumerStatefulWidget {
  const StudentOverviewPage({super.key});

  @override
  ConsumerState<StudentOverviewPage> createState() => _StudentOverviewPageState();
}

class _StudentOverviewPageState extends ConsumerState<StudentOverviewPage> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(studentOverviewProvider.notifier).fetchDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(studentOverviewProvider);
    
    // Filtrujeme pouze skutečně aktivní testy (začaté, nebo dostupné)
    final now = DateTime.now();
    final trulyActiveTests = state.activeTests.where((test) {
      final String? activateTo = test['rawActivateTo'];
      final String? activateFrom = test['rawActivateFrom'];
      
      if (activateFrom != null) {
        final fromDate = DateTime.parse(activateFrom.endsWith('Z') ? activateFrom : '${activateFrom}Z').toLocal();
        if (now.isBefore(fromDate)) return false;
      }
      if (activateTo != null) {
        final toDate = DateTime.parse(activateTo.endsWith('Z') ? activateTo : '${activateTo}Z').toLocal();
        if (now.isAfter(toDate)) return false;
      }

      if (test['status'] == 'STARTED') return true;
      if (test['status'] != null) return false; // Odevzdané nebo ohodnocené nepatří do aktivních
      
      return true;
    }).toList();

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      
      // --- HLAVIČKA APLIKACE (AppBar) ---
      appBar: AppBar(
        // Nastavení pro čistě bílou barvu nezávislou na scrollování (Material 3)
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor ?? Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0, 
        automaticallyImplyLeading: false,
        elevation: 0, 
        toolbarHeight: 80, 
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Jakub Novák', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface, fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text('Přehled studia', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.secondary, fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
      
      // --- TĚLO STRÁNKY ---
      body: state.isLoading 
        ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
        : SafeArea(
            child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (state.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.errorContainer, borderRadius: BorderRadius.circular(8)),
                  child: Text(state.errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer, fontSize: 13)),
                ),
                const SizedBox(height: 16.0),
              ],

              // 1. SEKCE: AKTIVNÍ TESTY (Prioritní, vyžadují akci)
              if (trulyActiveTests.isNotEmpty) ...[
                _buildSectionHeader('Aktivní testy', trulyActiveTests.length, Theme.of(context).colorScheme.error),
                const SizedBox(height: 16),
                // Vykreslí všechny probíhající testy jako velké červené karty
                ...trulyActiveTests.map((test) => _buildActiveTestCard(test)),
                const SizedBox(height: 32),
              ],

              // 2. SEKCE: MOJE PŘEDMĚTY
              _buildSectionHeader('Moje předměty', null, null),
              const SizedBox(height: 16),
              
              // Mapování pole předmětů z API na naši univerzální komponentu
              ...state.mySubjects.map((sub) => SubjectCardWidget(
                id: sub['id'].toString(),
                code: sub['code']?.toString() ?? '',
                name: sub['name']?.toString() ?? '',
                teacher: sub['teacher']?.toString() ?? '',
                color: sub['color'] as Color? ?? Colors.blue,
                testCount: (sub['testCount'] as int?) ?? 0,
                status: sub['status']?.toString() ?? '',
                timeText: sub['timeText']?.toString() ?? '',
              )),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // POMOCNÉ WIDGETY
  // ============================================================================

  // Univerzální hlavička sekce (např. "Aktivní testy"), volitelně s počtem v bublině
  Widget _buildSectionHeader(String title, int? count, Color? countColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
        if (count != null && count > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: countColor ?? Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(12)),
            child: Text(count.toString(), style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onError, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
      ],
    );
  }

  // Výrazná červená karta pro test, který se musí okamžitě řešit.
  // Po kliknutí na tlačítko naviguje rovnou do vyplňování testu.
  Widget _buildActiveTestCard(Map<String, dynamic> test) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Theme.of(context).colorScheme.error.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [BoxShadow(color: Theme.of(context).shadowColor.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          // Levá ikona
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.errorContainer, borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.quiz_outlined, color: Theme.of(context).colorScheme.error, size: 24),
          ),
          const SizedBox(width: 16),
          // Informace o testu
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Probíhá', style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                const SizedBox(height: 2),
                Text(test['title'] ?? '', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.onSurface)),
                const SizedBox(height: 2),
                Text('Dostupný do: ${test['deadline']}', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.secondary, fontSize: 12)),
              ],
            ),
          ),
          // Odpočet a spouštěcí tlačítko
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Icon(Icons.schedule, color: Theme.of(context).colorScheme.error, size: 14),
                  const SizedBox(width: 4),
                  Text(test['expiresIn'] ?? '', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.error, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  // Otevře ostrý test a předá do něj ID přiřazení (assignmentId), aby si TestActiveWidget
                  // mohl z API (GET /exam-assignments/{assignmentId}/take) načíst příslušné otázky.
                  context.push('/testActive', extra: {'assignmentId': test['id'], 'testTitle': test['title']});
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                  elevation: 0,
                  minimumSize: const Size(80, 36),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: Text('Spustit', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}