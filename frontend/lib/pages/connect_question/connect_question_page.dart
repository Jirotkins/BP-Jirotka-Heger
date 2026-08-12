import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../components/page_header_widget.dart';
import '../../components/image_upload_widget.dart';
import '../../components/student_preview_dialog.dart';
import '../../services/api_client.dart';
import '../questions_overview/questions_overview_provider.dart';

/// Editor pro vytvoření otázky typu "Párování" (Matching/Connect).
/// Učitel zde zadá logické dvojice (Pojem -> Definice).
/// Při spuštění testu se studentovi pravý sloupec zamíchá a on musí hodnoty správně propojit.
class ConnectQuestionPage extends ConsumerStatefulWidget {
  const ConnectQuestionPage({super.key});

  @override
  ConsumerState<ConnectQuestionPage> createState() => _ConnectQuestionPageState();
}

class _ConnectQuestionPageState extends ConsumerState<ConnectQuestionPage> {
  // Stav pro hlavní znění otázky
  late TextEditingController _questionTextController;
  late FocusNode _questionFocusNode;

  // DYNAMICKÝ SEZNAM pro párování (každá položka obsahuje Levý a Pravý kontroler)
  final List<Map<String, TextEditingController>> _pairControllers = [];
  bool _isInitialized = false;
  String? _imageBase64;

