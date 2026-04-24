import 'package:flutter/material.dart';

class AddNewClassPopupWidget extends StatefulWidget {
  const AddNewClassPopupWidget({super.key});

  @override
  State<AddNewClassPopupWidget> createState() => _AddNewClassPopupWidgetState();
}

class _AddNewClassPopupWidgetState extends State<AddNewClassPopupWidget> {
  // Ovladače pro textová pole
  late TextEditingController _nameController;
  late FocusNode _nameFocusNode;
  late TextEditingController _subjectController;
  late FocusNode _subjectFocusNode;

  // Index vybrané ikony (výchozí 0)
  int _selectedIconIndex = 0;

  // Seznam ikon pro výběr
  final List<IconData> _availableIcons = [
    Icons.menu_book_outlined,
    Icons.calculate_outlined,
    Icons.science_outlined,
    Icons.history_edu_outlined,
    Icons.public_outlined,
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _nameFocusNode = FocusNode();
    _subjectController = TextEditingController();
    _subjectFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    _subjectController.dispose();
    _subjectFocusNode.dispose();
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
            'Přidat novou třídu',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24.0),

          // VSTUP: NÁZEV TŘÍDY
          _buildInputLabel('Název'),
          const SizedBox(height: 6.0),
          _buildTextField(_nameController, _nameFocusNode, 'Zadejte název'),
          
          const SizedBox(height: 16.0),

          // VSTUP: PŘEDMĚT
          _buildInputLabel('Předmět'),
          const SizedBox(height: 6.0),
          _buildTextField(_subjectController, _subjectFocusNode, 'Zadejte předmět'),

          const SizedBox(height: 16.0),

          // VÝBĚR IKONY
          _buildInputLabel('Vyberte ikonu'),
          const SizedBox(height: 10.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_availableIcons.length, (index) {
              final isSelected = _selectedIconIndex == index;
              return InkWell(
                borderRadius: BorderRadius.circular(12.0),
                onTap: () => setState(() => _selectedIconIndex = index),
                child: Container(
                  width: 52.0,
                  height: 52.0,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF0056D2) : Colors.grey.shade300,
                      width: 2.0,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    _availableIcons[index],
                    color: isSelected ? const Color(0xFF0056D2) : Colors.grey,
                    size: 26.0,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 32.0),

          // TLAČÍTKA
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22.0)),
                  ),
                  child: const Text('Zrušit', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    print('Třída ${_nameController.text} uložena!');
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0056D2),
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22.0)),
                    elevation: 0,
                  ),
                  child: const Text('Uložit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Pomocné metody pro čistší build metodu
  Widget _buildInputLabel(String label) {
    return Text(
      label,
      style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600, fontSize: 13.0),
    );
  }

  Widget _buildTextField(TextEditingController controller, FocusNode focusNode, String hint) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14.0),
        filled: true,
        fillColor: const Color(0xFFF5F7FA),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: const BorderSide(color: Color(0xFF3D5AF1), width: 2.0)),
      ),
    );
  }
}