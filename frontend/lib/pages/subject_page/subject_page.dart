import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_themes.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../student_overview/student_overview_provider.dart';

/// Stránka s detailem konkrétního předmětu z pohledu studenta.
/// 
/// Zobrazuje rozdělení testů pro daný předmět do tří kategorií:
/// 1. Právě probíhající (aktivní) testy
/// 2. Nadcházející testy (ještě nezačaly)
/// 3. Historie testů (odevzdané nebo ohodnocené)
class SubjectPage extends ConsumerStatefulWidget {
  const SubjectPage({super.key});

  @override
  ConsumerState<SubjectPage> createState() => _SubjectPageState();
}

class _SubjectPageState extends ConsumerState<SubjectPage> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  bool _showAllHistory = false;

  @override
  Widget build(BuildContext context) {
    // Načtení argumentů předaných přes navigaci (např. z domovské stránky)
    final args = GoRouterState.of(context).extra as Map<String, dynamic>?;
    final String subjectName = args?['subjectName'] ?? 'Předmět';
    final String subjectId = args?['subjectId']?.toString() ?? '';

    final overviewState = ref.watch(studentOverviewProvider);
    final subjectAssignments = overviewState.activeTests.where((test) => test['groupId'] == subjectId).toList();

    Map<String, dynamic>? activeTest;
    List<Map<String, dynamic>> upcomingTests = [];
    List<Map<String, dynamic>> pastTests = [];

    final now = DateTime.now();

    for (var test in subjectAssignments) {
      final status = test['status'];
      
      bool isScheduledFuture = false;
      bool isExpired = false;
      final String? activateFrom = test['rawActivateFrom'];
      final String? activateTo = test['rawActivateTo'];
      
      if (activateFrom != null) {
        final fromDate = DateTime.parse(activateFrom.endsWith('Z') ? activateFrom : '${activateFrom}Z').toLocal();
        if (now.isBefore(fromDate)) {
          isScheduledFuture = true;
        }
      }
      
      if (activateTo != null) {
        final toDate = DateTime.parse(activateTo.endsWith('Z') ? activateTo : '${activateTo}Z').toLocal();
        if (now.isAfter(toDate)) {
          isExpired = true;
        }
      }

      String infoText = '';
      if (isScheduledFuture) {
        if (test['formattedActivateFrom'] != null) {
          infoText = 'Termín: ${test['formattedActivateFrom']} – ${test['deadline']} • ${test['questions'] ?? 0} otázek';
        } else {
          infoText = 'Termín: ${test['deadline']} • ${test['questions'] ?? 0} otázek';
        }
      } else if (isExpired) {
        infoText = 'Uzavřeno: ${test['deadline']} • ${test['questions'] ?? 0} otázek';
      } else {
        if (test['deadline'] != 'Bez termínu') {
          infoText = 'Spuštěno do: ${test['deadline']} • ${test['questions'] ?? 0} otázek';
        } else {
          infoText = 'Aktivní • ${test['questions'] ?? 0} otázek';
        }
      }
      bool hasAttemptsRemaining = true;
      if (test['max_attempts'] != null && test['attempts_count'] != null) {
        hasAttemptsRemaining = (test['attempts_count'] as int) < (test['max_attempts'] as int);
      }

      bool isMissed = isExpired && (status == null || status == 'ASSIGNED');
      
      String scoreText = 'Čeká na hodnocení';
      if (isMissed) {
        scoreText = 'Neodevzdáno';
      } else if (status == 'GRADED') {
        scoreText = test['score_percent'] != null ? '${(test['score_percent'] as num).toStringAsFixed(0)} %' : 'Ohodnoceno';
      }

      final uiTest = {
        'id': test['id'],
        'title': test['title'],
        'deadline': test['deadline'],
        'info': infoText,
        'date': test['deadline'],
        'questions': test['questions'] ?? 0,
        'score': scoreText,
        'isWarning': status == 'GRADED' && test['score_percent'] != null && (test['score_percent'] as num) < 50,
        'isMissed': isMissed,
        'attempt_id': test['attempt_id'],
        'attempt_number': test['attempt_number'],
        'attempts_count': test['attempts_count'],
        'isScheduledFuture': isScheduledFuture,
        'isExpired': isExpired,
        'hasAttemptsRemaining': hasAttemptsRemaining,
        'max_attempts': test['max_attempts'],
      };

      if (status == 'STARTED' && !isExpired) {
        activeTest = uiTest; // Pro zjednodušení bere první spuštěný
      } else if (status == 'SUBMITTED' || status == 'GRADED') {
        pastTests.add(uiTest);
        // Pokud mají ještě pokusy, přidáme to i do aktivních (pokud běží okno a není future)
        if (hasAttemptsRemaining && !isScheduledFuture && !isExpired && activeTest == null) {
            activeTest = uiTest;
        }
      } else {
        if (isExpired) {
            pastTests.add(uiTest); // Pokud nestihl začít a vypršelo to, dáme to do historie
        } else {
            // Upcoming or currently active (but not started)
            if (!isScheduledFuture && activeTest == null) {
               activeTest = uiTest; // Available to start!
            } else {
               upcomingTests.add(uiTest);
            }
        }
      }
    }
    
    // Nejnovější historie nahoře
    pastTests = pastTests.reversed.toList();

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      
      // --- HLAVIČKA APLIKACE (AppBar) ---
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor ?? Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent, // Zabrání zešednutí při rolování
        scrolledUnderElevation: 0,
        elevation: 0,
        toolbarHeight: 80, 
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(), // Návrat do přehledu předmětů
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              subjectName,
              style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface, fontSize: 24),
            ),
            const SizedBox(height: 2),
            Text(
              'Detail předmětu',
              style: GoogleFonts.inter(color: Theme.of(context).colorScheme.secondary, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
      
      // --- TĚLO STRÁNKY ---
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              
              // 1. HLAVNÍ STATISTIKA (Bílý box s průměrem)
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: Theme.of(context).colorScheme.outline),
                ),
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      width: 48.0, height: 48.0,
                      decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, borderRadius: BorderRadius.circular(12.0)),
                      child: Icon(Icons.calculate_outlined, color: Theme.of(context).colorScheme.primary, size: 24.0),
                    ),
                    const SizedBox(width: 16.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Předmět', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.secondary, fontSize: 12.0, fontWeight: FontWeight.w600)),
                          Text(subjectName, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18.0, color: Theme.of(context).colorScheme.onSurface)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32.0),

              // 2. AKTIVNÍ TEST (Zobrazí se POUZE, pokud nějaký aktuálně probíhá)
              if (activeTest != null) ...[
                _buildSectionHeader('Aktivní testy', 1, Theme.of(context).colorScheme.error),
                const SizedBox(height: 16.0),
                InkWell(
                  onTap: activeTest['hasAttemptsRemaining'] == false ? () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Vyčerpali jste všechny pokusy.'),
                        backgroundColor: Theme.of(context).colorScheme.error,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  } : () async {
                    // Navigace do ostrého testu s předáním ID testu
                    await context.push('/testActive', extra: {'assignmentId': activeTest!['id'], 'testTitle': activeTest['title']});
                    // Obnovit data po návratu (kvůli aktualizaci počtu pokusů)
                    ref.read(studentOverviewProvider.notifier).fetchDashboardData();
                  },
                  borderRadius: BorderRadius.circular(12.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface, 
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(
                        color: activeTest['hasAttemptsRemaining'] == false 
                          ? Theme.of(context).colorScheme.error.withValues(alpha: 0.5) 
                          : Theme.of(context).colorScheme.primary.withValues(alpha: 0.5), 
                        width: 1.5
                      ), 
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(width: 6, height: 6, decoration: BoxDecoration(color: Theme.of(context).colorScheme.error, shape: BoxShape.circle)),
                                  const SizedBox(width: 6),
                                  Text('Probíhá', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.error, fontSize: 11, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(activeTest['title'], style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16.0, color: Theme.of(context).colorScheme.onSurface)),
                              const SizedBox(height: 2),
                              Text(activeTest['info'], style: GoogleFonts.inter(color: Theme.of(context).colorScheme.secondary, fontSize: 12.0)),
                              const SizedBox(height: 2),
                              Text('Pokus: ${activeTest['attempts_count'] ?? 0} / ${activeTest['max_attempts'] ?? 'Neomezeno'}', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.secondary, fontSize: 12.0, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(
                                activeTest['hasAttemptsRemaining'] == false ? 'Vyčerpáno' : 'Spustit nový pokus', 
                                style: GoogleFonts.inter(
                                  color: activeTest['hasAttemptsRemaining'] == false ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary, 
                                  fontSize: 12.0, 
                                  fontWeight: FontWeight.bold
                                )
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios, color: Theme.of(context).colorScheme.primary, size: 16.0),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32.0),
              ],

              // 3. NADCHÁZEJÍCÍ TESTY
              _buildSectionHeader('Nadcházející testy', upcomingTests.isEmpty ? null : upcomingTests.length, null),
              const SizedBox(height: 12.0),
              if (upcomingTests.isEmpty)
                Text('Zatím nejsou naplánovány žádné testy.', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.secondary, fontSize: 14))
              else
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16.0),
                    border: Border.all(color: Theme.of(context).colorScheme.outline),
                  ),
                  child: Column(
                    children: upcomingTests.asMap().entries.map((entry) {
                      int index = entry.key;
                      Map<String, dynamic> test = entry.value;
                      return Column(
                        children: [
                          _buildUpcomingTestCard(test),
                          // Vykreslí jemnou oddělovací čáru mezi položkami (kromě poslední)
                          if (index != upcomingTests.length - 1)
                            Divider(height: 1, thickness: 1, color: Theme.of(context).colorScheme.outline, indent: 20, endIndent: 20),
                        ],
                      );
                    }).toList(),
                  ),
                ),

              const SizedBox(height: 32.0),

              // 4. HISTORIE (Minulé testy)
              _buildSectionHeader('Historie testů', pastTests.isEmpty ? null : pastTests.length, null),
              const SizedBox(height: 12.0),
              if (pastTests.isEmpty)
                Text('Zatím nemáš žádnou historii testů.', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.secondary, fontSize: 14))
              else
                Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16.0),
                        border: Border.all(color: Theme.of(context).colorScheme.outline),
                      ),
                      child: Column(
                        children: (_showAllHistory ? pastTests : pastTests.take(3).toList()).asMap().entries.map((entry) {
                          int index = entry.key;
                          Map<String, dynamic> test = entry.value;
                          final visibleCount = _showAllHistory ? pastTests.length : (pastTests.length > 3 ? 3 : pastTests.length);
                          return Column(
                            children: [
                              _buildPastTestCard(test),
                              // Čára
                              if (index != visibleCount - 1)
                                Divider(height: 1, thickness: 1, color: Theme.of(context).colorScheme.outline, indent: 20, endIndent: 20),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                    if (pastTests.length > 3) ...[
                      const SizedBox(height: 12.0),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _showAllHistory = !_showAllHistory;
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Theme.of(context).colorScheme.primary,
                            side: BorderSide(color: Theme.of(context).colorScheme.outline),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            backgroundColor: Theme.of(context).colorScheme.surface,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _showAllHistory ? 'Zobrazit méně' : 'Zobrazit celou historii (${pastTests.length})', 
                                style: GoogleFonts.inter(fontWeight: FontWeight.bold)
                              ),
                              const SizedBox(width: 8),
                              Icon(_showAllHistory ? Icons.expand_less : Icons.expand_more, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              
              const SizedBox(height: 40.0), // Místo pro plynulý scroll dolů
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // POMOCNÉ WIDGETY
  // ============================================================================

  /// Společný widget pro nadpisy sekcí (např. "Nadcházející testy").
  /// Volitelně může zobrazit i bublinu s počtem položek.
  Widget _buildSectionHeader(String title, int? count, Color? countColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
        if (count != null && count > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: countColor ?? Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(12)),
            child: Text(count.toString(), style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onError, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
      ],
    );
  }

  /// Karta reprezentující jeden nadcházející (nebo dostupný, ale nespustěný) test.
  /// 
  /// Pokud čas testu ještě nenastal (isScheduledFuture), nedovolí do něj vstoupit.
  Widget _buildUpcomingTestCard(Map<String, dynamic> test) {
    bool isScheduledFuture = test['isScheduledFuture'] == true;

    return InkWell(
      onTap: isScheduledFuture ? () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Čas pro tento test ještě nenastal.'),
            backgroundColor: Theme.of(context).colorScheme.secondary,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } : () async {
         await context.push('/testActive', extra: {'assignmentId': test['id'], 'testTitle': test['title']});
         ref.read(studentOverviewProvider.notifier).fetchDashboardData();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(test['title'], style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14.0, color: isScheduledFuture ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5) : Theme.of(context).colorScheme.onSurface)),
                  const SizedBox(height: 4),
                  Text(test['info'] ?? '', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.secondary, fontSize: 12.0)),
                ],
              ),
            ),
            if (isScheduledFuture)
              Icon(Icons.lock_clock, color: Theme.of(context).colorScheme.secondary, size: 16.0)
            else
              Icon(Icons.arrow_forward_ios, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 14.0),
          ],
        ),
      ),
    );
  }

  /// Karta reprezentující historický test (již odevzdaný nebo ohodnocený).
  /// 
  /// Zobrazuje procentuální skóre, které se může podbarvit oranžově/červeně, 
  /// pokud student nedosáhl dostatečného výsledku (isWarning).
  /// Po kliknutí přesměruje na detailní hodnocení testu.
  Widget _buildPastTestCard(Map<String, dynamic> test) {
    bool isWarning = test['isWarning'] == true;
    bool isMissed = test['isMissed'] == true;
    final customColors = Theme.of(context).extension<CustomColors>();
    Color scoreColor = isWarning ? (customColors?.orangeText ?? const Color(0xFFD97706)) : (customColors?.greenText ?? const Color(0xFF16A34A));
    
    if (isMissed) {
        scoreColor = Theme.of(context).colorScheme.error;
    }

    return InkWell(
      onTap: isMissed ? () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Tento test nebyl vypracován.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      } : () {
        context.push('/studentTestEvaluation', extra: {
          'assignmentId': test['id'] ?? 999,
          'attemptId': test['attempt_id'] ?? 1, // Fallback dokud backend nepřidá attempt_id
          'isStudent': true,
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(test['title'], style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14.0, color: Theme.of(context).colorScheme.onSurface)),
                  const SizedBox(height: 4),
                  Text('${test['date']} • ${test['questions']} otázek', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.secondary, fontSize: 12.0)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(test['score'], style: GoogleFonts.inter(color: scoreColor, fontWeight: FontWeight.bold, fontSize: 16)),
                if (!isMissed)
                  Text('Pokus ${test['attempt_number'] ?? test['attempts_count'] ?? 1}', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}