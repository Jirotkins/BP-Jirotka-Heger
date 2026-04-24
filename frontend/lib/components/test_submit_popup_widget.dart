import 'package:flutter/material.dart';

class TestSubmitPopupWidget extends StatelessWidget {
  final int answeredQuestions;
  final int totalQuestions;

  // Ukázková data
  const TestSubmitPopupWidget({
    super.key,
    this.answeredQuestions = 20, 
    this.totalQuestions = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent, // Průhledné kvůli zaobleným rohům Containeru
      insetPadding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        width: 340.0,
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(24.0),
          boxShadow: const [
            BoxShadow(
              blurRadius: 16.0,
              color: Colors.black12,
              offset: Offset(0, 8),
            )
          ],
        ),
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // NADPIS A STAV
            const Text(
              'Opravdu chcete odevzdat test?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFFC62828), // Tmavě červená
              ),
            ),
            const SizedBox(height: 16.0),
            Text(
              'Vyplnili jste $answeredQuestions / $totalQuestions otázek',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.w500,
                color: Colors.grey, 
              ),
            ),
            
            const SizedBox(height: 32.0),

            // TLAČÍTKA
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // TLAČÍTKO "ZPĚT K TESTU"
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(), // Skryje dialog
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF3D5AF1),
                    side: const BorderSide(color: Color(0xFF3D5AF1), width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22.0),
                    ),
                  ),
                  child: const Text(
                    'Zpět k testu',
                    style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                  ),
                ),
                
                const SizedBox(height: 16.0),
                
                // TLAČÍTKO "ODEVZDAT K HODNOCENÍ"
                ElevatedButton(
                  onPressed: () {
                    print('Test byl odevzdán!');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3D5AF1),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22.0),
                    ),
                  ),
                  child: const Text(
                    'Odevzdat k hodnocení',
                    style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
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