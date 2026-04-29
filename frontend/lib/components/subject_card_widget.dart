import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SubjectCardWidget extends StatelessWidget {
  final String id;
  final String code; // např. MA
  final String name; // např. Matematika
  final String teacher; // např. Ing. Petr Svoboda
  final Color color; // Hlavní barva předmětu (na ikonku)
  
  final int testCount; // Kolik má předmět celkem testů
  final String status; // 'active', 'upcoming', 'none'
  final String? timeText; // např. "Vyprší 45 min", "Za 2 dny"

  const SubjectCardWidget({
    super.key,
    required this.id,
    required this.code,
    required this.name,
    required this.teacher,
    required this.color,
    required this.testCount,
    required this.status,
    this.timeText,
  });

  @override
  Widget build(BuildContext context) {
    // --- Logika pro barevné odznáčky a texty podle stavu z backendu ---
    Color badgeBgColor = const Color(0xFFF3F4F6); // Default šedá
    Color badgeTextColor = const Color(0xFF6B7280);
    String badgeText = "Žádný test";
    
    Color timeIconColor = Colors.grey;
    IconData timeIcon = Icons.check_circle_outline;

    if (status == 'active') {
      badgeBgColor = const Color(0xFFFEE2E2); // Světle červená
      badgeTextColor = const Color(0xFFDC2626); // Tmavě červená
      badgeText = "Test nyní";
      timeIconColor = const Color(0xFFDC2626);
      timeIcon = Icons.schedule;
    } else if (status == 'upcoming') {
      badgeBgColor = const Color(0xFFFEF9C3); // Světle žlutá
      badgeTextColor = const Color(0xFFD97706); // Tmavě oranžová
      badgeText = "Test brzy";
      timeIconColor = const Color(0xFFD97706);
      timeIcon = Icons.calendar_today_outlined;
    } else {
      badgeBgColor = const Color(0xFFDCFCE7); // Světle zelená
      badgeTextColor = const Color(0xFF16A34A); // Tmavě zelená
    }

    return InkWell(
      onTap: () {
        // Navigace do detailu předmětu s předáním parametrů
        Navigator.pushNamed(
          context, 
          '/subjectPage',
          arguments: {
            'subjectId': id,
            'subjectName': name,
          }
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          children: [
            // HORNÍ ŘÁDEK: Ikona, Název, Učitel, Odznáček
            Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  alignment: Alignment.center,
                  child: Text(code, style: GoogleFonts.inter(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                      const SizedBox(height: 2),
                      Text(teacher, style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13)),
                    ],
                  ),
                ),
                // Barevný odznáček
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: badgeBgColor, borderRadius: BorderRadius.circular(20)),
                  child: Text(badgeText, style: GoogleFonts.inter(color: badgeTextColor, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Divider(height: 1, color: Color(0xFFF3F4F6)),
            ),

            // SPODNÍ ŘÁDEK: Počet testů, časový údaj, šipka
            Row(
              children: [
                Icon(Icons.assignment_outlined, size: 16, color: Colors.grey.shade500),
                const SizedBox(width: 6),
                Text('$testCount testy', style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500)),
                
                const SizedBox(width: 16),
                
                Icon(timeIcon, size: 16, color: timeIconColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(timeText ?? 'Vše ohodnoceno', style: GoogleFonts.inter(color: timeIconColor, fontSize: 12, fontWeight: FontWeight.w500)),
                ),
                
                Icon(Icons.arrow_forward_ios, color: Colors.grey.shade400, size: 14),
              ],
            )
          ],
        ),
      ),
    );
  }
}