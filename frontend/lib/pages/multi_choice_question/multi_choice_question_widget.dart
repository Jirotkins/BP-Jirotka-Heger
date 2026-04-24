import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../components/page_header_widget.dart';
import '../../components/next_question_button_widget.dart';

class MultiChoiceQuestionWidget extends StatefulWidget {
  const MultiChoiceQuestionWidget({super.key});

  @override
  State<MultiChoiceQuestionWidget> createState() => _MultiChoiceQuestionWidgetState();
}

class _MultiChoiceQuestionWidgetState extends State<MultiChoiceQuestionWidget> {
  // Stav pro hlavní znění otázky
  late TextEditingController _questionTextController;
  late FocusNode _questionFocusNode;

  // DYNAMICKÝ SEZNAM pro možnosti (Textový kontroler + informace, zda je to správná odpověď)
  final List<Map<String, dynamic>> _options = [];

  @override
  void initState() {
    super.initState();
    _questionTextController = TextEditingController();
    _questionFocusNode = FocusNode();

    // Výchozí stav: Přidá 4 prázdné možnosti (tradiční A, B, C, D)
    for (int i = 0; i < 4; i++) {
      _options.add({
        'controller': TextEditingController(),
        'isCorrect': false, // Ve výchozím stavu není možnost označena jako správná
      });
    }
  }

