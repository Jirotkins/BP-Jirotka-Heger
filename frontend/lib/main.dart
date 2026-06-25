import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';


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

// Zde připravíme prázdný provider, který pak v main() přepíšeme skutečnou instancí
final sharedPrefsProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError());

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  // Spuštění samotné aplikace obalené v ProviderScope pro Riverpod
  runApp(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
      ],
      child: const BakalarkaApp(),
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