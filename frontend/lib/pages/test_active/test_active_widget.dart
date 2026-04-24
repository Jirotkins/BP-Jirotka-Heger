import 'package:flutter/material.dart';
import '../../components/test_submit_popup_widget.dart';

class TestActiveWidget extends StatefulWidget {
  const TestActiveWidget({super.key});

  @override
  State<TestActiveWidget> createState() => _TestActiveWidgetState();
}

class _TestActiveWidgetState extends State<TestActiveWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: const Color(0xFFF8F9FA),
      
      // HORNÍ LIŠTA: Zpět a název předmětu
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Matematika',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 22),
        ),
      ),
      
      body: SafeArea(
        child: Column(
          children: [
            // HLAVIČKA TESTU: Stavový pruh, Čas, Progress
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4.0, offset: Offset(0, 2))],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '25%',
                        style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 14.0),
                      ),
                      const Text(
                        '14:10',
                        style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 24.0),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12.0),
                  // PŘEPRACOVÁNO: Skutečný Progress Bar
                  LinearProgressIndicator(
                    value: 0.25, // 25 % hotovo
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3D5AF1)),
                    minHeight: 8.0,
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  const SizedBox(height: 12.0),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Otázka 5 / 20',
                      style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 14.0),
                    ),
                  ),
                ],
              ),
            ),

            // OBLAST OTÁZKY A ODPOVĚDI
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // TYP OTÁZKY (Ikona + Text)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.0),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8.0, offset: Offset(0, 4))],
                      ),
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 52.0, height: 52.0,
                                decoration: BoxDecoration(color: const Color(0xFFF0F4FF), borderRadius: BorderRadius.circular(14.0)),
                                child: const Icon(Icons.calculate_outlined, color: Color(0xFF3D5AF1), size: 28.0),
                              ),
                              const SizedBox(width: 16.0),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Předmět', style: TextStyle(color: Colors.grey, fontSize: 12.0)),
                                    Text('Matematika', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24.0),
                          
                          // ZNĚNÍ OTÁZKY
                          const Text(
                            'Která z následujících funkcí je sudá?',
                            style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          const SizedBox(height: 16.0),
                          
                          // PŘÍKLAD ODPOVĚDI
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20.0),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F4FF),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'f(x) = ?',
                              style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold, color: Color(0xFF3D5AF1)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24.0),

                    // POKYNY NEBO ZPĚTNÁ VAZBA
                    const Text(
                      'Vyberte správnou odpověď:',
                      style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 14.0),
                    ),
                    const SizedBox(height: 8.0),

                    // MOŽNOSTI ODPOVĚDÍ (Ukázka)
                    _buildAnswerOption('A', 'f(x) = 2x + 1', isSelected: false, isCorrect: null),
                    _buildAnswerOption('B', 'f(x) = x³', isSelected: false, isCorrect: null),
                    _buildAnswerOption('C', 'f(x) = |x|', isSelected: true, isCorrect: true), // Příklad vybrané a správné
                    _buildAnswerOption('D', 'f(x) = sin(x)', isSelected: false, isCorrect: false),
                  ],
                ),
              ),
            ),

            // SPODNÍ NAVIGAČNÍ TLAČÍTKA
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              color: const Color(0xFFF8F9FA),
              child: Row(
                children: [
                  // TLAČÍTKO ZPĚT
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF3D5AF1),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => print('Předchozí otázka'),
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  
                  // TLAČÍTKO DALŠÍ OTÁZKA
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Tlačítko teď ukazuje dialog pro odevzdání
                        showDialog(
                          context: context,
                          builder: (dialogContext) => const Dialog(
                            backgroundColor: Colors.transparent,
                            insetPadding: EdgeInsets.zero,
                            child: TestSubmitPopupWidget(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3D5AF1),
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22.0)),
                        elevation: 0,
                      ),
                      label: const Text('Další otázka', style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.white)),
                      icon: const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Pomocný widget pro vykreslení jedné možnosti odpovědi
  Widget _buildAnswerOption(String letter, String text, {required bool isSelected, bool? isCorrect}) {
    // Logika barev
    Color borderColor = Colors.grey.shade300;
    Color bgColor = Colors.white;
    Color iconColor = Colors.transparent;
    IconData iconData = Icons.circle_outlined;

    if (isSelected) {
      if (isCorrect == true) {
        borderColor = const Color(0xFF34C759); // Zelená (správně)
        bgColor = const Color(0xFFECFDF4);
        iconColor = const Color(0xFF34C759);
        iconData = Icons.check_circle_rounded;
      } else if (isCorrect == false) {
        borderColor = Colors.red; // Červená (špatně)
        bgColor = const Color(0xFFFDEDED);
        iconColor = Colors.red;
        iconData = Icons.cancel_rounded;
      } else {
        borderColor = const Color(0xFF3D5AF1); // Modrá (vybráno, zatím neopraveno)
        bgColor = const Color(0xFFF0F4FF);
        iconColor = const Color(0xFF3D5AF1);
        iconData = Icons.radio_button_checked;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: borderColor, width: isSelected ? 2.0 : 1.0),
      ),
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          // Písmeno (A, B, C...)
          Container(
            width: 36.0, height: 36.0,
            decoration: BoxDecoration(
              color: isSelected ? iconColor.withOpacity(0.1) : const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(10.0),
            ),
            alignment: Alignment.center,
            child: Text(
              letter,
              style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? iconColor : Colors.black54),
            ),
          ),
          const SizedBox(width: 16.0),
          // Text odpovědi
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15.0,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          // Ikona stavu
          if (isSelected) Icon(iconData, color: iconColor, size: 22.0)
          else Icon(Icons.arrow_forward_ios, color: Colors.grey.shade400, size: 16.0),
        ],
      ),
    );
  }
}