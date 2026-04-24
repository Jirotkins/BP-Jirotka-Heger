import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BankCardWidget extends StatelessWidget {
  final String title;
  final String subject;
  final int questionCount;
  final Widget icon;

  const BankCardWidget({
    super.key,
    required this.title,
    required this.subject,
    required this.questionCount,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 10.0,
            color: Colors.black.withOpacity(0.02),
            offset: const Offset(0, 4),
          )
        ],
        borderRadius: BorderRadius.circular(16.0),
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42.0,
                height: 42.0,
                decoration: BoxDecoration(
                  color: const Color(0xFF0056D2),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                alignment: Alignment.center,
                child: icon,
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(color: const Color(0xFF111827), fontSize: 16.0, fontWeight: FontWeight.w700, height: 1.2),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      subject,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(color: const Color(0xFF6B7280), fontSize: 13.0, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24.0),

          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _buildStatColumn('Otázky', questionCount.toString(), const Color(0xFF111827)),
            ],
          ),

          const SizedBox(height: 24.0),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // PŘIDANÁ NAVIGACE S PŘEDÁNÍM DAT
                Navigator.pushNamed(
                  context, 
                  '/questionsOverview', // Cesta na přehled otázek
                  arguments: {
                    'bankName': title, // Posíláme název (např. Gravitační pole)
                    'subject': subject,
                  },
                ); 
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEFF6FF),
                foregroundColor: const Color(0xFF0056D2),
                elevation: 0,
                minimumSize: const Size(0, 38.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
              ),
              child: Text('Detail', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14.0)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center, 
      children: [
        Text(label, style: GoogleFonts.inter(color: const Color(0xFF6B7280), fontSize: 11.0, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4.0),
        Text(value, style: GoogleFonts.inter(color: valueColor, fontSize: 18.0, fontWeight: FontWeight.w800)),
      ],
    );
  }
}