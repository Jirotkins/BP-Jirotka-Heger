import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../components/active_test_card_widget.dart';
import '../../components/control_test_card_widget.dart';
import '../../components/page_header_widget.dart';
import '../../components/add_new_students_popup_widget.dart';
import '../../components/student_row_widget.dart';

class ClassManagerWidget extends StatefulWidget {
  const ClassManagerWidget({super.key});

  @override
  State<ClassManagerWidget> createState() => _ClassManagerWidgetState();
}

class _ClassManagerWidgetState extends State<ClassManagerWidget> {
  // Ukázková data 
  final List<Map<String, dynamic>> _mockStudents = [
    {'id': 1000, 'name': 'Jana Nováková'},
    {'id': 1001, 'name': 'Tomáš Kovář'},
    {'id': 1002, 'name': 'Karel Vratný'},
    {'id': 1003, 'name': 'Karolína Holá'},
    {'id': 1004, 'name': 'Petr Jenda'},
    {'id': 1005, 'name': 'Aneta Hromová'},
  ];

  @override
  Widget build(BuildContext context) {
    // ZÍSKÁNÍ PARAMETRŮ Z NAVIGACE (Přebírá z ClassCardWidget)
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final String className = args?['className'] ?? 'Neznámá třída';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // --- DYNAMICKÁ HLAVIČKA ---
        PageHeaderWidget(
          title: className,
          actions: [
            // PRVNÍ TLAČÍTKO: Přidat studenty
            ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  barrierColor: Colors.black54,
                  builder: (dialogContext) => const Dialog(
                    elevation: 0,
                    backgroundColor: Colors.transparent,
                    insetPadding: EdgeInsets.zero,
                    child: AddNewStudentsPopupWidget(),
                  ),
                );
              },
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: Text(
                'Přidat studenty',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0056D2), // Modrý podklad
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 40),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
              ),
            ),
            
            const SizedBox(width: 12.0), // Mezera mezi tlačítky

            // DRUHÉ TLAČÍTKO: Vytvořit test
            ElevatedButton.icon(
              onPressed: () {
                // Přesměrování na testEditor s předáním názvu třídy
                Navigator.pushNamed(
                  context,
                  '/testEditor', 
                  arguments: {
                    'targetName': className, 
                  },
                );
              },
              icon: const Icon(Icons.post_add, size: 18),
              label: Text(
                'Vytvořit test',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0056D2),
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 40),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
              ),
            ),
          ],
        ),

        // --- SCROLLOVACÍ OBSAH ---
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                // ROZBALOVACÍ PANEL STUDENTŮ
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0), 
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 10.0,
                        color: Colors.black.withOpacity(0.02),
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      title: Row(
                        children: [
                          const Icon(Icons.people_outline, color: Color(0xFF6B7280), size: 20),
                          const SizedBox(width: 12),
                          Text('STUDENTI', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF6B7280), letterSpacing: 1.1)),
                          const SizedBox(width: 12),
                          Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(color: Color(0xFF0056D2), shape: BoxShape.circle),
                            alignment: Alignment.center,
                            child: Text(
                              _mockStudents.length.toString(), 
                              style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)
                            ),
                          ),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6.0, left: 32.0),
                        child: Text(
                          'Rozklikněte pro rozbalení seznamu studentů', 
                          style: GoogleFonts.inter(color: const Color(0xFF9CA3AF), fontSize: 12)
                        ),
                      ),
                      children: [
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _mockStudents.length,
                          separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF3F4F6), indent: 20, endIndent: 20),
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4.0),
                              child: StudentRowWidget(
                                id: _mockStudents[index]['id'],
                                studentName: _mockStudents[index]['name'],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 48.0),
                
                // --- AKTIVNÍ TESTY ---
                _buildSectionHeader('Aktivní testy', const Color(0xFFDC2626), '1'), 
                const SizedBox(height: 16.0),
                
                ActiveTestCard(
                  title: 'Biologie - Buňka 2',
                  subtitle: 'Spuštěno: dnes 8:00 · Zbývá: 35 min',
                  submittedCount: 7,
                  totalStudents: 29,
                  onTap: () => print('Otevřít aktivní test'),
                ),

                const SizedBox(height: 48.0),

                // --- TESTY KE KONTROLE ---
                _buildSectionHeader('Testy ke kontrole', const Color(0xFF0056D2), '1'), 
                const SizedBox(height: 16.0),
                
                ControlTestCard(
                  title: 'Biologie - Buňka 1',
                  subtitle: 'Ukončeno: 12. 5. 2025 · 22/29 odevzdalo',
                  onTap: () => print('Otevřít test ke kontrole'),
                ),
                
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, Color badgeColor, String count) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(width: 4, height: 20, decoration: BoxDecoration(color: const Color(0xFF0056D2), borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 12),
        Text(title, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF111827))),
        const Spacer(),
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(count, style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
