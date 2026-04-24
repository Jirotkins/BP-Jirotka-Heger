import 'package:flutter/material.dart';

class AddNewStudentsPopupWidget extends StatefulWidget {
  const AddNewStudentsPopupWidget({super.key});

  @override
  State<AddNewStudentsPopupWidget> createState() => _AddNewStudentsPopupWidgetState();
}

class _AddNewStudentsPopupWidgetState extends State<AddNewStudentsPopupWidget> {
  // Lokální stavy pro číselné pole
  late TextEditingController _countController;
  late FocusNode _countFocusNode;

  @override
  void initState() {
    super.initState();
    _countController = TextEditingController();
    _countFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _countController.dispose();
    _countFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400.0,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
      ),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // NADPIS
          const Text(
            'Přidat studenty',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8.0),
          
          // PODNADPIS
          const Text(
            'Kolik nových studentů chcete přidat?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.0,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24.0),

          // VSTUPNÍ POLE (POČET)
          TextFormField(
            controller: _countController,
            focusNode: _countFocusNode,
            keyboardType: TextInputType.number, // Otevře číselnou klávesnici
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintText: 'Zadejte počet',
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: const Color(0xFFF5F7FA),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: const BorderSide(color: Color(0xFF0056D2), width: 2.0),
              ),
            ),
          ),
          const SizedBox(height: 24.0),

          // TLAČÍTKA (Zrušit / Uložit)
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22.0),
                    ),
                  ),
                  child: const Text(
                    'Zrušit',
                    style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final count = _countController.text;
                    print('Ukládám $count nových studentů');
                    // Tady bude budoucí logika pro generování kódů/přidání studentů
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0056D2),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22.0),
                    ),
                  ),
                  child: const Text(
                    'Uložit',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}