import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Interaktivní karta pro zobrazení běžícího (nebo naplánovaného) testu 
/// ve výpisu třídy (Class Overview). Ukazuje kolik studentů již odevzdalo.
class ActiveTestCard extends StatelessWidget {
  /// Název testu.
  final String title;
  
  /// Doplňující text (např. čas spuštění).
  final String subtitle;
  
  /// Počet studentů, kteří test už úspěšně odevzdali.
  final int submittedCount;
  
  /// Celkový počet studentů přihlášených k testu.
  final int totalStudents;
  
  /// Akce vyvolaná po kliknutí na kartu.
  final VoidCallback onTap;
  
  /// Určuje, zda test zrovna probíhá (`false`) nebo je pouze naplánován na později (`true`).
  final bool isScheduled;

  const ActiveTestCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.submittedCount,
    required this.totalStudents,
    required this.onTap,
    this.isScheduled = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface, 
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).colorScheme.outline, width: 1.0),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(width: 6, height: 6, decoration: BoxDecoration(color: isScheduled ? Theme.of(context).colorScheme.tertiary : Theme.of(context).colorScheme.error, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Text(isScheduled ? 'Naplánováno' : 'Probíhá', style: GoogleFonts.inter(color: isScheduled ? Theme.of(context).colorScheme.tertiary : Theme.of(context).colorScheme.error, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: Theme.of(context).colorScheme.onSurface)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: GoogleFonts.inter(color: Theme.of(context).colorScheme.secondary, fontSize: 13)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$submittedCount/$totalStudents', 
                  style: GoogleFonts.inter(color: Theme.of(context).colorScheme.primary, fontSize: 22, fontWeight: FontWeight.w800)
                ),
                Text('odevzdalo', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.secondary, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}