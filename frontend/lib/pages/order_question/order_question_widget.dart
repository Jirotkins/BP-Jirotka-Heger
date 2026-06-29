import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../components/page_header_widget.dart';
import '../../services/api_client.dart';
import '../../theme/app_themes.dart';

class OrderQuestionWidget extends ConsumerStatefulWidget {
  const OrderQuestionWidget({super.key});

  @override
  ConsumerState<OrderQuestionWidget> createState() => _OrderQuestionWidgetState();
}

class _OrderQuestionWidgetState extends ConsumerState<OrderQuestionWidget> {
  // Stav pro znění otázky
  late TextEditingController _questionTextController;
  late FocusNode _questionFocusNode;

  // DYNAMICKÝ SEZNAM pro položky k seřazení 
  final List<TextEditingController> _optionControllers = [];
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _questionTextController = TextEditingController();
    _questionFocusNode = FocusNode();

    // Výchozí stav: 4 prázdné položky k seřazení
    for (int i = 0; i < 4; i++) {
      _optionControllers.add(TextEditingController());
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final args = GoRouterState.of(context).extra as Map<String, dynamic>?;
      final questionData = args?['questionData'] as Map<String, dynamic>?;
      
      if (questionData != null) {
        _questionTextController.text = questionData['text'] ?? '';
        
        final answers = questionData['answers'] as List?;
        if (answers != null && answers.isNotEmpty) {
          for (var c in _optionControllers) {
            c.dispose();
          }
          _optionControllers.clear();
          
          // U ORDERING otázek musíme pole seřadit podle order_index
          final sortedAnswers = List.from(answers)
            ..sort((a, b) => (a['order_index'] ?? 0).compareTo(b['order_index'] ?? 0));
            
          for (var ans in sortedAnswers) {
            _optionControllers.add(TextEditingController(text: ans['text'] ?? ''));
          }
        }
      }
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _questionTextController.dispose();
    _questionFocusNode.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // Funkce pro přidání další položky
  void _addOptionField() {
    setState(() {
      _optionControllers.add(TextEditingController());
    });
  }

  // Funkce pro odebrání položky
  void _removeOptionField(int index) {
    setState(() {
      // Povolí smazat položku, jen pokud zbydou alespoň 3 
      if (_optionControllers.length > 3) {
        _optionControllers[index].dispose();
        _optionControllers.removeAt(index);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Pro otázku typu Seřazení jsou potřeba alespoň 3 položky.'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  Future<bool> _saveQuestion(int bankId, {int? questionId}) async {
    if (_questionTextController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Zadejte znění otázky'), backgroundColor: Theme.of(context).colorScheme.error));
      return false;
    }

    final validOptions = _optionControllers.map((c) => c.text.trim()).where((text) => text.isNotEmpty).toList();

    if (validOptions.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Zadejte alespoň 3 platné položky k seřazení'), backgroundColor: Theme.of(context).colorScheme.error));
      return false;
    }

    try {
      final apiClient = ref.read(apiClientProvider);
      
      final answers = List.generate(validOptions.length, (index) {
        return {
          "text": validOptions[index],
          "is_correct": true,
          "order_index": index + 1, // Pořadí začíná od 1
        };
      });

      final requestData = {
        "text": _questionTextController.text.trim(),
        "type": "ORDERING",
        "default_points": 1,
        "answers": answers,
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

  // --- FUNKCE PRO ZOBRAZENÍ NÁHLEDU STUDENTA ---
  void _showStudentPreview() {
    // Vytvoří simulovaný seznam pro studenta 
    List<String> mockStudentItems = _optionControllers
        .map((c) => c.text.isEmpty ? 'Prázdná položka' : c.text)
        .toList();

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
                        
                        // Simulace Drag & Drop kartiček pro studenta
                        Expanded(
                          child: ListView.separated(
                            itemCount: mockStudentItems.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(12.0),
                                  border: Border.all(color: Theme.of(context).colorScheme.outline),
                                  boxShadow: [
                                    BoxShadow(color: Theme.of(context).shadowColor.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))
                                  ]
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.drag_indicator_rounded, color: Theme.of(context).colorScheme.secondary),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(mockStudentItems[index], style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface)),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),

                        // Falešné tlačítko
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0056D2),
                            minimumSize: const Size(double.infinity, 48.0),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
                          ),
                          child: Text('Další otázka', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
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
                  
                  Text('TYP OTÁZKY', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.secondary, letterSpacing: 1.2, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8.0),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).extension<CustomColors>()?.orangeBg ?? Theme.of(context).colorScheme.primaryContainer, 
                      borderRadius: BorderRadius.circular(20.0),
                      border: Border.all(color: Theme.of(context).colorScheme.outline, width: 1.0),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.drag_indicator_rounded, color: Theme.of(context).extension<CustomColors>()?.orangeText ?? Theme.of(context).colorScheme.primary, size: 16),
                        const SizedBox(width: 8),
                        Text('Seřazení', style: GoogleFonts.inter(color: Theme.of(context).extension<CustomColors>()?.orangeText ?? Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600, fontSize: 13)),
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

                  // DYNAMICKÁ SEKCE PRO SEŘAZENÍ
                  Text('SPRÁVNÉ POŘADÍ POLOŽEK', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.secondary, letterSpacing: 1.2, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4.0),
                  Text('Zadejte položky v přesném pořadí, ve kterém mají být seřazeny (od 1. do poslední). Studentům se automaticky zamíchají.', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.secondary, fontSize: 12)),
                  const SizedBox(height: 16.0),
                  
                  Column(
                    children: _optionControllers.asMap().entries.map((entry) {
                      int index = entry.key;
                      TextEditingController controller = entry.value;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          children: [
                            // Kolečko s pořadovým číslem
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, shape: BoxShape.circle),
                              alignment: Alignment.center,
                              child: Text('${index + 1}.', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 16.0),
                            Expanded(
                              child: TextFormField(
                                controller: controller,
                                style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface),
                                decoration: InputDecoration(
                                  hintText: 'Položka č. ${index + 1}',
                                  hintStyle: GoogleFonts.inter(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.normal),
                                  filled: true,
                                  fillColor: Theme.of(context).colorScheme.surface,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: BorderSide(color: Theme.of(context).colorScheme.outline)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: BorderSide(color: Theme.of(context).colorScheme.outline)),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12.0),
                            // Ikona pro odebrání položky
                            IconButton(
                              onPressed: () => _removeOptionField(index),
                              icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                              tooltip: 'Odebrat položku',
                              splashRadius: 24.0,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 12.0),
                  
                  TextButton.icon(
                    onPressed: _addOptionField,
                    icon: Icon(Icons.add_circle_outline, size: 18.0, color: Theme.of(context).colorScheme.primary),
                    label: Text('Přidat další položku', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
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