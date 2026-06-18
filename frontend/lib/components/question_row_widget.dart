import 'package:flutter/material.dart';
import '../theme/app_themes.dart';

class QuestionRowWidget extends StatelessWidget {
  final int id;
  final String question;
  final String type;

  const QuestionRowWidget({
    super.key,
    required this.id,
    required this.question,
    required this.type,
  });

  Map<String, Color> _getTypeColors(BuildContext context, String questionType) {
    final customColors = Theme.of(context).extension<CustomColors>();
    switch (questionType) {
      case 'Výběr z možností':
        return {'bg': customColors?.blueBg ?? Theme.of(context).colorScheme.primaryContainer, 'text': customColors?.blueText ?? Theme.of(context).colorScheme.primary};
      case 'Seřazení':
        return {'bg': customColors?.orangeBg ?? Theme.of(context).colorScheme.primaryContainer, 'text': customColors?.orangeText ?? Theme.of(context).colorScheme.primary};
      case 'Párování':
        return {'bg': customColors?.purpleBg ?? Theme.of(context).colorScheme.primaryContainer, 'text': customColors?.purpleText ?? Theme.of(context).colorScheme.primary};
      case 'Otevřená':
        return {'bg': customColors?.greenBg ?? Theme.of(context).colorScheme.primaryContainer, 'text': customColors?.greenText ?? Theme.of(context).colorScheme.primary};
      case 'Krátká odpověď':
        return {'bg': customColors?.redBg ?? Theme.of(context).colorScheme.primaryContainer, 'text': customColors?.redText ?? Theme.of(context).colorScheme.primary};
      default:
        return {'bg': Theme.of(context).colorScheme.surfaceContainerHighest, 'text': Theme.of(context).colorScheme.onSurface};
    }
  }

  @override
  Widget build(BuildContext context) {
    // Získáme barvy pro aktuální typ otázky
    final typeColors = _getTypeColors(context, type);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface, // Původně primaryBackground
          borderRadius: BorderRadius.circular(12.0), // Zmenšeno z 22 na 12 pro hezčí řádek
        ),
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ID OTÁZKY
            SizedBox(
              width: 40.0,
              child: Text(
                id.toString(),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            
            // ZNĚNÍ OTÁZKY
            Expanded(
              flex: 5,
              child: Text(
                question,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14.0,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 16.0),

            // ŠTÍTEK S TYPEM OTÁZKY
            Container(
              width: 140.0,
              decoration: BoxDecoration(
                color: typeColors['bg'],
                borderRadius: BorderRadius.circular(22.0),
              ),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
              child: Text(
                type,
                style: TextStyle(
                  color: typeColors['text'],
                  fontWeight: FontWeight.w600,
                  fontSize: 12.0,
                ),
              ),
            ),
            const SizedBox(width: 24.0),

            // AKČNÍ TLAČÍTKA (Upravit, Smazat)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tlačítko Editovat
                Container(
                  width: 36.0,
                  height: 36.0,
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).colorScheme.outline),
                    borderRadius: BorderRadius.circular(22.0),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.edit_outlined, color: Theme.of(context).colorScheme.primary, size: 18.0),
                    onPressed: () {
                      print('Editovat otázku $id');
                    },
                    padding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(width: 8.0),
                
                // Tlačítko Smazat
                Container(
                  width: 36.0,
                  height: 36.0,
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).colorScheme.outline),
                    borderRadius: BorderRadius.circular(22.0),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error, size: 18.0),
                    onPressed: () {
                      print('Smazat otázku $id');
                    },
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}