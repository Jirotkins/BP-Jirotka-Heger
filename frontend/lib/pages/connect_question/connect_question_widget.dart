import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../components/page_header_widget.dart';
import '../../services/api_client.dart';
import '../../theme/app_themes.dart';

class ConnectQuestionWidget extends ConsumerStatefulWidget {
  const ConnectQuestionWidget({super.key});

  @override
  ConsumerState<ConnectQuestionWidget> createState() => _ConnectQuestionWidgetState();
}

class _ConnectQuestionWidgetState extends ConsumerState<ConnectQuestionWidget> {
  // Stav pro hlavní znění otázky
  late TextEditingController _questionTextController;
  late FocusNode _questionFocusNode;

  // DYNAMICKÝ SEZNAM pro párování (každá položka obsahuje Levý a Pravý kontroler)
  final List<Map<String, TextEditingController>> _pairControllers = [];

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

  Future<bool> _saveQuestion(int bankId) async {
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
          "text": p['left']!.text.trim(),
          "match_text": p['right']!.text.trim(), // Speciální pole pro druhou část páru, pokud backend podporuje
          "is_correct": true,
        };
      }).toList();

      final requestData = {
        "text": _questionTextController.text.trim(),
        "type": "MATCHING",
        "default_points": 1,
        "answers": answers,
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
    // Vytáhneme hodnoty z kontrolerů pro zobrazení
    List<String> leftItems = _pairControllers.map((p) => p['left']!.text.isEmpty ? 'Pojem' : p['left']!.text).toList();
    List<String> rightItems = _pairControllers.map((p) => p['right']!.text.isEmpty ? 'Definice' : p['right']!.text).toList();
    
    // Pro ukázku "zamícháme" pravý sloupec (v praxi se to udělá reálně, tady to posuneme o 1)
    if (rightItems.length > 1) {
      String first = rightItems.removeAt(0);
      rightItems.add(first);
    }

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
                color: const Color(0xFFF5F7FA), 
                borderRadius: BorderRadius.circular(36.0),
                border: Border.all(color: const Color(0xFF111827), width: 10.0), 
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20.0, offset: Offset(0, 10))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26.0),
                child: Scaffold(
                  backgroundColor: const Color(0xFFF5F7FA),
                  appBar: AppBar(
                    backgroundColor: Colors.white,
                    elevation: 0,
                    centerTitle: true,
                    title: Text('Ukázka testu', style: GoogleFonts.inter(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
                    automaticallyImplyLeading: false,
                    actions: [
                      IconButton(icon: const Icon(Icons.close, color: Colors.black87), onPressed: () => Navigator.pop(context))
                    ],
                  ),
                  body: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _questionTextController.text.isEmpty ? '[Zde bude znění otázky...]' : _questionTextController.text,
                          style: GoogleFonts.inter(fontSize: 18.0, fontWeight: FontWeight.w600, color: const Color(0xFF111827)),
                        ),
                        const SizedBox(height: 24.0),
                        
                        // Simulace dvou sloupců pro studenta
                        Expanded(
                          child: Row(
                            children: [
                              // Levý sloupec
                              Expanded(
                                child: ListView.separated(
                                  itemCount: leftItems.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                                  itemBuilder: (context, index) => _buildPreviewCard(leftItems[index], const Color(0xFFF5F3FF), const Color(0xFF7C3AED)),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Pravý sloupec (Zamíchaný)
                              Expanded(
                                child: ListView.separated(
                                  itemCount: rightItems.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                                  itemBuilder: (context, index) => _buildPreviewCard(rightItems[index], Colors.white, const Color(0xFFE5E7EB)),
                                ),
                              ),
                            ],
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

  Widget _buildPreviewCard(String text, Color bgColor, Color borderColor) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: borderColor),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))]
      ),
      alignment: Alignment.center,
      child: Text(text, textAlign: TextAlign.center, style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: const Color(0xFF111827), fontSize: 13)),
    );
  }

  // --- POMOCNÁ METODA PRO TLAČÍTKO NAHRÁNÍ OBRÁZKU ---
  Widget _buildImagePlaceholder() {
    return InkWell(
      onTap: () => print('Nahrát obrázek (zatím jen placeholder)'),
      borderRadius: BorderRadius.circular(10.0),
      child: Container(
        width: 48.0,
        height: 48.0, // Stejná výška jako TextFormField
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(color: Theme.of(context).colorScheme.outline, width: 1.0),
        ),
        alignment: Alignment.center,
        child: Icon(Icons.add_photo_alternate_outlined, color: Theme.of(context).colorScheme.secondary, size: 24.0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  
                  Text('TYP OTÁZKY', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.secondary, letterSpacing: 1.2, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8.0),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).extension<CustomColors>()?.purpleBg ?? Theme.of(context).colorScheme.primaryContainer, 
                      borderRadius: BorderRadius.circular(20.0),
                      border: Border.all(color: Theme.of(context).colorScheme.outline, width: 1.0),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.compare_arrows_rounded, color: Theme.of(context).extension<CustomColors>()?.purpleText ?? Theme.of(context).colorScheme.primary, size: 16),
                        const SizedBox(width: 8),
                        Text('Párování', style: GoogleFonts.inter(color: Theme.of(context).extension<CustomColors>()?.purpleText ?? Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600, fontSize: 13)),
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

                  // DYNAMICKÁ SEKCE PRO PÁROVÁNÍ
                  Text('SPRÁVNÉ DVOJICE K PROPOJENÍ', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.secondary, letterSpacing: 1.2, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4.0),
                  Text('Zadejte hodnoty, které k sobě patří. K libovolné položce můžete připojit i obrázek. Studentům se sloupce automaticky zamíchají.', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.secondary, fontSize: 12)),
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
                                  _buildImagePlaceholder(),
                                  const SizedBox(width: 8.0),
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
                                  _buildImagePlaceholder(),
                                  const SizedBox(width: 8.0),
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