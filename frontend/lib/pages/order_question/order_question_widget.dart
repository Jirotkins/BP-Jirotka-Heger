import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../components/page_header_widget.dart';
import '../../components/next_question_button_widget.dart';

class OrderQuestionWidget extends StatefulWidget {
  const OrderQuestionWidget({super.key});

  @override
  State<OrderQuestionWidget> createState() => _OrderQuestionWidgetState();
}

class _OrderQuestionWidgetState extends State<OrderQuestionWidget> {
  // Stav pro znění otázky
  late TextEditingController _questionTextController;
  late FocusNode _questionFocusNode;

  // DYNAMICKÝ SEZNAM pro položky k seřazení 
  final List<TextEditingController> _optionControllers = [];

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
          const SnackBar(
            content: Text('Pro otázku typu Seřazení jsou potřeba alespoň 3 položky.'),
            backgroundColor: Color(0xFFD97706),
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
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
                        
                        // Simulace Drag & Drop kartiček pro studenta
                        Expanded(
                          child: ListView.separated(
                            itemCount: mockStudentItems.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12.0),
                                  border: Border.all(color: const Color(0xFFE5E7EB)),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))
                                  ]
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.drag_indicator_rounded, color: Color(0xFF9CA3AF)),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(mockStudentItems[index], style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: const Color(0xFF111827))),
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
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF0056D2),
                minimumSize: const Size(0, 40),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: Color(0xFF0056D2), width: 1.5)
                ),
                elevation: 0,
              ),
            ),
            const SizedBox(width: 12.0),

            ElevatedButton.icon(
              onPressed: () {
                print('Uloženo znění: ${_questionTextController.text}');
                print('Správné pořadí: ${_optionControllers.map((c) => c.text).toList()}');
              },
              icon: const Icon(Icons.save_outlined, size: 18),
              label: Text('Uložit', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0056D2),
                foregroundColor: Colors.white,
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
                  
                  Text('TYP OTÁZKY', style: GoogleFonts.inter(color: const Color(0xFF6B7280), letterSpacing: 1.2, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8.0),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB), // Světle oranžová
                      borderRadius: BorderRadius.circular(20.0),
                      border: Border.all(color: const Color(0xFFFCD34D), width: 1.0),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.drag_indicator_rounded, color: Color(0xFFD97706), size: 16),
                        const SizedBox(width: 8),
                        Text('Seřazení', style: GoogleFonts.inter(color: const Color(0xFFD97706), fontWeight: FontWeight.w600, fontSize: 13)),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32.0),

                  // POLE PRO ZNĚNÍ OTÁZKY
                  Text('ZNĚNÍ OTÁZKY', style: GoogleFonts.inter(color: const Color(0xFF6B7280), letterSpacing: 1.2, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8.0),
                  TextFormField(
                    controller: _questionTextController,
                    focusNode: _questionFocusNode,
                    maxLines: 4,
                    minLines: 3,
                    style: GoogleFonts.inter(fontSize: 16, color: const Color(0xFF111827)),
                    decoration: InputDecoration(
                      hintText: 'Napište zde znění otázky...',
                      hintStyle: GoogleFonts.inter(color: const Color(0xFF9CA3AF)),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.all(20.0),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: const BorderSide(color: Color(0xFF0056D2), width: 1.5)),
                    ),
                  ),
                  
                  const SizedBox(height: 24.0),

                  // UPLOAD OBRÁZKU
                  Container(
                    height: 120.0,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_upload_outlined, color: Color(0xFF9CA3AF), size: 36.0),
                        const SizedBox(height: 8.0),
                        Text('Přetáhněte obrázek nebo schéma (volitelné)', style: GoogleFonts.inter(color: const Color(0xFF6B7280), fontSize: 14.0)),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 48.0),
                  const Divider(color: Color(0xFFE5E7EB), height: 1),
                  const SizedBox(height: 32.0),

                  // DYNAMICKÁ SEKCE PRO SEŘAZENÍ
                  Text('SPRÁVNÉ POŘADÍ POLOŽEK', style: GoogleFonts.inter(color: const Color(0xFF6B7280), letterSpacing: 1.2, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4.0),
                  Text('Zadejte položky v přesném pořadí, ve kterém mají být seřazeny (od 1. do poslední). Studentům se automaticky zamíchají.', style: GoogleFonts.inter(color: const Color(0xFF9CA3AF), fontSize: 12)),
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
                              decoration: const BoxDecoration(color: Color(0xFFFFFBEB), shape: BoxShape.circle),
                              alignment: Alignment.center,
                              child: Text('${index + 1}.', style: GoogleFonts.inter(color: const Color(0xFFD97706), fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 16.0),
                            Expanded(
                              child: TextFormField(
                                controller: controller,
                                style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: const Color(0xFF111827)),
                                decoration: InputDecoration(
                                  hintText: 'Položka č. ${index + 1}',
                                  hintStyle: GoogleFonts.inter(color: const Color(0xFF9CA3AF), fontWeight: FontWeight.normal),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: const BorderSide(color: Color(0xFF0056D2))),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12.0),
                            // Ikona pro odebrání položky
                            IconButton(
                              onPressed: () => _removeOptionField(index),
                              icon: const Icon(Icons.delete_outline, color: Color(0xFFDC2626)),
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
                    icon: const Icon(Icons.add_circle_outline, size: 18.0, color: Color(0xFF0056D2)),
                    label: Text('Přidat další položku', style: GoogleFonts.inter(color: const Color(0xFF0056D2), fontWeight: FontWeight.w600)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                    ),
                  ),
                  
                  const SizedBox(height: 48.0),
                  const NextQuestionButtonWidget(),
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