  @override
  void initState() {
    super.initState();
    _questionTextController = TextEditingController();
    _questionFocusNode = FocusNode();

    // Výchozí stav: Přidáme 3 prázdné dvojice k propojení
    for (int i = 0; i < 3; i++) {
      _addPair();
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
        _imageBase64 = questionData['image_url'];
        
        final answers = questionData['answers'] as List?;
        if (answers != null && answers.isNotEmpty) {
          for (var p in _pairControllers) {
            p['left']?.dispose();
            p['right']?.dispose();
          }
          _pairControllers.clear();
          
          for (var ans in answers) {
            String left = '';
            String right = '';
            String text = ans['text'] ?? '';
            
            if (text.contains('|||')) {
              final parts = text.split('|||');
              left = parts[0];
              right = parts.length > 1 ? parts[1] : '';
            } else {
              left = text;
              right = ans['match_text'] ?? '';
            }
            
            _pairControllers.add({
              'left': TextEditingController(text: left),
              'right': TextEditingController(text: right),
            });
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
    // Uvolnění všech kontrolerů z paměti
    for (var pair in _pairControllers) {
      pair['left']?.dispose();
      pair['right']?.dispose();
    }
    super.dispose();
  }

  // Funkce pro přidání další dvojice
  void _addPair() {
    setState(() {
      _pairControllers.add({
        'left': TextEditingController(),
        'right': TextEditingController(),
      });
    });
  }

  // Funkce pro odebrání dvojice
  void _removePair(int index) {
    setState(() {
      // Pro párování dává smysl mít minimálně 2 dvojice
      if (_pairControllers.length > 2) {
        _pairControllers[index]['left']?.dispose();
        _pairControllers[index]['right']?.dispose();
        _pairControllers.removeAt(index);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Pro otázku typu Párování jsou potřeba alespoň 2 dvojice.'),
            backgroundColor: Theme.of(context).colorScheme.primary, // Fialová barva
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

    final validPairs = _pairControllers.where((p) => p['left']!.text.trim().isNotEmpty && p['right']!.text.trim().isNotEmpty).toList();

    if (validPairs.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Zadejte alespoň 2 kompletní dvojice k propojení'), backgroundColor: Theme.of(context).colorScheme.error));
      return false;
    }

    try {
      final apiClient = ref.read(apiClientProvider);
      
      final answers = validPairs.map((p) {
        return {
          "text": "${p['left']!.text.trim()}|||${p['right']!.text.trim()}",
          "is_correct": true,
        };
      }).toList();

      final requestData = {
        "text": _questionTextController.text.trim(),
        "type": "MATCHING",
        "default_points": 1,
        "image_url": _imageBase64,
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

  /// Zobrazí modální okno simulující pohled studenta na mobilním zařízení.
  /// Využívá komponentu [StudentPreviewDialog].
  void _showStudentPreview() {
    List<String> leftItems = _pairControllers.map((p) => p['left']!.text.isEmpty ? 'Pojem' : p['left']!.text).toList();
    List<String> rightItems = _pairControllers.map((p) => p['right']!.text.isEmpty ? 'Definice' : p['right']!.text).toList();
    
    // Pro ukázku posuneme pravý sloupec
    if (rightItems.length > 1) {
      String first = rightItems.removeAt(0);
      rightItems.add(first);
    }

    showDialog(
      context: context,
      builder: (context) {
        return StudentPreviewDialog(
          questionText: _questionTextController.text,
          imageBase64: _imageBase64,
          subtitle: 'Přiřaďte správný pojem ke každé položce:',
          child: ListView.separated(
            itemCount: leftItems.length,
            separatorBuilder: (_, _) => const SizedBox(height: 24),
            itemBuilder: (context, index) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    leftItems[index],
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            rightItems[index], 
                            style: GoogleFonts.inter(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Icon(Icons.arrow_drop_down, color: Theme.of(context).colorScheme.onSurface),
                      ],
                    ),
                  ),
                ],
              );
            },
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
          showBackButton: true,
          actions: [
            // TLAČÍTKO 1: Pohled studenta
            ElevatedButton.icon(
              onPressed: _showStudentPreview, // Otevře mobilní simulátor
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

            // TLAČÍTKO 2: Uložit
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
                      color: const Color(0xFFF3E5F5), // Světle fialová
                      borderRadius: BorderRadius.circular(20.0),
                      border: Border.all(color: Theme.of(context).colorScheme.outline, width: 1.0),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.compare_arrows_rounded, color: Color(0xFF7B1FA2), size: 16),
                        const SizedBox(width: 8),
                        Text('Párování', style: GoogleFonts.inter(color: const Color(0xFF7B1FA2), fontWeight: FontWeight.w600, fontSize: 13)),
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
                      hintText: 'Např. Spojte správně fyzikální veličiny s jejich jednotkami...',
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

                  // DYNAMICKÁ SEKCE PRO PÁROVÁNÍ
                  Text('SPRÁVNÉ DVOJICE K PROPOJENÍ', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.secondary, letterSpacing: 1.2, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4.0),
                  Text('Zadejte hodnoty, které k sobě patří. Studentům se sloupce automaticky zamíchají.', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.secondary, fontSize: 12)),
                  const SizedBox(height: 24.0),
                  
                  // Záhlaví sloupců
                  Row(
                    children: [
                      const SizedBox(width: 48), // Odsazení pro číslo
                      Expanded(child: Text('Levá strana (Pojem)', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface, fontSize: 13))),
                      const SizedBox(width: 32), // Místo pro šipky
                      Expanded(child: Text('Pravá strana (Definice / Hodnota)', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface, fontSize: 13))),
                      const SizedBox(width: 48), // Odsazení pro ikonu smazání
                    ],
                  ),
                  const SizedBox(height: 12.0),

                  // Generování řádků
                  Column(
                    children: _pairControllers.asMap().entries.map((entry) {
                      int index = entry.key;
                      TextEditingController leftCtrl = entry.value['left']!;
                      TextEditingController rightCtrl = entry.value['right']!;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Kolečko s číslem páru
                            Container(
                              width: 32,
                              height: 32,
                              margin: const EdgeInsets.only(top: 8),
                              decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, shape: BoxShape.circle),
                              alignment: Alignment.center,
                              child: Text('${index + 1}', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 16.0),
                            
                            // Levá strana (Nyní s obrázkem)
                            Expanded(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: leftCtrl,
                                      style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface),
                                      decoration: InputDecoration(
                                        hintText: 'Např. Rychlost',
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
                                ],
                              ),
                            ),
                            
                            // Šipky uprostřed
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              height: 48.0,
                              alignment: Alignment.center,
                              child: Icon(Icons.sync_alt_rounded, color: Theme.of(context).colorScheme.outline),
                            ),

                            // Pravá strana (Nyní s obrázkem)
                            Expanded(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: rightCtrl,
                                      style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface),
                                      decoration: InputDecoration(
                                        hintText: 'Např. v',
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
                                ],
                              ),
                            ),

                            const SizedBox(width: 12.0),
                            
                            // Ikona pro odebrání řádku
                            Container(
                              height: 48,
                              alignment: Alignment.center,
                              child: IconButton(
                                onPressed: () => _removePair(index),
                                icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                                tooltip: 'Odebrat dvojici',
                                splashRadius: 24.0,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 12.0),
                  
                  TextButton.icon(
                    onPressed: _addPair,
                    icon: Icon(Icons.add_circle_outline, size: 18.0, color: Theme.of(context).colorScheme.primary), // Tlačítko v barvě kategorie
                    label: Text('Přidat další dvojici', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600)),
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