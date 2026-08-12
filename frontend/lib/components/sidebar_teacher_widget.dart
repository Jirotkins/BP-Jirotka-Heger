import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

/// Boční navigační menu (sidebar) pro učitelské rozhraní.
/// 
/// Zobrazuje ikony pro rychlou navigaci. Při najetí myší (hover)
/// se menu plynule rozbalí a zobrazí textové popisky.
class SidebarTeacherWidget extends ConsumerStatefulWidget {
  /// Identifikátor aktuálně aktivní stránky (např. 'classes', 'banks').
  final String? activePage;

  /// Vytvoří instanci bočního menu.
  const SidebarTeacherWidget({
    super.key,
    required this.activePage,
  });

  @override
  ConsumerState<SidebarTeacherWidget> createState() => _SidebarTeacherWidgetState();
}

/// Stav bočního menu řešící animaci rozbalení a navigaci.
class _SidebarTeacherWidgetState extends ConsumerState<SidebarTeacherWidget> {
  bool _isHovered = false;

  /// Vrátí iniciály z e-mailové adresy.
  /// 
  /// Používá první dvě písmena (pokud jsou k dispozici).
  String _getInitials(String email) {
    if (email.isEmpty) return 'U';
    if (email.length >= 2) {
      return email.substring(0, 2).toUpperCase();
    }
    return email[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final currentRoute = GoRouterState.of(context).uri.path;
    final authState = ref.watch(authProvider);
    final username = authState.username ?? 'ucitel@skola.cz';
    final initials = _getInitials(username);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: _isHovered ? 250.0 : 85.0,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            right: BorderSide(color: Theme.of(context).colorScheme.outline, width: 1.0),
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight, 
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // LOGO
                        Padding(
                          padding: const EdgeInsets.only(bottom: 32.0),
                          child: Icon(Icons.quiz_outlined, color: Theme.of(context).colorScheme.primary, size: 48.0),
                        ),

                        const Spacer(),

                        // NAVIGACE
                        _buildMenuItem(
                          icon: Icons.group_outlined,
                          title: 'Třídy',
                          pageKey: 'classes',
                          onTap: () {
                            if (currentRoute != '/classOverview') {
                              context.go('/classOverview');
                            }
                          },
                        ),
                        const SizedBox(height: 4.0),
                        _buildMenuItem(
                          icon: Icons.dehaze_rounded,
                          title: 'Banky otázek',
                          pageKey: 'banks',
                          onTap: () {
                            if (currentRoute != '/bankOverview') {
                              context.go('/bankOverview');
                            }
                          },
                        ),
                        const SizedBox(height: 4.0),
                        _buildMenuItem(
                          icon: Icons.settings_rounded,
                          title: 'Nastavení',
                          pageKey: 'settings',
                          onTap: () {
                            if (currentRoute != '/settingsTeacher') {
                              context.go('/settingsTeacher');
                            }
                          },
                        ),

                        const Spacer(),

                        // UŽIVATELSKÝ PROFIL
                        Container(
                          width: 48.0,
                          height: 48.0,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            initials,
                            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        if (_isHovered)
                          Text(
                            username,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Pomocná metoda pro vykreslení položky v menu.
  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String pageKey,
    required VoidCallback onTap,
  }) {
    final isActive = widget.activePage == pageKey;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
        decoration: BoxDecoration(
          color: isActive ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12.0),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
        child: Row(
          children: [
            Icon(
              icon,
              color: isActive ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
              size: 20.0,
            ),
            if (_isHovered) ...[
              const SizedBox(width: 12.0), 
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  style: TextStyle(
                    color: isActive ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                    fontSize: 14.0,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}