  @override
  void dispose() {
    _questionTextController.dispose();
    _questionFocusNode.dispose();
    for (var option in _options) {
      (option['controller'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  // Funkce pro přidání další možnosti
  void _addOption() {
    setState(() {
      _options.add({
        'controller': TextEditingController(),
        'isCorrect': false,
      });
    });
  }

  // Funkce pro odebrání možnosti
  void _removeOption(int index) {
    setState(() {
      // Povolí smazat položku, jen pokud zbydou alespoň 2 
      if (_options.length > 2) {
        (_options[index]['controller'] as TextEditingController).dispose();
        _options.removeAt(index);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Otázka s výběrem z možností musí mít alespoň 2 varianty.'),
            backgroundColor: Color(0xFF0056D2),
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  // --- FUNKCE PRO ZOBRAZENÍ NÁHLEDU STUDENTA ---
  void _showStudentPreview() {
    // Pro ukázku si vytáhneme texty, aby byl náhled co nejreálnější
    List<String> studentOptions = _options
        .map((opt) => (opt['controller'] as TextEditingController).text.isEmpty 
            ? 'Prázdná varianta' 
            : (opt['controller'] as TextEditingController).text)
        .toList();

    showDialog(
      context: context,
      builder: (context) {
        // StatefulBuilder, aby šlo v náhledu i reálně klikat na checkboxy
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Lokální stav jen pro tento náhled 
            List<bool> studentChecked = List.generate(studentOptions.length, (index) => false);

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
                            
                            // Simulace seznamu možností
                            Expanded(
                              child: ListView.separated(
                                itemCount: studentOptions.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  bool isChecked = studentChecked[index];
                                  return InkWell(
                                    onTap: () {
                                      setDialogState(() {
                                        studentChecked[index] = !studentChecked[index];
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(12.0),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                                      decoration: BoxDecoration(
                                        color: isChecked ? const Color(0xFFEFF6FF) : Colors.white,
                                        borderRadius: BorderRadius.circular(12.0),
                                        border: Border.all(color: isChecked ? const Color(0xFF0056D2) : const Color(0xFFE5E7EB), width: isChecked ? 2.0 : 1.0),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            isChecked ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                                            color: isChecked ? const Color(0xFF0056D2) : const Color(0xFF9CA3AF),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              studentOptions[index], 
                                              style: GoogleFonts.inter(fontWeight: isChecked ? FontWeight.w600 : FontWeight.w500, color: const Color(0xFF111827))
                                            ),
                                          ),
                                        ],
                                      ),
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
          }
        );
      },
    );
  }

  // --- POMOCNÁ METODA PRO TLAČÍTKO NAHRÁNÍ OBRÁZKU K MOŽNOSTI ---
  Widget _buildImagePlaceholder() {
    return InkWell(
      onTap: () => print('Nahrát obrázek (zatím jen placeholder)'),
      borderRadius: BorderRadius.circular(10.0),
      child: Container(
        width: 48.0,
        height: 48.0, 
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.add_photo_alternate_outlined, color: Color(0xFF9CA3AF), size: 24.0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFF0056D2), width: 1.5)),
                elevation: 0,
              ),
            ),
            const SizedBox(width: 12.0),

            ElevatedButton.icon(
              onPressed: () {
                print('Uloženo znění: ${_questionTextController.text}');
                print('Možnosti: ${_options.map((o) => "{text: ${(o['controller'] as TextEditingController).text}, correct: ${o['isCorrect']}}").toList()}');
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
                      color: const Color(0xFFEEF2FF), // Světle modré pozadí
                      borderRadius: BorderRadius.circular(20.0),
                      border: Border.all(color: const Color(0xFF93C5FD), width: 1.0),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_box_outlined, color: Color(0xFF0056D2), size: 16),
                        const SizedBox(width: 8),
                        Text('Výběr z možností', style: GoogleFonts.inter(color: const Color(0xFF0056D2), fontWeight: FontWeight.w600, fontSize: 13)),
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

                  // DYNAMICKÁ SEKCE PRO MOŽNOSTI
                  Text('VARIANTY ODPOVĚDÍ', style: GoogleFonts.inter(color: const Color(0xFF6B7280), letterSpacing: 1.2, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4.0),
                  Text('Zadejte možné odpovědi a zaškrtněte tu správnou (nebo více správných). Ke každé možnosti lze přidat obrázek.', style: GoogleFonts.inter(color: const Color(0xFF9CA3AF), fontSize: 12)),
                  const SizedBox(height: 24.0),

                  // Generování řádků s možnostmi
                  Column(
                    children: _options.asMap().entries.map((entry) {
                      int index = entry.key;
                      var option = entry.value;
                      TextEditingController optCtrl = option['controller'];
                      bool isCorrect = option['isCorrect'];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Checkbox pro označení správnosti
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              child: InkWell(
                                onTap: () => setState(() => option['isCorrect'] = !isCorrect),
                                borderRadius: BorderRadius.circular(4.0),
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: isCorrect ? const Color(0xFF16A34A) : const Color(0xFFF9FAFB),
                                    borderRadius: BorderRadius.circular(8.0),
                                    border: Border.all(color: isCorrect ? const Color(0xFF16A34A) : const Color(0xFFD1D5DB)),
                                  ),
                                  child: isCorrect 
                                      ? const Icon(Icons.check, color: Colors.white, size: 24)
                                      : null,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16.0),
                            
                            // 2. Obrázek (Placeholder)
                            _buildImagePlaceholder(),
                            const SizedBox(width: 12.0),

                            // 3. Textové pole
                            Expanded(
                              child: TextFormField(
                                controller: optCtrl,
                                style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: const Color(0xFF111827)),
                                decoration: InputDecoration(
                                  hintText: 'Možnost ${String.fromCharCode(65 + index)}', // Generuje A, B, C, D...
                                  hintStyle: GoogleFonts.inter(color: const Color(0xFF9CA3AF), fontWeight: FontWeight.normal),
                                  filled: true,
                                  fillColor: isCorrect ? const Color(0xFFF0FDF4) : Colors.white, // Lehce zazelená textové pole, pokud je správně
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: BorderSide(color: isCorrect ? const Color(0xFF86EFAC) : const Color(0xFFE5E7EB))),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: BorderSide(color: isCorrect ? const Color(0xFF86EFAC) : const Color(0xFFE5E7EB))),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: BorderSide(color: isCorrect ? const Color(0xFF16A34A) : const Color(0xFF0056D2))),
                                ),
                              ),
                            ),

                            const SizedBox(width: 12.0),
                            
                            // 4. Ikona pro odebrání
                            Container(
                              height: 48,
                              alignment: Alignment.center,
                              child: IconButton(
                                onPressed: () => _removeOption(index),
                                icon: const Icon(Icons.delete_outline, color: Color(0xFFDC2626)),
                                tooltip: 'Odebrat možnost',
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
                    onPressed: _addOption,
                    icon: const Icon(Icons.add_circle_outline, size: 18.0, color: Color(0xFF0056D2)), 
                    label: Text('Přidat další možnost odpovědi', style: GoogleFonts.inter(color: const Color(0xFF0056D2), fontWeight: FontWeight.w600)),
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