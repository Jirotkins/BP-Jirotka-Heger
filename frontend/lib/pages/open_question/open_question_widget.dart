import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../components/page_header_widget.dart';
import '../../services/api_client.dart';
import '../../theme/app_themes.dart';

class OpenQuestionWidget extends ConsumerStatefulWidget {
  const OpenQuestionWidget({super.key});

  @override
  ConsumerState<OpenQuestionWidget> createState() => _OpenQuestionWidgetState();
}

class _OpenQuestionWidgetState extends ConsumerState<OpenQuestionWidget> {
  // Stavy pro textové pole znění otázky
  late TextEditingController _questionTextController;
  late FocusNode _questionFocusNode;

  @override
  void initState() {
    super.initState();
    _questionTextController = TextEditingController();
    _questionFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _questionTextController.dispose();
    _questionFocusNode.dispose();
    super.dispose();
  }

  Future<bool> _saveQuestion(int bankId) async {
    if (_questionTextController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Zadejte znění otázky'), backgroundColor: Theme.of(context).colorScheme.error));
      return false;
    }

    try {
      final apiClient = ref.read(apiClientProvider);
      
      final requestData = {
        "text": _questionTextController.text.trim(),
        "type": "OPEN_TEXT",
        "default_points": 1,
        "answers": [],
      };

      await apiClient.post('/banks/$bankId/questions', requestData);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Otázka uložena'), backgroundColor: Colors.green));
      }
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Chyba při ukládání: $e'), backgroundColor: Theme.of(context).colorScheme.error));
      }
      return false;
    }
  }

  // --- FUNKCE PRO ZOBRAZENÍ NÁHLEDU STUDENTA ---
  void _showStudentPreview() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Center(
            child: Container(
              width: 375.0,
              height: 700.0,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor, 
                borderRadius: BorderRadius.circular(36.0),
                border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 10.0), 
                boxShadow: [BoxShadow(color: Theme.of(context).shadowColor.withValues(alpha: 0.1), blurRadius: 20.0, offset: const Offset(0, 10))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26.0),
                child: Scaffold(
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  appBar: AppBar(
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    elevation: 0,
                    centerTitle: true,
                    title: Text('Ukázka testu', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.bold)),
                    automaticallyImplyLeading: false,
                    actions: [
                      IconButton(icon: Icon(Icons.close, color: Theme.of(context).colorScheme.onSurface), onPressed: () => Navigator.pop(context))
                    ],
                  ),
                  body: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _questionTextController.text.isEmpty ? '[Zde bude znění otázky...]' : _questionTextController.text,
                          style: GoogleFonts.inter(fontSize: 18.0, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                        ),
                        const SizedBox(height: 24.0),
                        
                        // Simulace velkého textového pole pro dlouhou odpověď
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(12.0),
                              border: Border.all(color: Theme.of(context).colorScheme.outline),
                              boxShadow: [
                                BoxShadow(color: Theme.of(context).shadowColor.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))
                              ]
                            ),
                            alignment: Alignment.topLeft,
                            child: Text(
                              'Zde bude mít student k dispozici velké textové pole, kam může napsat několik odstavců textu...', 
                              style: GoogleFonts.inter(color: Theme.of(context).colorScheme.secondary, height: 1.5)
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 24.0),

                        // Falešné tlačítko
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            minimumSize: const Size(double.infinity, 48.0),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
                          ),
                          child: Text('Další otázka', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // CHYTÁNÍ DAT Z MENU
    final args = GoRouterState.of(context).extra as Map<String, dynamic>?;
    final String targetName = args?['targetName'] ?? 'Neznámá banka';
    final int bankId = args?['bankId'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        
        // --- DYNAMICKÁ HLAVIČKA ---
        PageHeaderWidget(
          title: 'Tvorba: $targetName',
          actions: [
            ElevatedButton.icon(
              onPressed: _showStudentPreview, 
              icon: const Icon(Icons.visibility_outlined, size: 18),
              label: Text('Pohled studenta', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.surface,
                foregroundColor: Theme.of(context).colorScheme.primary,
                minimumSize: const Size(0, 40),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5)
                ),
                elevation: 0,
              ),
            ),
            const SizedBox(width: 12.0),

            ElevatedButton.icon(
              onPressed: () async {
                final success = await _saveQuestion(bankId);
                if (success && context.mounted) {
                  context.pop();
                }
              },
              icon: const Icon(Icons.save_outlined, size: 18),
              label: Text('Uložit', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.surface,
                minimumSize: const Size(0, 40),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
              ),
            ),
          ],
        ),

        // --- HLAVNÍ PLOCHA EDITORU ---
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  // ŠTÍTEK TYPU OTÁZKY
                  Text('TYP OTÁZKY', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.secondary, letterSpacing: 1.2, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8.0),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).extension<CustomColors>()?.greenBg ?? Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20.0),
                      border: Border.all(color: Theme.of(context).colorScheme.outline, width: 1.0),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.notes_rounded, color: Theme.of(context).extension<CustomColors>()?.greenText ?? Theme.of(context).colorScheme.primary, size: 16),
                        const SizedBox(width: 8),
                        Text('Otevřená otázka', style: GoogleFonts.inter(color: Theme.of(context).extension<CustomColors>()?.greenText ?? Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32.0),

                  // POLE PRO ZNĚNÍ OTÁZKY
                  Text('ZNĚNÍ OTÁZKY', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.secondary, letterSpacing: 1.2, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8.0),
                  TextFormField(
                    controller: _questionTextController,
                    focusNode: _questionFocusNode,
                    maxLines: 4,
                    minLines: 3,
                    style: GoogleFonts.inter(fontSize: 16, color: Theme.of(context).colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: 'Napište zde znění otázky...',
                      hintStyle: GoogleFonts.inter(color: Theme.of(context).colorScheme.secondary),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      contentPadding: const EdgeInsets.all(20.0),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide(color: Theme.of(context).colorScheme.outline)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide(color: Theme.of(context).colorScheme.outline)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5)),
                    ),
                  ),
                  
                  const SizedBox(height: 24.0),

                  // UPLOAD OBRÁZKU
                  Container(
                    height: 120.0,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(color: Theme.of(context).colorScheme.outline, width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cloud_upload_outlined, color: Theme.of(context).colorScheme.secondary, size: 36.0),
                        const SizedBox(height: 8.0),
                        Text('Přetáhněte obrázek nebo schéma (volitelné)', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.secondary, fontSize: 14.0)),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 48.0),
                  Divider(color: Theme.of(context).colorScheme.outline, height: 1),
                  const SizedBox(height: 32.0),

                  // INFORMAČNÍ BOX
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(color: Theme.of(context).colorScheme.outline, width: 1.0),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded, color: Theme.of(context).colorScheme.primary, size: 24),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Vyhodnocení otevřené otázky', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface, fontSize: 14)),
                              const SizedBox(height: 4),
                              Text(
                                'U otevřených otázek student odpovídá volným textem. Protože systém nedokáže automaticky posoudit správnost eseje či rozsáhlého textu, bude vyžadována vaše manuální kontrola a obodování po odevzdání testu.', 
                                style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface, fontSize: 13, height: 1.5)
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40.0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}