import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/api_client.dart';

class AddNewBankPopupWidget extends ConsumerStatefulWidget {
  final VoidCallback? onSuccess;

  const AddNewBankPopupWidget({
    super.key,
    this.onSuccess,
  });

  @override
  ConsumerState<AddNewBankPopupWidget> createState() => _AddNewBankPopupWidgetState();
}

class _AddNewBankPopupWidgetState extends ConsumerState<AddNewBankPopupWidget> {
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

  Future<void> _saveBank() async {
    final name = _nameController.text.trim();
    final subject = _subjectController.text.trim();

    if (name.isEmpty || subject.isEmpty) {
      setState(() => _errorMessage = 'Vyplňte prosím název i předmět.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      
      // Předmět a vybranou ikonu uložíme do pole description jako JSON string
      final descriptionJson = json.encode({
        'subject': subject,
        'iconIndex': _selectedIconIndex,
      });

      await apiClient.post('/banks', {
        'name': name,
        'description': descriptionJson,
        'is_public': false,
      });
      
      if (mounted) {
        Navigator.of(context).pop();
        widget.onSuccess?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Chyba: ${e.toString()}';
          _isSaving = false;
        });
      }
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
            'Přidat novou banku otázek',
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

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Název', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600, fontSize: 14.0)),
              const SizedBox(height: 6.0),
              TextFormField(
                controller: _nameController,
                focusNode: _nameFocusNode,
                textInputAction: TextInputAction.next,
                enabled: !_isSaving,
                decoration: InputDecoration(
                  hintText: 'Zadejte název',
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 14.0),
                  border: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8.0)),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8.0)),
                  focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFF3D5AF1)), borderRadius: BorderRadius.circular(8.0)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Popis', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600, fontSize: 14.0)),
              const SizedBox(height: 6.0),
              TextFormField(
                controller: _subjectController,
                focusNode: _subjectFocusNode,
                textInputAction: TextInputAction.done,
                enabled: !_isSaving,
                decoration: InputDecoration(
                  hintText: 'Zadejte popis',
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 14.0),
                  border: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8.0)),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8.0)),
                  focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFF3D5AF1)), borderRadius: BorderRadius.circular(8.0)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Vyberte ikonu', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600, fontSize: 14.0)),
              const SizedBox(height: 10.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(_availableIcons.length, (index) {
                  final isSelected = _selectedIconIndex == index;
                  return InkWell(
                    borderRadius: BorderRadius.circular(12.0),
                    onTap: _isSaving ? null : () => setState(() => _selectedIconIndex = index),
                    child: Container(
                      width: 52.0,
                      height: 52.0,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(color: isSelected ? const Color(0xFF0056D2) : Colors.grey.shade300, width: 2.0),
                      ),
                      alignment: Alignment.center,
                      child: Icon(_availableIcons[index], color: isSelected ? const Color(0xFF0056D2) : Colors.grey, size: 26.0),
                    ),
                  );
                }),
              ),
            ],
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
                  onPressed: _isSaving ? null : _saveBank,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0056D2),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22.0)),
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
}