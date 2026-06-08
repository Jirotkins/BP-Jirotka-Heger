import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../components/subject_card_widget.dart'; 

// Úvodní domovská obrazovka studenta (Dashboard).
// Slouží jako rozcestník pro probíhající testy a přehled zapsaných předmětů.
class StudentOverviewWidget extends StatefulWidget {
  const StudentOverviewWidget({super.key});

  @override
  State<StudentOverviewWidget> createState() => _StudentOverviewWidgetState();
}

class _StudentOverviewWidgetState extends State<StudentOverviewWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  // Seznam aktuálně probíhajících testů.
  final List<Map<String, dynamic>> _activeTests = [
    {
      'id': 'test_999', 
      'title': 'Matematika – Funkce',
      'deadline': 'Dnes 23:59',
      'expiresIn': '45 min',
    }
  ];

  // Seznam předmětů žáka.
  // Atribut 'status' je klíčový pro design karty. Očekáváme hodnoty:
  // - 'active' (Test nyní - červená barva)
  // - 'upcoming' (Test brzy - žlutá/oranžová barva)
  // - 'none' (Žádný test / Vše ohodnoceno - zelená barva)
  final List<Map<String, dynamic>> _mySubjects = [
    {
      'id': 'sub_1', 'code': 'MA', 'name': 'Matematika', 'teacher': 'Ing. Petr Svoboda', 
      'color': const Color(0xFF4285F4), 'testCount': 3, 'status': 'active', 'timeText': 'Vyprší 45 min'
    },
    {
      'id': 'sub_2', 'code': 'FY', 'name': 'Fyzika', 'teacher': 'doc. Jana Horáková', 
      'color': const Color(0xFF34A853), 'testCount': 2, 'status': 'upcoming', 'timeText': 'Za 2 dny'
    },
    {
      'id': 'sub_3', 'code': 'CH', 'name': 'Chemie', 'teacher': 'Mgr. Tomáš Blažek', 
      'color': const Color(0xFFAB47DB), 'testCount': 4, 'status': 'none', 'timeText': 'Vše ohodnoceno'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: const Color(0xFFF5F7FA),
      
      // --- HLAVIČKA APLIKACE (AppBar) ---
      appBar: AppBar(
        // Nastavení pro čistě bílou barvu nezávislou na scrollování (Material 3)
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0, 
        automaticallyImplyLeading: false,
        elevation: 0, 
        toolbarHeight: 80, 
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Jakub Novák', style: GoogleFonts.inter(color: Colors.black87, fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text('Přehled studia', style: GoogleFonts.inter(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
      
      // --- TĚLO STRÁNKY ---
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              // 1. SEKCE: AKTIVNÍ TESTY (Prioritní, vyžadují akci)
              _buildSectionHeader('Aktivní testy', _activeTests.length, const Color(0xFFDC2626)),
              const SizedBox(height: 16),
              // Vykreslí všechny probíhající testy jako velké červené karty
              ..._activeTests.map((test) => _buildActiveTestCard(test)).toList(),

              const SizedBox(height: 32),

              // 2. SEKCE: MOJE PŘEDMĚTY
              _buildSectionHeader('Moje předměty', null, null),
              const SizedBox(height: 16),
              
              // Mapování pole předmětů z API na naši univerzální komponentu
              ..._mySubjects.map((sub) => SubjectCardWidget(
                id: sub['id'],
                code: sub['code'],
                name: sub['name'],
                teacher: sub['teacher'],
                color: sub['color'],
                testCount: sub['testCount'],
                status: sub['status'],
                timeText: sub['timeText'],
              )).toList(),
              
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
        Text(title, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
        if (count != null && count > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: countColor, borderRadius: BorderRadius.circular(12)),
            child: Text(count.toString(), style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFFDC2626).withOpacity(0.5), width: 1.5),
        boxShadow: [BoxShadow(color: const Color(0xFFDC2626).withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          // Levá ikona
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.quiz_outlined, color: Color(0xFFDC2626), size: 24),
          ),
          const SizedBox(width: 16),
          // Informace o testu
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Probíhá', style: TextStyle(color: Color(0xFFDC2626), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                const SizedBox(height: 2),
                Text(test['title'], style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                const SizedBox(height: 2),
                Text('Dostupný do: ${test['deadline']}', style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 12)),
              ],
            ),
          ),
          // Odpočet a spouštěcí tlačítko
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  const Icon(Icons.schedule, color: Color(0xFFDC2626), size: 14),
                  const SizedBox(width: 4),
                  Text(test['expiresIn'], style: GoogleFonts.inter(color: Color(0xFFDC2626), fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  // Otevře ostrý test a předá do něj ID testu, aby si TestActiveWidget
                  // mohl z API (GET /api/tests/{testId}/take) načíst příslušné otázky.
                  context.push('/testActive', extra: {'testId': test['id'], 'testTitle': test['title']});
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
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