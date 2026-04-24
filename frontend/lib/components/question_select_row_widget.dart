import 'package:flutter/material.dart';

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
  Map<String, Color> _getTypeColors(String questionType) {
    switch (questionType) {
      case 'Výběr':
        return {'bg': const Color(0xFFEEF2FF), 'text': const Color(0xFF3D5AF1)};
      case 'Seřazení':
        return {'bg': const Color(0xFFFFF3E0), 'text': const Color(0xFFFFB300)};
      case 'Párování':
        return {'bg': const Color(0xFFDED1F1), 'text': const Color(0xFF9100FF)};
      case 'Otevřená':
        return {'bg': const Color(0xFFE8F5E9), 'text': const Color(0xFF43A047)};
      case 'Krátká':
        return {'bg': const Color(0xFFF8DADA), 'text': const Color(0xFFF85353)};
      default:
        return {'bg': Colors.grey.shade100, 'text': Colors.black87};
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = const Color(0xFF3D5AF1);
    final typeColors = _getTypeColors(widget.type);

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
            color: _isSelected ? const Color(0xFFF0F4FA) : Colors.white,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(
              color: _isSelected ? primaryBlue : Colors.grey.shade200,
              width: 1.5,
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
                  color: typeColors['bg'],
                  borderRadius: BorderRadius.circular(22.0),
                ),
                alignment: Alignment.center,
                child: Text(
                  widget.type,
                  style: TextStyle(
                    color: typeColors['text'],
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
                    color: Colors.black87,
                    fontWeight: _isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 14.0,
                  ),
                ),
              ),

              // CHECKBOX / RADIO INDIKÁTOR
              const SizedBox(width: 8.0),
              Icon(
                _isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                color: _isSelected ? primaryBlue : Colors.grey.shade300,
                size: 24.0,
              ),
            ],
          ),
        ),
      ),
    );
  }
}