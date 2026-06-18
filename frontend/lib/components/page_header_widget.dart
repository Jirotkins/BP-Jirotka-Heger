import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PageHeaderWidget extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;

  const PageHeaderWidget({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16.0)),
        
        border: Border.all(
          color: Theme.of(context).colorScheme.outline, 
          width: 1.0,
        ),
        
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      margin: EdgeInsets.zero,
      
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 20.0), 
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.interTight(
                    fontSize: 30.0, 
                    fontWeight: FontWeight.w800, 
                    letterSpacing: -0.5,
                    height: 1.1, 
                    color: Theme.of(context).colorScheme.onSurface, 
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: GoogleFonts.inter(
                      fontSize: 14.0,
                      color: Theme.of(context).colorScheme.secondary,
                      fontWeight: FontWeight.w500,
                      height: 1.1,
                    ),
                  ),
                ],
              ],
            ),
          ),

          if (actions != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: actions!.map((widget) {
                return Padding(
                  padding: const EdgeInsets.only(left: 12.0),
                  child: widget,
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}