import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// IMPORT PROVIDERŮ
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';

// IMPORT VŠECH POUŽÍVANÝCH STRÁNEK A ROUTERU
import 'pages/pages.dart';
import 'router/app_router.dart';
import 'theme/app_themes.dart';

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
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('cs', 'CZ'), // Nastavení češtiny jako hlavního jazyka
      ],

      // Reaktivní hlavní obrazovka podle stavu přihlášení
      routerConfig: router,
    );
  }
}