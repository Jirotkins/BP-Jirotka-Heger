import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/api_client.dart';
import '../../utils/download_helper.dart';

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
  late TextEditingController _prefixController;
  late FocusNode _prefixFocusNode;
  late TextEditingController _countController;
  late FocusNode _countFocusNode;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _prefixController = TextEditingController();
    _prefixFocusNode = FocusNode();
    _countController = TextEditingController();
    _countFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _prefixController.dispose();
    _prefixFocusNode.dispose();
    _countController.dispose();
    _countFocusNode.dispose();
    super.dispose();
  }

  Future<void> _addStudents() async {
    final prefix = _prefixController.text.trim();
    final countText = _countController.text.trim();
    final count = int.tryParse(countText);

    if (prefix.isEmpty) {
      setState(() => _errorMessage = 'Zadejte prosím předponu.');
      return;
    }

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
      
      final response = await apiClient.post('/groups/${widget.groupId}/students/bulk', {
        'prefix': prefix,
        'count': count,
      });
      
      if (mounted) {
        setState(() => _isSaving = false);
        if (response is String) {
          _showCredentialsDialog(context, response);
        } else {
          Navigator.of(context).pop();
          widget.onSuccess?.call();
        }
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

  void _showCredentialsDialog(BuildContext context, String csvData) {
    final lines = csvData.trim().split('\n');
    // Přeskočíme hlavičku a načteme data
    final credentials = lines.skip(1).map((line) {
      final parts = line.split(',');
      if (parts.length >= 3) {
        return {'email': parts[0].trim(), 'login': parts[1].trim(), 'password': parts[2].trim()};
      }
      return null;
    }).where((e) => e != null).cast<Map<String, String>>().toList();

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        elevation: 0,
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Container(
          width: 500.0,
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
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
                'Studenti úspěšně přidáni',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.w800, color: Colors.black87),
              ),
              const SizedBox(height: 8.0),
              const Text(
                'Pečlivě si uložte tyto údaje. Hesla se znovu nikde nezobrazí!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14.0, color: Colors.red, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24.0),
              Flexible(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: credentials.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final c = credentials[index];
                      return ListTile(
                        title: SelectableText(c['login']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: SelectableText(c['email']!),
                        trailing: SelectableText(c['password']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24.0),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => downloadCsv(csvData, 'studenti_hesla.csv'),
                      icon: const Icon(Icons.download, size: 18),
                      label: const Text('Stáhnout .csv', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22.0)),
                        foregroundColor: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop(); 
                        Navigator.of(context).pop(); 
                        widget.onSuccess?.call(); 
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0056D2),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22.0)),
                      ),
                      child: const Text('Zavřít', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
            'Zadejte předponu a kolik nových studentů chcete přidat. Následně se vám zobrazí jejich přihlašovací údaje.',
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
            controller: _prefixController,
            focusNode: _prefixFocusNode,
            textInputAction: TextInputAction.next,
            enabled: !_isSaving,
            decoration: InputDecoration(
              labelText: 'Předpona (např. matika8)',
              labelStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: const Color(0xFFF5F7FA),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide(color: Colors.grey.shade300)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: const BorderSide(color: Color(0xFF0056D2), width: 2.0)),
            ),
          ),
          const SizedBox(height: 16.0),

          TextFormField(
            controller: _countController,
            focusNode: _countFocusNode,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            enabled: !_isSaving,
            decoration: InputDecoration(
              labelText: 'Zadejte počet (max 100)',
              labelStyle: const TextStyle(color: Colors.grey),
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