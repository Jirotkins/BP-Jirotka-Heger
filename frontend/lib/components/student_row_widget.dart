import 'package:flutter/material.dart';

class StudentRowWidget extends StatelessWidget {
  final int id;
  final String studentName;

  const StudentRowWidget({
    super.key,
    required this.id,
    required this.studentName,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Jemné odsazení řádku od okrajů
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Row(
          children: [
            // ID STUDENTA (Fixní šířka pro zarovnání)
            SizedBox(
              width: 45.0,
              child: Text(
                id.toString(),
                style: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.0,
                ),
              ),
            ),

            // JMÉNO STUDENTA
            Expanded(
              child: Text(
                studentName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14.0,
                  color: Colors.black87,
                ),
              ),
            ),

            // AKČNÍ TLAČÍTKA (Editovat a Smazat)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tlačítko Upravit
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Color(0xFF3D5AF1), size: 18.0),
                  onPressed: () => print('Upravit studenta: $studentName'),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8.0),
                  tooltip: 'Upravit',
                ),
                // Tlačítko Smazat
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18.0),
                  onPressed: () => print('Smazat studenta: $id'),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8.0),
                  tooltip: 'Odebrat ze třídy',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}