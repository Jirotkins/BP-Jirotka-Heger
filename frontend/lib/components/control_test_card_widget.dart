import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Komponenta reprezentující interaktivní kartu (tlačítko) v seznamu akcí,
/// typicky používaná v detailu třídy (Class Manager) pro zobrazení aktivních
/// či uzavřených testů a proklik na jejich správu.
class ControlTestCard extends StatelessWidget {
  /// Hlavní nadpis karty (např. název testu).
  final String title;
  
  /// Podtitulek karty (např. termín spuštění nebo statistika odevzdání).
  final String subtitle;
  
  /// Akce vyvolaná po kliknutí na celou kartu.
  final VoidCallback onTap;

  const ControlTestCard({
    super.key, 
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
                  Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: Theme.of(context).colorScheme.onSurface)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: GoogleFonts.inter(color: Theme.of(context).colorScheme.secondary, fontSize: 13)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.primary),
          ],
        ),
      ),
    );
  }
}