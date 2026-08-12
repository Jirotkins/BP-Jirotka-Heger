import 'package:flutter/material.dart';
import '../components/sidebar_teacher_widget.dart';

/// Hlavní rozvržení (layout) pro učitelské rozhraní.
/// 
/// Vykresluje sdílenou strukturu stránky sestávající z bočního menu [SidebarTeacherWidget]
/// na levé straně a hlavního obsahu zadaného pomocí [child].
class TeacherMainLayout extends StatelessWidget {
  /// Obsah (widget), který se má zobrazit ve zbylém prostoru vedle postranního menu.
  final Widget child;
  
  /// Identifikátor aktuálně aktivní stránky pro zvýraznění v bočním menu.
  final String activePage;

  /// Vytvoří hlavní layout učitele.
  const TeacherMainLayout({
    super.key,
    required this.child,
    required this.activePage,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // HLAVNÍ OBSAH STRÁNKY
            // Odsazeno o 85 pixelů, což odpovídá šířce sbaleného postranního menu.
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.only(left: 85.0),
                child: child,
              ),
            ),

            // POSTRANNÍ MENU (SIDEBAR)
            Positioned(
              top: 0,
              bottom: 0,
              left: 0,
              child: SidebarTeacherWidget(activePage: activePage),
            ),
          ],
        ),
      ),
    );
  }
}