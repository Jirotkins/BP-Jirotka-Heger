import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/api_client.dart';

class AddNewClassPopupWidget extends ConsumerStatefulWidget {
  final VoidCallback? onSuccess;

  const AddNewClassPopupWidget({super.key, this.onSuccess});

  @override
  ConsumerState<AddNewClassPopupWidget> createState() => _AddNewClassPopupWidgetState();
}

class _AddNewClassPopupWidgetState extends ConsumerState<AddNewClassPopupWidget> {
  late TextEditingController _nameController;
  late FocusNode _nameFocusNode;
  late TextEditingController _subjectController;
  late FocusNode _subjectFocusNode;

  int _selectedIconIndex = 0;
  bool _isSaving = false;
  String? _errorMessage;

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

  Future<void> _saveClass() async {
    if (_nameController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Název třídy je povinný.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      
      final descriptionData = {
        "subject": _subjectController.text.trim().isEmpty 
            ? 'Předmět neuveden' 
            : _subjectController.text.trim(),
        "icon": _availableIcons[_selectedIconIndex].codePoint.toString(),
      };

      // Voláme API POST /groups
      await apiClient.post('/groups', {
        'name': _nameController.text.trim(),
        'description': jsonEncode(descriptionData),
      });
      
      if (mounted) {
        Navigator.of(context).pop();
        widget.onSuccess?.call(); // Upozorníme nadřazený widget na úspěch
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Chyba: ${e.toString()}';
        _isSaving = false;
      });
    }
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
          const Text(
            'Přidat novou třídu',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.w800, color: Colors.black87),
          ),
          const SizedBox(height: 24.0),

          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
              child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 13)),
            ),
            const SizedBox(height: 16.0),
          ],

          _buildInputLabel('Název'),
          const SizedBox(height: 6.0),
          _buildTextField(_nameController, _nameFocusNode, 'Zadejte název (např. 1.A)'),
          
          const SizedBox(height: 16.0),

          _buildInputLabel('Předmět'),
          const SizedBox(height: 6.0),
          _buildTextField(_subjectController, _subjectFocusNode, 'Zadejte předmět (volitelné)'),

          const SizedBox(height: 16.0),

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

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
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
                  onPressed: _isSaving ? null : _saveClass,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0056D2),
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22.0)),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Uložit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600, fontSize: 13.0));
  }

  Widget _buildTextField(TextEditingController controller, FocusNode focusNode, String hint) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      enabled: !_isSaving,
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