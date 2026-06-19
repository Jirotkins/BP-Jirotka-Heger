import 'package:flutter/material.dart';
import '../theme/app_themes.dart';

class QuestionSelectRowWidget extends StatelessWidget {
  final String question;
  final String type;
  final bool isSelected;
  final VoidCallback onToggle;

  const QuestionSelectRowWidget({
    super.key,
    required this.question,
    required this.type,
    required this.isSelected,
    required this.onToggle,
  });

  String _getTypeLabel(String questionType) {
    switch (questionType) {
      case 'SINGLE_CHOICE':
      case 'MULTI_CHOICE': return 'Výběr';
      case 'ORDERING': return 'Seřazení';
      case 'MATCHING': return 'Párování';
      case 'OPEN_TEXT': return 'Otevřená';
      case 'SHORT_ANSWER': return 'Krátká';
      default: return questionType;
    }
  }

  // Pomocná metoda pro barvy štítků podle typu otázky
  Map<String, Color> _getTypeColors(BuildContext context, String questionType) {
    final customColors = Theme.of(context).extension<CustomColors>();
    
    switch (questionType) {
      case 'SINGLE_CHOICE':
      case 'MULTI_CHOICE':
        return {'bg': customColors?.blueBg ?? Theme.of(context).colorScheme.primaryContainer, 'text': customColors?.blueText ?? Theme.of(context).colorScheme.primary};
      case 'ORDERING':
        return {'bg': customColors?.orangeBg ?? Theme.of(context).colorScheme.primaryContainer, 'text': customColors?.orangeText ?? Theme.of(context).colorScheme.primary};
      case 'MATCHING':
        return {'bg': customColors?.purpleBg ?? Theme.of(context).colorScheme.primaryContainer, 'text': customColors?.purpleText ?? Theme.of(context).colorScheme.primary};
      case 'OPEN_TEXT':
        return {'bg': customColors?.greenBg ?? Theme.of(context).colorScheme.primaryContainer, 'text': customColors?.greenText ?? Theme.of(context).colorScheme.primary};
      case 'SHORT_ANSWER':
        return {'bg': customColors?.redBg ?? Theme.of(context).colorScheme.errorContainer, 'text': customColors?.redText ?? Theme.of(context).colorScheme.error};
      default:
        return {'bg': Theme.of(context).colorScheme.surfaceContainerHighest, 'text': Theme.of(context).colorScheme.onSurface};
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryBlue = Theme.of(context).colorScheme.primary;
    final typeColors = _getTypeColors(context, type);
    final displayType = _getTypeLabel(type);

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