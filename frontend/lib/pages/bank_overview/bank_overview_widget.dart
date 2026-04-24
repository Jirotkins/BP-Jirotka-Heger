import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../components/page_header_widget.dart';
import '../../components/add_new_bank_popup_widget.dart';
import '../../components/bank_card_widget.dart';

class BankOverviewWidget extends StatelessWidget {
  BankOverviewWidget({super.key});

  // Ukázková data:
  final List<Map<String, dynamic>> _mockBanks = [
    {
      'title': 'Gravitační pole',
      'subject': 'Fyzika',
      'questionCount': 8,
      'icon': Icons.menu_book_outlined,
    },
    {
      'title': 'Kinematika hmotného bodu',
      'subject': 'Fyzika',
      'questionCount': 7,
      'icon': Icons.menu_book_outlined,
    },
    {
      'title': 'Kvadratické rovnice',
      'subject': 'Matematika',
      'questionCount': 15,
      'icon': Icons.calculate_outlined,
    },
    {
      'title': 'Fyzikální veličiny a jejich jednotky',
      'subject': 'Fyzika',
      'questionCount': 20,
      'icon': Icons.menu_book_outlined,
    },
    {
      'title': 'Buňka',
      'subject': 'Biologie',
      'questionCount': 18,
      'icon': Icons.science_outlined,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // --- HLAVIČKA ---
        PageHeaderWidget(
          title: 'Banky otázek',
          actions: [
            ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  barrierColor: Colors.black54, // Poloprůhledné pozadí
                  builder: (_) => const Dialog(
                    elevation: 0,
                    backgroundColor: Colors.transparent,
                    insetPadding: EdgeInsets.zero,
                    child: AddNewBankPopupWidget(),
                  ),
                );
              },
              icon: const Icon(Icons.add_circle_outline, size: 18.0),
              label: Text(
                'Přidat novou banku',
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
                  // Velké monitory: 3 karty vedle sebe
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
                  children: List.generate(_mockBanks.length, (index) {
                    final bankData = _mockBanks[index];
                    return SizedBox(
                      width: cardWidth,
                      child: BankCardWidget(
                        title: bankData['title'] as String,
                        subject: bankData['subject'] as String,
                        questionCount: bankData['questionCount'] as int,
                        icon: Icon(bankData['icon'] as IconData, color: Colors.white),
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