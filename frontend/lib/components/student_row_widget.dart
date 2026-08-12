import 'package:flutter/material.dart';

/// Vizualizační komponenta pro jeden řádek s údaji studenta v seznamu.
/// 
/// Zobrazuje ID studenta, jeho email/uživatelské jméno a poskytuje
/// akční tlačítka pro úpravu (zatím neimplementováno) nebo smazání studenta.
class StudentRowWidget extends StatelessWidget {
  /// Unikátní identifikátor studenta.
  final int id;
  
  /// Přihlašovací email nebo vygenerované jméno studenta.
  final String studentName;
  
  /// Callback volaný při kliknutí na tlačítko "Smazat".
  final VoidCallback? onDelete;

  const StudentRowWidget({
    super.key,
    required this.id,
    required this.studentName,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Jemné odsazení řádku od okrajů
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.transparent,
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
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
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
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14.0,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),

            // AKČNÍ TLAČÍTKA
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tlačítko Smazat
                IconButton(
                  icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error, size: 18.0),
                  onPressed: onDelete,
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