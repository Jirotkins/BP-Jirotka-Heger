import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_themes.dart';

// Stránka s detailem konkrétního předmětu (např. Matematika).
// Zobrazuje statistiky, právě probíhající test, budoucí termíny a historii.
class SubjectPageWidget extends StatefulWidget {
  const SubjectPageWidget({super.key});

  @override
  State<SubjectPageWidget> createState() => _SubjectPageWidgetState();
}

class _SubjectPageWidgetState extends State<SubjectPageWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  // Právě probíhající test (pokud existuje). Pokud ne, hodnota je null.
  final Map<String, dynamic>? _activeTest = {
    'id': 'test_999',
    'title': 'Funkce',
    'info': 'Termín: 15. 1. 2025 • 20 otázek',
  };

  // Seznam budoucích testů
  final List<Map<String, dynamic>> _upcomingTests = [
    {
      'id': 'test_789', 
      'title': 'Rovnice a nerovnice',
      'deadline': '28. 1. 2025',
      'questions': 15,
    }
  ];

  // Seznam dokončených a opravených testů
  final List<Map<String, dynamic>> _pastTests = [
    {
      'id': 'test_700',
      'title': 'Geometrie – obvod a obsah',
      'date': '10. 12. 2024',
      'questions': 18,
      'score': '85%',
    },
    {
      'id': 'test_701',
      'title': 'Přirozená čísla a operace',
      'date': '20. 11. 2024',
      'questions': 25,
      'score': '60%',
      'isWarning': true, // Slouží k obarvení skóre na oranžovo/červeno
    }
  ];

  @override
  Widget build(BuildContext context) {
    // Načtení argumentů předaných přes navigaci (např. z domovské stránky)
    // Předáváme id a název předmětu, aby se nemusel název tahat z API jen kvůli hlavičce
    final args = GoRouterState.of(context).extra as Map<String, dynamic>?;
    final String subjectName = args?['subjectName'] ?? 'Matematika';

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
              if (_activeTest != null) ...[
                _buildSectionHeader('Aktivní testy', 1, Theme.of(context).colorScheme.error),
                const SizedBox(height: 16.0),
                InkWell(
                  onTap: () {
                    // Navigace do ostrého testu s předáním ID testu
                    context.push('/testActive', extra: {'testId': _activeTest!['id'], 'testTitle': _activeTest!['title']});
                  },
                  borderRadius: BorderRadius.circular(12.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface, 
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5), width: 1.5), 
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
                              Text(_activeTest!['title'], style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16.0, color: Theme.of(context).colorScheme.onSurface)),
                              const SizedBox(height: 2),
                              Text(_activeTest!['info'], style: GoogleFonts.inter(color: Theme.of(context).colorScheme.secondary, fontSize: 12.0)),
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
              _buildSectionHeader('Nadcházející testy', null, null),
              const SizedBox(height: 12.0),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: Theme.of(context).colorScheme.outline),
                ),
                child: Column(
                  children: _upcomingTests.asMap().entries.map((entry) {
                    int index = entry.key;
                    Map<String, dynamic> test = entry.value;
                    return Column(
                      children: [
                        _buildUpcomingTestCard(test),
                        // Vykreslí jemnou oddělovací čáru mezi položkami (kromě poslední)
                        if (index != _upcomingTests.length - 1)
                          Divider(height: 1, thickness: 1, color: Theme.of(context).colorScheme.outline, indent: 20, endIndent: 20),
                      ],
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 32.0),

              // 4. HISTORIE (PŘEDCHOZÍ TESTY)
              _buildSectionHeader('Předchozí testy', null, null),
              const SizedBox(height: 12.0),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: Theme.of(context).colorScheme.outline),
                ),
                child: Column(
                  children: _pastTests.asMap().entries.map((entry) {
                    int index = entry.key;
                    Map<String, dynamic> test = entry.value;
                    return Column(
                      children: [
                        _buildPastTestCard(test),
                        if (index != _pastTests.length - 1)
                          Divider(height: 1, thickness: 1, color: Theme.of(context).colorScheme.outline, indent: 20, endIndent: 20),
                      ],
                    );
                  }).toList(),
                ),
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

  // Společný widget pro nadpisy sekcí (volitelně s kulatým odznáčkem počtu)
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

  // Karta reprezentující jeden nadcházející test. Po kliknutí otevře ostrý test.
  Widget _buildUpcomingTestCard(Map<String, dynamic> test) {
    return InkWell(
      onTap: () {
         context.push('/testActive', extra: {'testId': test['id'], 'testTitle': test['title']});
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
                  Text('Termín: ${test['deadline']} • ${test['questions']} otázek', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.secondary, fontSize: 12.0)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 14.0),
          ],
        ),
      ),
    );
  }

  // Karta reprezentující historický test. Může mít oranžové skóre při horším výsledku.
  Widget _buildPastTestCard(Map<String, dynamic> test) {
    bool isWarning = test['isWarning'] == true;
    final customColors = Theme.of(context).extension<CustomColors>();
    Color scoreColor = isWarning ? (customColors?.orangeText ?? const Color(0xFFD97706)) : (customColors?.greenText ?? const Color(0xFF16A34A));

    return InkWell(
      onTap: () {
        print('Otevřít výsledky pro test ID: ${test['id']}');
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
                Text('1', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)), 
              ],
            ),
          ],
        ),
      ),
    );
  }
}