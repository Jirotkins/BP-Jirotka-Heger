import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../components/page_header_widget.dart';
import '../../components/image_upload_widget.dart';
import '../../components/student_preview_dialog.dart';
import '../../services/api_client.dart';
import '../questions_overview/questions_overview_provider.dart';

/// Editor pro vytvoření "Otevřené otázky".
/// Studentům se při testu zobrazí rozsáhlé textové pole pro vypracování odpovědi (esej).
/// Tento typ otázky nelze automaticky vyhodnotit.
class OpenQuestionPage extends ConsumerStatefulWidget {
  const OpenQuestionPage({super.key});

  @override
  ConsumerState<OpenQuestionPage> createState() => _OpenQuestionPageState();
}

class _OpenQuestionPageState extends ConsumerState<OpenQuestionPage> {
  // Stavy pro textové pole znění otázky
  late TextEditingController _questionTextController;
  late FocusNode _questionFocusNode;
  bool _isInitialized = false;
  String? _imageBase64;

  @override
  void initState() {
    super.initState();
    _questionTextController = TextEditingController();
    _questionFocusNode = FocusNode();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final args = GoRouterState.of(context).extra as Map<String, dynamic>?;
      final questionData = args?['questionData'] as Map<String, dynamic>?;
      
      if (questionData != null) {
        _questionTextController.text = questionData['text'] ?? '';
        _imageBase64 = questionData['image_url'];
      }
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _questionTextController.dispose();
    _questionFocusNode.dispose();
    super.dispose();
  }

  Future<bool> _saveQuestion(int bankId, {int? questionId}) async {
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
        "image_url": _imageBase64,
        "answers": [],
      };

      if (questionId != null) {
        await apiClient.put('/banks/$bankId/questions/$questionId', requestData);
      } else {
        await apiClient.post('/banks/$bankId/questions', requestData);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(questionId != null ? 'Otázka upravena' : 'Otázka uložena'), backgroundColor: Colors.green));
      }
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Chyba při ukládání: $e'), backgroundColor: Theme.of(context).colorScheme.error));
      }
      return false;
    }
  }

  /// Zobrazí modální okno simulující pohled studenta na mobilním zařízení.
  /// Využívá komponentu [StudentPreviewDialog].
  void _showStudentPreview() {
    showDialog(
      context: context,
      builder: (context) {
        return StudentPreviewDialog(
          questionText: _questionTextController.text,
          imageBase64: _imageBase64,
          subtitle: 'Napište odpověď:',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                  ),
                  alignment: Alignment.topLeft,
                  child: Text(
                    'Vaše odpověď...', 
                    style: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.secondary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
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
    final Map<String, dynamic>? questionData = args?['questionData'];
    final bool isEdit = questionData != null;
    final int? questionId = questionData?['question_id'] ?? questionData?['id'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        
        // --- DYNAMICKÁ HLAVIČKA ---
        PageHeaderWidget(
          title: isEdit ? 'Úprava otázky' : 'Tvorba: $targetName',
          showBackButton: true,
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
                final success = await _saveQuestion(bankId, questionId: questionId);
                if (success && context.mounted) {
                  ref.read(questionsOverviewProvider.notifier).refresh();
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
                      color: const Color(0xFFE8F5E9), // Lehce zelené
                      borderRadius: BorderRadius.circular(20.0),
                      border: Border.all(color: Theme.of(context).colorScheme.outline, width: 1.0),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.notes_rounded, color: Color(0xFF2E7D32), size: 16),
                        const SizedBox(width: 8),
                        Text('Otevřená otázka', style: GoogleFonts.inter(color: const Color(0xFF2E7D32), fontWeight: FontWeight.w600, fontSize: 13)),
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
                  ImageUploadWidget(
                    initialImageUrl: _imageBase64,
                    onImageSelected: (base64DataUrl) {
                      setState(() {
                        _imageBase64 = base64DataUrl;
                      });
                    },
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