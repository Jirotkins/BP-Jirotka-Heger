import 'package:flutter/material.dart';
import '../components/sidebar_teacher_widget.dart';

class TeacherMainLayout extends StatelessWidget {
  /// Tohle je ta "prázdná díra". Tady se bude zobrazovat obsah obrazovek.
  final Widget child;
  /// Tohle říká Sidebaru, která položka má svítit jako aktivní.
  final String activePage;

  const TeacherMainLayout({
    super.key,
    required this.child,
    required this.activePage,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Globální pozadí aplikace
      body: SafeArea(
        child: Stack(
          children: [
            // 1. ZDE JE OBSAH (Třídy, Banky, atd.)
            // Positioned.fill vynutí, aby obsah zabíral celou obrazovku.
            // Padding zleva jsme přesunuli sem, takže už ho nebudete muset
            // psát do každé nové obrazovky! (85px je šířka sbaleného sidebaru)
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.only(left: 85.0),
                child: child, // Zde se vykreslí aktuální stránka
              ),
            ),

            // 2. ZDE JE SIDEBAR (Navždy ukotvený vlevo)
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