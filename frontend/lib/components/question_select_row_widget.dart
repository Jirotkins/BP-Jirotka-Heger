import 'package:flutter/material.dart';
import '../theme/app_themes.dart';

class QuestionSelectRowWidget extends StatefulWidget {
  final String question;
  final String type;

  const QuestionSelectRowWidget({
    super.key,
    required this.question,
    required this.type,
  });

  @override
  State<QuestionSelectRowWidget> createState() => _QuestionSelectRowWidgetState();
}

class _QuestionSelectRowWidgetState extends State<QuestionSelectRowWidget> {
  // Lokální stav výběru
  bool _isSelected = false;

  // Pomocná metoda pro barvy štítků podle typu otázky
  Map<String, Color> _getTypeColors(BuildContext context, String questionType) {
    final customColors = Theme.of(context).extension<CustomColors>();
    
    switch (questionType) {
      case 'Výběr':
        return {'bg': Theme.of(context).colorScheme.primaryContainer, 'text': Theme.of(context).colorScheme.primary};
      case 'Seřazení':
        return {'bg': customColors?.orangeBg ?? Theme.of(context).colorScheme.primaryContainer, 'text': customColors?.orangeText ?? Theme.of(context).colorScheme.primary};
      case 'Párování':
        return {'bg': customColors?.purpleBg ?? Theme.of(context).colorScheme.primaryContainer, 'text': customColors?.purpleText ?? Theme.of(context).colorScheme.primary};
      case 'Otevřená':
        return {'bg': customColors?.greenBg ?? Theme.of(context).colorScheme.primaryContainer, 'text': customColors?.greenText ?? Theme.of(context).colorScheme.primary};
      case 'Krátká':
        return {'bg': Theme.of(context).colorScheme.errorContainer, 'text': Theme.of(context).colorScheme.error};
      default:
        return {'bg': Theme.of(context).colorScheme.surface, 'text': Theme.of(context).colorScheme.onSurface};
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryBlue = Theme.of(context).colorScheme.primary;
    final typeColors = _getTypeColors(context, widget.type);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: InkWell(
        onTap: () {
          setState(() {
            _isSelected = !_isSelected;
          });
        },
        borderRadius: BorderRadius.circular(16.0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: _isSelected ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: _isSelected ? primaryBlue : Theme.of(context).colorScheme.outline,
              width: _isSelected ? 2.0 : 1.0,
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
                  widget.type,
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
                  widget.question,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: _isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 14.0,
                  ),
                ),
              ),

              // CHECKBOX / RADIO INDIKÁTOR
              const SizedBox(width: 8.0),
              Icon(
                _isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                color: _isSelected ? primaryBlue : Theme.of(context).colorScheme.outline,
                size: 24.0,
              ),
            ],
          ),
        ),
      ),
    );
  }
}