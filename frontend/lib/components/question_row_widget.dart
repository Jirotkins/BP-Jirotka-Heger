import 'package:flutter/material.dart';

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

  // Pomocná metoda pro čisté určení barev štítku na základě typu otázky
  // Vrací Mapu s barvou pozadí (bg) a barvou textu (text)
  Map<String, Color> _getTypeColors(String questionType) {
    switch (questionType) {
      case 'Výběr z možností':
        return {'bg': const Color(0xFFEEF2FF), 'text': const Color(0xFF3D5AF1)};
      case 'Seřazení':
        return {'bg': const Color(0xFFFFF3E0), 'text': const Color(0xFFFFB300)};
      case 'Párování':
        return {'bg': const Color(0xFFDED1F1), 'text': const Color(0xFF9100FF)};
      case 'Otevřená':
        return {'bg': const Color(0xFFE8F5E9), 'text': const Color(0xFF43A047)};
      case 'Krátká odpověď':
        return {'bg': const Color(0xFFF8DADA), 'text': const Color(0xFFF85353)};
      default:
        return {'bg': Colors.grey.shade100, 'text': Colors.black87};
    }
  }

  @override
  Widget build(BuildContext context) {
    // Získáme barvy pro aktuální typ otázky
    final typeColors = _getTypeColors(type);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white, // Původně primaryBackground
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
                style: const TextStyle(
                  color: Colors.grey,
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
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14.0,
                  color: Colors.black87,
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
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(22.0),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Color(0xFF3D5AF1), size: 18.0),
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
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(22.0),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18.0),
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