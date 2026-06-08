import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// IMPORT PROVIDERŮ
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';

// IMPORT VŠECH POUŽÍVANÝCH STRÁNEK A ROUTERU
import 'pages/pages.dart';
import 'router/app_router.dart';

// IMPORT LAYOUTŮ (SPA RÁMCŮ)
import 'layouts/teacher_main_layout.dart';
import 'layouts/student_main_layout.dart'; 

void main() {
  // Spuštění samotné aplikace obalené v ProviderScope pro Riverpod
  runApp(
    const ProviderScope(
      child: BakalarkaApp(),
    ),
  );
}

class BakalarkaApp extends ConsumerWidget {
  const BakalarkaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Čtení aktuálního tématu (Světlý/Tmavý) z Riverpodu
    final currentThemeMode = ref.watch(themeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Quizzes',
      debugShowCheckedModeBanner: false,
      themeMode: currentThemeMode,
      darkTheme: ThemeData.dark().copyWith(
        primaryColor: const Color(0xFF0056D2),
        scaffoldBackgroundColor: const Color(0xFF121212),
        useMaterial3: true,
      ),

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('cs', 'CZ'), // Nastavení češtiny jako hlavního jazyka
      ],
      
      // Nastavení globálního grafického tématu
      theme: ThemeData(
        primaryColor: const Color(0xFF0056D2), // Hlavní modrá
        scaffoldBackgroundColor: const Color(0xFFF5F7FA), // Výchozí světlé pozadí
        useMaterial3: true,
      ),

      // Reaktivní hlavní obrazovka podle stavu přihlášení
      routerConfig: router,
    );
  }
}