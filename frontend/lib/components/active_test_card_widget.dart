import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ActiveTestCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final int submittedCount;
  final int totalStudents;
  final VoidCallback onTap;

  const ActiveTestCard({
    required this.title,
    required this.subtitle,
    required this.submittedCount,
    required this.totalStudents,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                  Row(
                    children: [
                      Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFFDC2626), shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Text('Probíhá', style: GoogleFonts.inter(color: const Color(0xFFDC2626), fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: const Color(0xFF111827))),
                  const SizedBox(height: 2),
                  Text(subtitle, style: GoogleFonts.inter(color: const Color(0xFF6B7280), fontSize: 13)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$submittedCount/$totalStudents', 
                  style: GoogleFonts.inter(color: const Color(0xFF0056D2), fontSize: 22, fontWeight: FontWeight.w800)
                ),
                Text('odevzdalo', style: GoogleFonts.inter(color: const Color(0xFF6B7280), fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}