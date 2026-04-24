import 'package:flutter/material.dart';

class AddNewBankPopupWidget extends StatefulWidget {
  const AddNewBankPopupWidget({super.key});

  @override
  State<AddNewBankPopupWidget> createState() => _AddNewBankPopupWidgetState();
}

class _AddNewBankPopupWidgetState extends State<AddNewBankPopupWidget> {
  // Stavy pro textová pole
  late TextEditingController _nameController;
  late FocusNode _nameFocusNode;
  
  late TextEditingController _subjectController;
  late FocusNode _subjectFocusNode;

  // Stav pro výběr ikony (výchozí je první ikona: 0)
  int _selectedIconIndex = 0;

  // Seznam ikon, ze kterých může učitel vybírat
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
        crossAxisAlignment: CrossAxisAlignment.stretch, // Rozáhne vše na šířku
        children: [
          // NADPIS
          const Text(
            'Přidat novou banku otázek',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20.0, 
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24.0),

          // VSTUP: NÁZEV BANKY
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Název',
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600, fontSize: 14.0),
              ),
              const SizedBox(height: 6.0),
              TextFormField(
                controller: _nameController,
                focusNode: _nameFocusNode,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  hintText: 'Zadejte název',
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey.shade50, // Původně primaryBackground
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 14.0),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFF3D5AF1)),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),

          // VSTUP: PŘEDMĚT
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Předmět',
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600, fontSize: 14.0),
              ),
              const SizedBox(height: 6.0),
              TextFormField(
                controller: _subjectController,
                focusNode: _subjectFocusNode,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: 'Zadejte předmět',
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 14.0),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFF3D5AF1)),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),

          // VÝBĚR IKONY (Dynamicky generováno z pole)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Vyberte ikonu',
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600, fontSize: 14.0),
              ),
              const SizedBox(height: 10.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(_availableIcons.length, (index) {
                  final isSelected = _selectedIconIndex == index;
                  return InkWell(
                    borderRadius: BorderRadius.circular(12.0),
                    onTap: () {
                      setState(() {
                        _selectedIconIndex = index;
                      });
                    },
                    child: Container(
                      width: 52.0,
                      height: 52.0,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
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
            ],
          ),
          const SizedBox(height: 32.0),

          // SPODNÍ TLAČÍTKA (Zrušit / Uložit)
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(), // Zavře popup
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
                    print('Nová banka uložena!');
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