import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_themes.dart';
import '../utils/question_type_helper.dart';

class QuestionRowWidget extends StatelessWidget {
  final int id;
  final String question;
  final String type;
  final int bankId;
  final String targetName;
  final Map<String, dynamic>? questionData;
  final VoidCallback? onDelete;

  const QuestionRowWidget({
    super.key,
    required this.id,
    required this.question,
    required this.type,
    this.bankId = 0,
    this.targetName = 'Neznámá banka',
    this.questionData,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // Získáme barvy pro aktuální typ otázky
    final typeColors = QuestionTypeHelper.getColors(context, type);
    final displayType = QuestionTypeHelper.getLabel(type);

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
                displayType,
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
                      final route = QuestionTypeHelper.getRouteForType(type);
                      context.push(route, extra: {
                        'targetName': targetName,
                        'bankId': bankId,
                        'questionData': questionData,
                      });
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
                      if (onDelete != null) {
                        onDelete!();
                      }
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