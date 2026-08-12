import 'package:flutter/material.dart';
import '../utils/question_type_helper.dart';

/// Interaktivní řádek pro výběr otázky ze seznamu (banky).
///
/// Zobrazuje znění otázky, její typ (ve formě barevného štítku) a
/// přepínač (Switch), který indikuje, zda bude otázka přidána do testu.
class QuestionSelectRowWidget extends StatelessWidget {
  /// Znění otázky (např. "Jaké je hlavní město ČR?").
  final String question;
  
  /// Identifikátor typu otázky (např. "multi_choice").
  final String type;
  
  /// Indikuje, zda je aktuální otázka vybrána (Switch je zapnutý).
  final bool isSelected;
  
  /// Callback, který se zavolá při změně stavu přepínače.
  final VoidCallback onToggle;

  const QuestionSelectRowWidget({
    super.key,
    required this.question,
    required this.type,
    required this.isSelected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final Color primaryBlue = Theme.of(context).colorScheme.primary;
    final typeColors = QuestionTypeHelper.getColors(context, type);
    final displayType = QuestionTypeHelper.getShortLabel(type);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(16.0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: isSelected ? primaryBlue : Theme.of(context).colorScheme.outline,
              width: isSelected ? 2.0 : 1.0,
            ),
          ),
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // ŠTÍTEK TYPU OTÁZKY
              Container(
                width: 85.0,
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                decoration: BoxDecoration(
                  color: typeColors['bg']!,
                  borderRadius: BorderRadius.circular(22.0),
                ),
                alignment: Alignment.center,
                child: Text(
                  displayType,
                  style: TextStyle(
                    color: typeColors['text']!,
                    fontWeight: FontWeight.w600,
                    fontSize: 11.0,
                  ),
                ),
              ),
              const SizedBox(width: 16.0),

              // TEXT OTÁZKY
              Expanded(
                child: Text(
                  question,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 14.0,
                  ),
                ),
              ),

              // CHECKBOX / RADIO INDIKÁTOR
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: isSelected 
                  ? Icon(Icons.check_circle_rounded, color: primaryBlue, size: 22.0)
                  : Icon(Icons.radio_button_unchecked_rounded, color: Theme.of(context).colorScheme.outline, size: 22.0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}