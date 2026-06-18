import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/api_client.dart';

class AddNewStudentsPopupWidget extends ConsumerStatefulWidget {
  final int groupId;
  final VoidCallback? onSuccess;

  const AddNewStudentsPopupWidget({
    super.key,
    required this.groupId,
    this.onSuccess,
  });

  @override
  ConsumerState<AddNewStudentsPopupWidget> createState() => _AddNewStudentsPopupWidgetState();
}

class _AddNewStudentsPopupWidgetState extends ConsumerState<AddNewStudentsPopupWidget> {
  late TextEditingController _countController;
  late FocusNode _countFocusNode;
  bool _isSaving = false;
  String? _errorMessage;

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

  Future<void> _addStudents() async {
    final countText = _countController.text.trim();
    final count = int.tryParse(countText);

    if (count == null || count < 1 || count > 100) {
      setState(() => _errorMessage = 'Zadejte platné číslo od 1 do 100.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      
      await apiClient.post('/groups/${widget.groupId}/students/bulk', {
        'prefix': 'student_',
        'count': count,
      });
      
      if (mounted) {
        Navigator.of(context).pop();
        widget.onSuccess?.call();
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
            'Přidat studenty',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.w800, color: Colors.black87),
          ),
          const SizedBox(height: 8.0),
          
          const Text(
            'Kolik nových studentů chcete přidat?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14.0, color: Colors.grey),
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

          TextFormField(
            controller: _countController,
            focusNode: _countFocusNode,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            enabled: !_isSaving,
            decoration: InputDecoration(
              hintText: 'Zadejte počet (max 100)',
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: const Color(0xFFF5F7FA),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide(color: Colors.grey.shade300)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: const BorderSide(color: Color(0xFF0056D2), width: 2.0)),
            ),
          ),
          const SizedBox(height: 24.0),

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
                  onPressed: _isSaving ? null : _addStudents,
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