import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'dart:typed_data';

/// Znovupoužitelná komponenta (Dialog) představující maketu mobilního zařízení.
/// Používá se v editorech otázek pro funkci "Pohled studenta".
class StudentPreviewDialog extends StatelessWidget {
  /// Znění dané otázky.
  final String questionText;

  /// Base64 řetězec obsahující nahraný obrázek (volitelný).
  final String? imageBase64;

  /// Samotný obsah odpovědí (generovaný pro daný typ otázky).
  final Widget child;

  /// Volitelný podtitulek zobrazený pod otázkou (např. "Vyberte jednu správnou odpověď:").
  final String? subtitle;

  const StudentPreviewDialog({
    super.key,
    required this.questionText,
    this.imageBase64,
    required this.child,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    Uint8List? imageBytes;
    if (imageBase64 != null && imageBase64!.startsWith('data:image')) {
      try {
        final b64 = imageBase64!.split(',').last;
        imageBytes = base64Decode(b64);
      } catch (_) {}
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Center(
        child: Container(
          width: 375.0, // Průměrná šířka telefonu (iPhone SE / menší telefony)
          height: 700.0, // Fixní výška
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(36.0),
            border: Border.all(
              color: Theme.of(context).colorScheme.onSurface,
              width: 10.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
                blurRadius: 20.0,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26.0),
            child: Scaffold(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              appBar: AppBar(
                backgroundColor: Theme.of(context).colorScheme.surface,
                elevation: 0,
                titleSpacing: 0,
                leading: IconButton(
                  icon: Icon(
                    Icons.close,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  'TEST',
                  style: GoogleFonts.inter(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Bílý pruh pod hlavičkou s progresem
                  Container(
                    color: Theme.of(context).colorScheme.surface,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 16.0,
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Otázka 1 z 5',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            Row(
                              children: [
                                Icon(
                                  Icons.timer_outlined,
                                  size: 16,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '24:15',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Progress bar
                        Stack(
                          children: [
                            Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.outlineVariant,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            Container(
                              height: 6,
                              width: 60, // 1 z 5
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Hlavní obsah s otázkou a odpověďmi
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Bílý box s textem otázky
                          Container(
                            padding: const EdgeInsets.all(20.0),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(12.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(
                                    context,
                                  ).shadowColor.withValues(alpha: 0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              questionText.trim().isEmpty
                                  ? '[Zde bude znění otázky...]'
                                  : questionText.trim(),
                              style: GoogleFonts.inter(
                                fontSize: 16.0,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),

                          const SizedBox(height: 16.0),

                          // OBRÁZEK K OTÁZCE
                          if (imageBytes != null) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12.0),
                              child: Image.memory(
                                imageBytes,
                                width: double.infinity,
                                height: 180, // Fixní výška náhledu obrázku
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 16.0),
                          ],

                          // Podtitulek (např. Vyberte jednu správnou odpověď:)
                          if (subtitle != null) ...[
                            Text(
                              subtitle!,
                              style: GoogleFonts.inter(
                                fontSize: 13.0,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                            const SizedBox(height: 16.0),
                          ],

                          // CUSTOM OBSAH MOŽNOSTÍ (předaný z editoru)
                          Expanded(child: child),
                          const SizedBox(height: 16.0),

                          // FALEŠNÉ TLAČÍTKO "Další otázka"
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              minimumSize: const Size(double.infinity, 48.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24.0),
                              ),
                              elevation: 0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Další otázka',
                                  style: GoogleFonts.inter(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.arrow_forward,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimary,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
