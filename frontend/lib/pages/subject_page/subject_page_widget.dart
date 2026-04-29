import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final String subjectName = args?['subjectName'] ?? 'Matematika';

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: const Color(0xFFF5F7FA),
      
      // --- HLAVIČKA APLIKACE (AppBar) ---
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent, // Zabrání zešednutí při rolování
        scrolledUnderElevation: 0,
        elevation: 0,
        toolbarHeight: 80, 
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(), // Návrat do přehledu předmětů
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              subjectName,
              style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: Colors.black87, fontSize: 24),
            ),
            const SizedBox(height: 2),
            Text(
              'Detail předmětu',
              style: GoogleFonts.inter(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500),
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      width: 48.0, height: 48.0,
                      decoration: BoxDecoration(color: const Color(0xFFF0F4FF), borderRadius: BorderRadius.circular(12.0)),
                      child: const Icon(Icons.calculate_outlined, color: Color(0xFF4285F4), size: 24.0),
                    ),
                    const SizedBox(width: 16.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Předmět', style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 12.0, fontWeight: FontWeight.w600)),
                          Text(subjectName, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18.0, color: Colors.black87)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32.0),

              // 2. AKTIVNÍ TEST (Zobrazí se POUZE, pokud nějaký aktuálně probíhá)
              if (_activeTest != null) ...[
                _buildSectionHeader('Aktivní testy', 1, const Color(0xFFDC2626)),
                const SizedBox(height: 16.0),
                InkWell(
                  onTap: () {
                    // Navigace do ostrého testu s předáním ID testu
                    Navigator.pushNamed(
                      context, 
                      '/testActive', 
                      arguments: {'testId': _activeTest!['id'], 'testTitle': _activeTest!['title']}
                    );
                  },
                  borderRadius: BorderRadius.circular(12.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFF), 
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.5), width: 1.5), 
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
                                  Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFFDC2626), shape: BoxShape.circle)),
                                  const SizedBox(width: 6),
                                  Text('Probíhá', style: GoogleFonts.inter(color: const Color(0xFFDC2626), fontSize: 11, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(_activeTest!['title'], style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16.0, color: Colors.black87)),
                              const SizedBox(height: 2),
                              Text(_activeTest!['info'], style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 12.0)),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, color: Color(0xFF4285F4), size: 16.0),
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
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
                          const Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6), indent: 20, endIndent: 20),
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  children: _pastTests.asMap().entries.map((entry) {
                    int index = entry.key;
                    Map<String, dynamic> test = entry.value;
                    return Column(
                      children: [
                        _buildPastTestCard(test),
                        if (index != _pastTests.length - 1)
                          const Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6), indent: 20, endIndent: 20),
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
        Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
        if (count != null && count > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: countColor, borderRadius: BorderRadius.circular(12)),
            child: Text(count.toString(), style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
      ],
    );
  }

  // Karta reprezentující jeden nadcházející test. Po kliknutí otevře ostrý test.
  Widget _buildUpcomingTestCard(Map<String, dynamic> test) {
    return InkWell(
      onTap: () {
         Navigator.pushNamed(context, '/testActive', arguments: {'testId': test['id'], 'testTitle': test['title']});
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(test['title'], style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14.0, color: Colors.black87)),
                  const SizedBox(height: 4),
                  Text('Termín: ${test['deadline']} • ${test['questions']} otázek', style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 12.0)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey.shade400, size: 14.0),
          ],
        ),
      ),
    );
  }

  // Karta reprezentující historický test. Může mít oranžové skóre při horším výsledku.
  Widget _buildPastTestCard(Map<String, dynamic> test) {
    bool isWarning = test['isWarning'] == true;
    Color scoreColor = isWarning ? const Color(0xFFD97706) : const Color(0xFF16A34A);

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
                  Text(test['title'], style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14.0, color: Colors.black87)),
                  const SizedBox(height: 4),
                  Text('${test['date']} • ${test['questions']} otázek', style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 12.0)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(test['score'], style: GoogleFonts.inter(color: scoreColor, fontWeight: FontWeight.bold, fontSize: 16)),
                Text('1', style: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 12)), 
              ],
            ),
          ],
        ),
      ),
    );
  }
}