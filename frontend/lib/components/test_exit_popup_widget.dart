import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TestExitPopupWidget extends StatelessWidget {
  final VoidCallback onExit;

  const TestExitPopupWidget({
    super.key,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        width: 340.0,
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(24.0),
          boxShadow: const [BoxShadow(blurRadius: 16.0, color: Colors.black12, offset: Offset(0, 8))],
        ),
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // IKONA A NADPIS
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: const BoxDecoration(color: Color(0xFFFEF2F2), shape: BoxShape.circle),
              child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 32),
            ),
            const SizedBox(height: 16.0),
            Text(
              'Opustit test?',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 22.0, fontWeight: FontWeight.bold, color: const Color(0xFFDC2626)),
            ),
            const SizedBox(height: 12.0),
            Text(
              'Pokud nyní odejdete, váš postup se neuloží a test bude vyhodnocen jako neodevzdaný.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14.0, fontWeight: FontWeight.w500, color: Colors.grey.shade600, height: 1.4),
            ),
            
            const SizedBox(height: 32.0),

            // TLAČÍTKA
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // TLAČÍTKO "OPUSTIT TEST" (Hlavní výstražná akce)
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Zavře popup
                    onExit(); // Spustí logiku odchodu
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22.0)),
                  ),
                  child: Text('Opustit test', style: GoogleFonts.inter(fontSize: 16.0, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12.0),
                // TLAČÍTKO "ZRUŠIT" (Návrat k testování)
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(), 
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade600,
                    side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22.0)),
                  ),
                  child: Text('Zrušit', style: GoogleFonts.inter(fontSize: 16.0, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}