import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_themes.dart';

class ClassCardWidget extends StatelessWidget {
  final int groupId;
  final String title;
  final String subject;
  final int studentCount;
  final int activeTestCount;
  final int testsToControl;
  final Widget icon;

  const ClassCardWidget({
    super.key,
    required this.groupId,
    required this.title,
    required this.subject,
    required this.studentCount,
    required this.activeTestCount,
    required this.testsToControl,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
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
          
          // --- HORNÍ ČÁST (Ikona, Název, Předmět) ---
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42.0,
                height: 42.0,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
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
                      style: GoogleFonts.inter(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 16.0,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      subject,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: Theme.of(context).colorScheme.secondary,
                        fontSize: 13.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24.0),

          // --- STŘEDNÍ ČÁST (Čísla) ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatColumn(context, 'Studenti', studentCount.toString(), Theme.of(context).colorScheme.onSurface),
              _buildStatColumn(context, 'Aktivní testy', activeTestCount.toString(), Theme.of(context).colorScheme.primary),
              _buildStatColumn(context, 'Ke kontrole', testsToControl.toString(), Theme.of(context).extension<CustomColors>()?.orangeText ?? Colors.orange),
            ],
          ),

          const SizedBox(height: 24.0),

          // --- SPODNÍ ČÁST  ---
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                context.push('/classManager', extra: {
                    'className': title,
                    'subject': subject,
                    'groupId': groupId,
                  },); 
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                foregroundColor: Theme.of(context).colorScheme.primary,
                elevation: 0,
                minimumSize: const Size(0, 38.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
              ),
              child: Text(
                'Detail',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 14.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(BuildContext context, String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center, 
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: Theme.of(context).colorScheme.secondary,
            fontSize: 11.0,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4.0),
        Text(
          value,
          style: GoogleFonts.inter(
            color: valueColor,
            fontSize: 18.0,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}