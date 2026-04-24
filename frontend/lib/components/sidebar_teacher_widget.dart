import 'package:flutter/material.dart';

class SidebarTeacherWidget extends StatefulWidget {
  final String? activePage;

  const SidebarTeacherWidget({
    super.key,
    required this.activePage,
  });

  @override
  State<SidebarTeacherWidget> createState() => _SidebarTeacherWidgetState();
}

class _SidebarTeacherWidgetState extends State<SidebarTeacherWidget> {
  // Zde držíme stav najetí myši čistě v rámci widgetu
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    // Získáme přesnou aktuální cestu z navigátoru (např. '/classManager')
    final currentRoute = ModalRoute.of(context)?.settings.name;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        // Plynulá animace rozbalení
        duration: const Duration(milliseconds: 200),
        width: _isHovered ? 250.0 : 85.0,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            right: BorderSide(color: Colors.grey.shade300, width: 1.0),
          ),
        ),
        // LayoutBuilder pro získání dostupné výšky obrazovky
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              // ConstrainedBox a IntrinsicHeight, aby Spacer fungoval uvnitř ScrollView
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
                        // LOGO (Horní část)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 32.0),
                          child: Icon(Icons.quiz_outlined, color: Color(0xFF3D5AF1), size: 48.0),
                        ),

                        const Spacer(),

                        // MENU POLOŽKY S CHYTROU NAVIGACÍ
                        _buildMenuItem(
                          icon: Icons.group_outlined,
                          title: 'Třídy',
                          pageKey: 'classes',
                          onTap: () {
                            // Kontroluje REÁLNOU cestu. 
                            // Pokud jsme v detailu třídy, pustí nás to zpět na přehled
                            if (currentRoute != '/classOverview') {
                              Navigator.pushReplacementNamed(context, '/classOverview');
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
                              Navigator.pushReplacementNamed(context, '/bankOverview');
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
                              Navigator.pushReplacementNamed(context, '/settingsTeacher');
                            }
                          },
                        ),

                        const Spacer(),

                        // PROFIL (Spodní část)
                        Container(
                          width: 48.0,
                          height: 48.0,
                          decoration: const BoxDecoration(
                            color: Color(0xFF3D5AF1),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'PN',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        if (_isHovered)
                          const Text(
                            'Mgr. Petr Novák',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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

  // Pomocná metoda pro stavbu čistých položek menu
  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String pageKey,
    required VoidCallback onTap,
  }) {
    // Pro podbarvení používá activePage z parametru 
    final isActive = widget.activePage == pageKey;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFE3F2FD) : Colors.transparent,
          borderRadius: BorderRadius.circular(12.0),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
        child: Row(
          children: [
            Icon(
              icon,
              color: isActive ? const Color(0xFF3D5AF1) : Colors.black87,
              size: 20.0,
            ),
            if (_isHovered) ...[
              const SizedBox(width: 12.0), 
              Expanded(
                child: Text(
                  title,
                  maxLines: 1, // Pojistka proti zalomení na 2 řádky
                  style: TextStyle(
                    color: isActive ? const Color(0xFF3D5AF1) : Colors.black87,
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