import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_themes.dart';

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
    final customColors = Theme.of(context).extension<CustomColors>();
    // --- Logika pro barevné odznáčky a texty podle stavu z backendu ---
    Color badgeBgColor = Theme.of(context).colorScheme.surfaceContainerHighest; // Default šedá
    Color badgeTextColor = Theme.of(context).colorScheme.secondary;
    String badgeText = "Žádný test";
    
    Color timeIconColor = Theme.of(context).colorScheme.secondary;
    IconData timeIcon = Icons.check_circle_outline;

    if (status == 'active') {
      badgeBgColor = customColors?.redBg ?? Theme.of(context).colorScheme.errorContainer;
      badgeTextColor = customColors?.redText ?? Theme.of(context).colorScheme.error;
      badgeText = "Test nyní";
      timeIconColor = badgeTextColor;
      timeIcon = Icons.schedule;
    } else if (status == 'upcoming') {
      badgeBgColor = customColors?.orangeBg ?? const Color(0xFFFEF9C3);
      badgeTextColor = customColors?.orangeText ?? const Color(0xFFD97706);
      badgeText = "Test brzy";
      timeIconColor = badgeTextColor;
      timeIcon = Icons.calendar_today_outlined;
    } else {
      badgeBgColor = customColors?.greenBg ?? const Color(0xFFDCFCE7);
      badgeTextColor = customColors?.greenText ?? const Color(0xFF16A34A);
    }

    return InkWell(
      onTap: () {
        // Navigace do detailu předmětu s předáním parametrů
        context.push('/subjectPage', extra: {
            'subjectId': id,
            'subjectName': name,
          });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          boxShadow: [BoxShadow(color: Theme.of(context).shadowColor.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          children: [
            // HORNÍ ŘÁDEK: Ikona, Název, Učitel, Odznáček
            Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  alignment: Alignment.center,
                  child: Text(code, style: GoogleFonts.inter(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.onSurface)),
                      const SizedBox(height: 2),
                      Text(teacher, style: GoogleFonts.inter(color: Theme.of(context).colorScheme.secondary, fontSize: 13)),
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
            
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Divider(height: 1, color: Theme.of(context).colorScheme.outline),
            ),

            // SPODNÍ ŘÁDEK: Počet testů, časový údaj, šipka
            Row(
              children: [
                Icon(Icons.assignment_outlined, size: 16, color: Theme.of(context).colorScheme.secondary),
                const SizedBox(width: 6),
                Text('$testCount testy', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.secondary, fontSize: 12, fontWeight: FontWeight.w500)),
                
                const SizedBox(width: 16),
                
                Icon(timeIcon, size: 16, color: timeIconColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(timeText ?? 'Vše ohodnoceno', style: GoogleFonts.inter(color: timeIconColor, fontSize: 12, fontWeight: FontWeight.w500)),
                ),
                
                Icon(Icons.arrow_forward_ios, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 14),
              ],
            )
          ],
        ),
      ),
    );
  }
}