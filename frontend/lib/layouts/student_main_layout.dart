import 'package:flutter/material.dart';
import '../pages/student_overview/student_overview_widget.dart';
import '../pages/settings_student/settings_student_widget.dart';

class StudentMainLayout extends StatefulWidget {
  const StudentMainLayout({super.key});

  @override
  State<StudentMainLayout> createState() => _StudentMainLayoutState();
}

class _StudentMainLayoutState extends State<StudentMainLayout> {
  int _currentIndex = 0;
  
  // Controller, který se postará o plynulé posouvání stránek
  late PageController _pageController;

  // Seznam stránek, mezi kterými lišta přepíná
  final List<Widget> _pages = const [
    StudentOverviewWidget(),
    SettingsStudentWidget(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Funkce, která se zavolá po kliknutí na ikonu v liště
  void _onItemTapped(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
      // Animace posunu doleva/doprava
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 350), // Délka animace
        curve: Curves.easeOutCubic, // Plynulý dojezd
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      
      // PageView drží stránky a posouvá je
      body: PageView(
        controller: _pageController,
        // Zabrání posouvání prstem (swipování), funguje jen klikání na lištu
        physics: const NeverScrollableScrollPhysics(),
        children: _pages,
      ),
      
      // Spodní navigační lišta zůstává celou dobu pevně na místě!
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05), 
              blurRadius: 10, 
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onItemTapped,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF4285F4),
          unselectedItemColor: Colors.grey.shade400,
          showSelectedLabels: false, 
          showUnselectedLabels: false,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.library_books_outlined, size: 28),
              activeIcon: Icon(Icons.library_books, size: 28),
              label: 'Přehled',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined, size: 28),
              activeIcon: Icon(Icons.settings, size: 28),
              label: 'Nastavení',
            ),
          ],
        ),
      ),
    );
  }
}