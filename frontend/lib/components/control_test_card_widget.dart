import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ControlTestCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const ControlTestCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: const Color(0xFF111827))),
                  const SizedBox(height: 4),
                  Text(subtitle, style: GoogleFonts.inter(color: const Color(0xFF6B7280), fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF0056D2)),
          ],
        ),
      ),
    );
  }
}