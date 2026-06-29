import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_themes.dart';

class QuestionTypeMenuWidget extends StatelessWidget {
  final Map<String, dynamic>? args;

  const QuestionTypeMenuWidget({
    super.key,
    this.args,
  });

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<CustomColors>();
    // ZÍSKÁNÍ DAT Z PARAMETRU (nikoliv přes router context uvnitř dialogu)
    final String targetName = args?['targetName'] ?? 'Neznámá banka';

    // Pomocná funkce pro navigaci, která rovnou předá název banky dál
    void navigateToEditor(String routeName) {
      context.push(
        routeName,
        extra: args,
      );
    }

    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Container(
        width: 560.0,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: Theme.of(context).colorScheme.outline, width: 1.0),
          boxShadow: [
            BoxShadow(
              blurRadius: 24.0,
              color: Colors.black.withOpacity(0.04),
              offset: const Offset(0.0, 4.0),
            )
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min, 
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Vyberte typ otázky',
                style: GoogleFonts.inter(
                  fontSize: 20.0,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8.0),
              
              Text(
                'Zvolte formát otázky, kterou chcete vytvořit do banky: $targetName.',
                style: GoogleFonts.inter(
                  fontSize: 14.0,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 24.0), // Větší mezera před seznamem

              // Možnost 1: Výběr z možností
              _buildMenuOption(
                context: context,
                icon: Icons.check_box_outlined,
                iconColor: customColors?.blueText ?? Theme.of(context).colorScheme.primary,
                iconBgColor: customColors?.blueBg ?? Theme.of(context).colorScheme.primaryContainer,
                title: 'Výběr z možností',
                description: 'Student vybírá jednu nebo více správných odpovědí.',
                onTap: () => navigateToEditor('/multiChoiceQuestion'), 
              ),
              const SizedBox(height: 12.0),

              // Možnost 2: Krátká odpověď
              _buildMenuOption(
                context: context,
                icon: Icons.edit_outlined,
                iconColor: customColors?.redText ?? Theme.of(context).colorScheme.primary,
                iconBgColor: customColors?.redBg ?? Theme.of(context).colorScheme.primaryContainer,
                title: 'Krátká odpověď',
                description: 'Student odpovídá jedním slovem do textového pole.',
                onTap: () => navigateToEditor('/shortAnswerQuestion'),
              ),
              const SizedBox(height: 12.0),

              // Možnost 3: Seřazení
              _buildMenuOption(
                context: context,
                icon: Icons.drag_indicator_rounded,
                iconColor: customColors?.orangeText ?? Theme.of(context).colorScheme.primary,
                iconBgColor: customColors?.orangeBg ?? Theme.of(context).colorScheme.primaryContainer,
                title: 'Seřazení',
                description: 'Student seřazuje prvky podle určeného pořadí.',
                onTap: () => navigateToEditor('/orderQuestion'),
              ),
              const SizedBox(height: 12.0),

              // Možnost 4: Párování
              _buildMenuOption(
                context: context,
                icon: Icons.compare_arrows_rounded,
                iconColor: customColors?.purpleText ?? Theme.of(context).colorScheme.primary,
                iconBgColor: customColors?.purpleBg ?? Theme.of(context).colorScheme.primaryContainer,
                title: 'Párování',
                description: 'Student spojuje dvojice pojmů nebo obrázků.',
                onTap: () => navigateToEditor('/connectQuestion'),
              ),
              const SizedBox(height: 12.0),

              // Možnost 5: Otevřená otázka
              _buildMenuOption(
                context: context,
                icon: Icons.notes_rounded, 
                iconColor: customColors?.greenText ?? Theme.of(context).colorScheme.primary,
                iconBgColor: customColors?.greenBg ?? Theme.of(context).colorScheme.primaryContainer,
                title: 'Otevřená otázka',
                description: 'Student odpovídá vlastními slovy do textového pole.',
                onTap: () => navigateToEditor('/openQuestion'),
              ),
              const SizedBox(height: 32.0),

              // Tlačítko Zrušit (Návrat zpět)
              Align(
                alignment: Alignment.center,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context), 
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(160.0, 44.0),
                    side: BorderSide(color: Theme.of(context).colorScheme.outline, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22.0)),
                    foregroundColor: Theme.of(context).colorScheme.secondary,
                  ),
                  child: Text(
                    'Zrušit',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14.0),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Pomocná metoda 
  Widget _buildMenuOption({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16.0),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: Theme.of(context).colorScheme.outline, width: 1.0),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 48.0,
              height: 48.0,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Icon(icon, color: iconColor, size: 24.0),
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15.0, color: Theme.of(context).colorScheme.onSurface),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    description,
                    style: GoogleFonts.inter(fontSize: 13.0, color: Theme.of(context).colorScheme.secondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16.0),
            Icon(Icons.chevron_right_rounded, color: Theme.of(context).colorScheme.secondary, size: 24.0),
          ],
        ),
      ),
    );
  }
}