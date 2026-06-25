import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/web_color_helper.dart';
import '../main.dart';

// Notifier spravující hodnotu ThemeMode (světlý / tmavý)
class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final prefs = ref.watch(sharedPrefsProvider);
    final isDark = prefs.getBool('isDarkTheme') ?? false;
    final initialMode = isDark ? ThemeMode.dark : ThemeMode.light;

    // Zajištění, že se už při prvním spuštění (např. login) nastaví správná barva webu a SystemChrome
    Future.microtask(() => _updateSystemUI(initialMode));
    return initialMode;
  }

  void _updateSystemUI(ThemeMode mode) {
    // 1. Upraví hlavičky a spodní lišty prohlížeče (theme-color) a mobilních OS přes SystemChrome
    // Voláme to pouze na nativních platformách, aby se to "nepralo" s naším ručním web helperem!
    if (!kIsWeb) {
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        systemNavigationBarColor: mode == ThemeMode.dark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
        systemNavigationBarIconBrightness: mode == ThemeMode.dark ? Brightness.light : Brightness.dark,
        statusBarColor: mode == ThemeMode.dark ? const Color(0xFF1E1E1E) : Colors.white,
        statusBarIconBrightness: mode == ThemeMode.dark ? Brightness.light : Brightness.dark,
        statusBarBrightness: mode == ThemeMode.dark ? Brightness.dark : Brightness.light,
      ));
    }

    // 2. Ruční změna HTML barvy na pozadí, abychom zamezili prosvítání bílých okrajů v mobilním prohlížeči (Safe Area)
    if (mode == ThemeMode.dark) {
      setWebBackgroundColor('#1E1E1E');
    } else if (mode == ThemeMode.light) {
      setWebBackgroundColor('#FFFFFF');
    }
  }

  void toggleTheme() {
    final newMode = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    state = newMode;
    ref.read(sharedPrefsProvider).setBool('isDarkTheme', newMode == ThemeMode.dark);
    _updateSystemUI(newMode);
  }
  
  void setDarkTheme() {
    state = ThemeMode.dark;
    ref.read(sharedPrefsProvider).setBool('isDarkTheme', true);
    _updateSystemUI(state);
  }
  
  void setLightTheme() {
    state = ThemeMode.light;
    ref.read(sharedPrefsProvider).setBool('isDarkTheme', false);
    _updateSystemUI(state);
  }
}

// Globální provider pro ThemeMode
final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(() {
  return ThemeNotifier();
});
