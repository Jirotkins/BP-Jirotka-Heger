import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

/// Vizualizační komponenta pro jednu konkrétní banku otázek.
/// 
/// Zobrazuje zadanou ikonu, název, předmět a aktuální počet otázek.
/// Obsahuje kontextové menu pro úpravu a smazání banky, 
/// a výrazné tlačítko pro přechod do detailu (seznamu otázek).
class BankCardWidget extends StatelessWidget {
  /// Jednoznačné ID banky otázek.
  final int id;
  
  /// Zvolený název banky (např. Biologie - savci).
  final String title;
  
  /// Volitelný předmět, do kterého banka spadá.
  final String subject;
  
  /// Zjištěný počet celkových otázek uložených v bance.
  final int questionCount;
  
  /// Widget s vybranou ikonou, pro vizuální odlišení banky.
  final Widget icon;
  
  /// Callback při vybrání možnosti "Upravit" v kontextovém menu.
  final VoidCallback? onEdit;
  
  /// Callback při vybrání možnosti "Smazat" v kontextovém menu.
  final VoidCallback? onDelete;
  
  /// Callback pro aktualizaci seznamu bank po případném návratu z detailu.
  final VoidCallback? onRefresh;

  const BankCardWidget({
    super.key,
    required this.id,
    required this.title,
    required this.subject,
    required this.questionCount,
    required this.icon,
    this.onEdit,
    this.onDelete,
    this.onRefresh,
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
            color: Colors.black.withValues(alpha: 0.02),
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
                      style: GoogleFonts.inter(
                        fontSize: 18.0,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      subject,
                      style: GoogleFonts.inter(
                        fontSize: 13.0,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (onEdit != null || onDelete != null)
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_horiz, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  onSelected: (value) {
                    if (value == 'edit' && onEdit != null) onEdit!();
                    if (value == 'delete' && onDelete != null) onDelete!();
                  },
                  itemBuilder: (BuildContext context) => [
                    if (onEdit != null)
                      PopupMenuItem<String>(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18, color: Theme.of(context).colorScheme.onSurface),
                            const SizedBox(width: 12),
                            const Text('Upravit'),
                          ],
                        ),
                      ),
                    if (onDelete != null)
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 18, color: Theme.of(context).colorScheme.error),
                            const SizedBox(width: 12),
                            Text('Smazat', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                          ],
                        ),
                      ),
                  ],
                ),
            ],
          ),
          
          const SizedBox(height: 24.0),

          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _buildStatColumn(context, 'Otázky', questionCount.toString(), Theme.of(context).colorScheme.onSurface),
            ],
          ),

          const SizedBox(height: 24.0),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                // PŘIDANÁ NAVIGACE S PŘEDÁNÍM DAT
                await context.push(
                  '/questionsOverview', // Cesta na přehled otázek
                  extra: {
                    'bankId': id,
                    'bankName': title, // Posíláme název (např. Gravitační pole)
                    'subject': subject,
                  },
                );
                if (onRefresh != null) {
                  onRefresh!();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                foregroundColor: Theme.of(context).colorScheme.primary,
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

  Widget _buildStatColumn(BuildContext context, String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center, 
      children: [
        Text(label, style: GoogleFonts.inter(color: Theme.of(context).colorScheme.secondary, fontSize: 11.0, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4.0),
        Text(value, style: GoogleFonts.inter(color: valueColor, fontSize: 18.0, fontWeight: FontWeight.w800)),
      ],
    );
  }
}