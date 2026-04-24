import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; 
import '../../components/page_header_widget.dart';
import '../../components/add_new_class_popup_widget.dart';
import '../../components/class_card_widget.dart';

class ClassOverviewWidget extends StatefulWidget {
  const ClassOverviewWidget({super.key});

  @override
  State<ClassOverviewWidget> createState() => _ClassOverviewWidgetState();
}

class _ClassOverviewWidgetState extends State<ClassOverviewWidget> {
  // Ukázková data
  final List<Map<String, dynamic>> _mockClasses = [
    {
      'title': '3.C bio',
      'subject': 'Biologie',
      'studentCount': 29,
      'activeTests': 7,
      'toControl': 22,
      'icon': Icons.science_outlined,
    },
    {
      'title': '3.C fyz',
      'subject': 'Fyzika',
      'studentCount': 27,
      'activeTests': 3,
      'toControl': 7,
      'icon': Icons.menu_book_outlined,
    },
    {
      'title': '2.B fyz',
      'subject': 'Fyzika',
      'studentCount': 31,
      'activeTests': 31,
      'toControl': 0,
      'icon': Icons.menu_book_outlined,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        
        // --- HLAVIČKA ---
        PageHeaderWidget(
          title: 'Moje třídy',
          actions: [
            ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  barrierColor: Colors.black54,
                  builder: (dialogContext) => const Dialog(
                    elevation: 0,
                    backgroundColor: Colors.transparent,
                    insetPadding: EdgeInsets.zero,
                    child: AddNewClassPopupWidget(),
                  ),
                );
              },
              icon: const Icon(Icons.add_circle_outline, size: 18.0),
              label: Text(
                'Přidat novou třídu',
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

        // --- SEKCE S KARTAMI ---
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                
                // Výpočet přesné šířky karty
                double cardWidth;
                if (constraints.maxWidth >= 1200) {
                  // Velké monitory: 3 karty vedle sebe (2 mezery po 24px)
                  cardWidth = (constraints.maxWidth - (2 * 24.0)) / 3;
                } else if (constraints.maxWidth >= 700) {
                  // Střední monitory/tablety: 2 karty vedle sebe
                  cardWidth = (constraints.maxWidth - 24.0) / 2;
                } else {
                  // Mobily: 1 karta na plnou šířku
                  cardWidth = constraints.maxWidth;
                }

                return Wrap(
                  spacing: 24.0, // Horizontální mezera
                  runSpacing: 24.0, // Vertikální mezera
                  children: List.generate(_mockClasses.length, (index) {
                    final item = _mockClasses[index];
                    return SizedBox(
                      width: cardWidth,
                      child: ClassCardWidget(
                        title: item['title'] as String,
                        subject: item['subject'] as String,
                        studentCount: item['studentCount'] as int,
                        activeTestCount: item['activeTests'] as int,
                        testsToControl: item['toControl'] as int,
                        icon: Icon(item['icon'] as IconData, color: Colors.white),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}