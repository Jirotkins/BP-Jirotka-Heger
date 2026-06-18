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
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16.0),
          ),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Studenti úspěšně přidáni',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface),
              ),
              const SizedBox(height: 8.0),
              Text(
                'Pečlivě si uložte tyto údaje. Hesla se znovu nikde nezobrazí!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14.0, color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24.0),
              Flexible(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).colorScheme.outline),
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
                        side: BorderSide(color: Theme.of(context).colorScheme.outline),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                        foregroundColor: Theme.of(context).colorScheme.onSurface,
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
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                      ),
                      child: Text('Zavřít', style: TextStyle(color: Theme.of(context).colorScheme.surface, fontWeight: FontWeight.bold)),
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
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16.0),
      ),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Přidat studenty',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface),
          ),
          const SizedBox(height: 8.0),
          
          Text(
            'Zadejte předponu a kolik nových studentů chcete přidat. Následně se vám zobrazí jejich přihlašovací údaje.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14.0, color: Theme.of(context).colorScheme.secondary),
          ),
          const SizedBox(height: 24.0),

          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.errorContainer, borderRadius: BorderRadius.circular(8)),
              child: Text(_errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer, fontSize: 13)),
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
              labelStyle: TextStyle(color: Theme.of(context).colorScheme.secondary),
              filled: true,
              fillColor: Theme.of(context).scaffoldBackgroundColor,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide(color: Theme.of(context).colorScheme.outline)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide(color: Theme.of(context).colorScheme.outline)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2.0)),
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
              labelStyle: TextStyle(color: Theme.of(context).colorScheme.secondary),
              filled: true,
              fillColor: Theme.of(context).scaffoldBackgroundColor,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide(color: Theme.of(context).colorScheme.outline)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide(color: Theme.of(context).colorScheme.outline)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2.0)),
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
                    side: BorderSide(color: Theme.of(context).colorScheme.outline),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                  ),
                  child: Text('Zrušit', style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _addStudents,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                  ),
                  child: _isSaving
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
}