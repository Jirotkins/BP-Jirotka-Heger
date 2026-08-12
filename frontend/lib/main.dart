import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'providers/theme_provider.dart';
import 'theme/app_themes.dart';
import 'router/app_router.dart'; 

/// Zástupný provider pro [SharedPreferences]. 
/// Během inicializace aplikace (v `main()`) je tento provider přepsán
/// skutečnou asynchronně získanou instancí (přes `overrideWithValue`).
/// Tím je zajištěn bezproblémový synchronní přístup k paměti napříč celou aplikací.
final sharedPrefsProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError());

void main() async {
  // Inicializace vazeb Flutteru před asynchronním voláním.
  WidgetsFlutterBinding.ensureInitialized();
  
  // Načtení lokální paměti.
  final prefs = await SharedPreferences.getInstance();

  // Spuštění samotné aplikace obalené v ProviderScope pro správu stavů (Riverpod).
  runApp(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
      ],
      child: const BakalarkaApp(),
    ),
  );
}

/// Hlavní kořenový widget aplikace.
/// Nastavuje lokalizaci (češtinu), napojení na GoRouter a aktuální vizuální režim.
class BakalarkaApp extends ConsumerWidget {
  const BakalarkaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        Locale('cs', 'CZ'),
      ],
      routerConfig: router,
    );
  }
}