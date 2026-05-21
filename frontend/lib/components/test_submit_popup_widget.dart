import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TestSubmitPopupWidget extends StatelessWidget {
  final int answeredQuestions;
  final int totalQuestions;
  final VoidCallback onSubmit;

  const TestSubmitPopupWidget({
    super.key,
    required this.answeredQuestions, 
    required this.totalQuestions,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    // LOGIKA PREVENCE CHYB (Nielsenova heuristika)
    bool hasUnanswered = answeredQuestions < totalQuestions;
    
    // Dynamické barvy podle toho, zda test obsahuje nevyplněné otázky
    Color primaryColor = hasUnanswered ? const Color(0xFFD97706) : const Color(0xFF0056D2); // Oranžová vs Modrá
    Color bgColor = hasUnanswered ? const Color(0xFFFEF3C7) : const Color(0xFFF0F4FF);
    IconData topIcon = hasUnanswered ? Icons.notification_important_rounded : Icons.check_circle_outline;
    String titleText = hasUnanswered ? 'Pozor, nemáte hotovo!' : 'Opravdu chcete\nodevzdat test?';

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
            // IKONA A NADPIS (Dynamická zpětná vazba)
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: Icon(topIcon, color: primaryColor, size: 32),
            ),
            const SizedBox(height: 16.0),
            Text(
              titleText,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 22.0, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 12.0),
            
            // INFORMAČNÍ TEXT
            Text(
              'Vyplnili jste $answeredQuestions z $totalQuestions otázek.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14.0, 
                fontWeight: FontWeight.w600, 
                color: hasUnanswered ? const Color(0xFFD97706) : Colors.grey.shade600,
              ),
            ),
            
            if (hasUnanswered) ...[
              const SizedBox(height: 8.0),
              Text(
                'Doporučujeme se vrátit a test dokončit, abyste nepřišli o body.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 13.0, color: Colors.grey.shade600, height: 1.4),
              ),
            ],
            
            const SizedBox(height: 32.0),

            // TLAČÍTKA
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // TLAČÍTKO "ZPĚT K TESTU"
                if (hasUnanswered)
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(), 
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22.0)),
                    ),
                    child: Text('Vrátit se k testu', style: GoogleFonts.inter(fontSize: 16.0, fontWeight: FontWeight.bold)),
                  ),
                
                if (hasUnanswered) const SizedBox(height: 12.0),

                // TLAČÍTKO "ODEVZDAT K HODNOCENÍ"
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); 
                    onSubmit(); 
                  },
                  style: ElevatedButton.styleFrom(
                    // Pokud něco chybí, tlačítko pro odevzdání je jen šedé/nenápadné, abychom uživatele odradili
                    backgroundColor: hasUnanswered ? Colors.grey.shade200 : primaryColor,
                    foregroundColor: hasUnanswered ? Colors.black87 : Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22.0)),
                  ),
                  child: Text('Přesto odevzdat', style: GoogleFonts.inter(fontSize: 16.0, fontWeight: FontWeight.bold)),
                ),

                if (!hasUnanswered) ...[
                  const SizedBox(height: 12.0),
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
                ]
              ],
            ),
          ],
        ),
      ),
    );
  }
}