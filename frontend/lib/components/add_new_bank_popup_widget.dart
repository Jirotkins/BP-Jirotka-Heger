import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../pages/bank_overview/bank_overview_provider.dart';

class AddNewBankPopupWidget extends ConsumerStatefulWidget {
  final int? bankId;
  final String? initialName;
  final String? initialSubject;
  final int? initialIconIndex;

  const AddNewBankPopupWidget({
    super.key,
    this.bankId,
    this.initialName,
    this.initialSubject,
    this.initialIconIndex,
  });

  @override
  ConsumerState<AddNewBankPopupWidget> createState() => _AddNewBankPopupWidgetState();
}

class _AddNewBankPopupWidgetState extends ConsumerState<AddNewBankPopupWidget> {
  late TextEditingController _nameController;
  late FocusNode _nameFocusNode;
  late TextEditingController _subjectController;
  late FocusNode _subjectFocusNode;

  late int _selectedIconIndex;
  String? _localError;

  bool get _isEditing => widget.bankId != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _nameFocusNode = FocusNode();
    _subjectController = TextEditingController(text: widget.initialSubject ?? '');
    _subjectFocusNode = FocusNode();
    _selectedIconIndex = widget.initialIconIndex ?? 0;
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
    if (_nameController.text.trim().isEmpty) {
      setState(() => _localError = 'Název banky je povinný.');
      return;
    }

    setState(() => _localError = null);
    
    final notifier = ref.read(bankOverviewProvider.notifier);
    
    if (_isEditing) {
      await notifier.updateBank(
        widget.bankId!,
        _nameController.text.trim(),
        _subjectController.text.trim(),
        _selectedIconIndex,
      );
    } else {
      await notifier.addBank(
        _nameController.text.trim(),
        _subjectController.text.trim(),
        _selectedIconIndex,
      );
    }
    
    if (mounted && ref.read(bankOverviewProvider).errorMessage == null) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bankOverviewProvider);
    final notifier = ref.read(bankOverviewProvider.notifier);
    final errorToShow = _localError ?? state.errorMessage;
    final availableIcons = notifier.availableIcons;

    return Container(
      width: 400.0,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16.0),
      ),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _isEditing ? 'Upravit banku' : 'Vytvořit novou banku',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface),
          ),
          const SizedBox(height: 24.0),

          if (errorToShow != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.errorContainer, borderRadius: BorderRadius.circular(8)),
              child: Text(errorToShow, style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer, fontSize: 13)),
            ),
            const SizedBox(height: 16.0),
          ],

          _buildInputLabel('Název'),
          const SizedBox(height: 6.0),
          _buildTextField(_nameController, _nameFocusNode, 'Zadejte název (např. Biologie 8. třída)', state.isLoading),
          
          const SizedBox(height: 16.0),

          _buildInputLabel('Předmět'),
          const SizedBox(height: 6.0),
          _buildTextField(_subjectController, _subjectFocusNode, 'Zadejte předmět (volitelné)', state.isLoading),

          const SizedBox(height: 16.0),

          _buildInputLabel('Vyberte ikonu'),
          const SizedBox(height: 10.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(availableIcons.length, (index) {
              final isSelected = _selectedIconIndex == index;
              return InkWell(
                borderRadius: BorderRadius.circular(10.0),
                onTap: () => setState(() => _selectedIconIndex = index),
                child: Container(
                  width: 52.0,
                  height: 52.0,
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(
                      color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline,
                      width: isSelected ? 2.0 : 1.0,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    availableIcons[index],
                    color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.secondary,
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
                  onPressed: state.isLoading ? null : () {
                    notifier.clearError();
                    Navigator.of(context).pop();
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    side: BorderSide(color: Theme.of(context).colorScheme.outline),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('Zrušit', style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: ElevatedButton(
                  onPressed: state.isLoading ? null : _saveBank,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: state.isLoading
                      ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Theme.of(context).colorScheme.surface, strokeWidth: 2))
                      : Text('Uložit', style: TextStyle(color: Theme.of(context).colorScheme.surface, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Text(label, style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.w600, fontSize: 13.0));
  }

  Widget _buildTextField(TextEditingController controller, FocusNode focusNode, String hint, bool isSaving) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      enabled: !isSaving,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 14.0),
        filled: true,
        fillColor: Theme.of(context).scaffoldBackgroundColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide(color: Theme.of(context).colorScheme.outline)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide(color: Theme.of(context).colorScheme.outline)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2.0)),
      ),
    );
  }
}