import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Notifier spravující hodnotu ThemeMode (světlý / tmavý)
class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    // Výchozí stav je světlý (podle preferencí aplikace)
    return ThemeMode.light;
  }

  void toggleTheme() {
    state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
  }
  
  void setDarkTheme() {
    state = ThemeMode.dark;
  }
  
  void setLightTheme() {
    state = ThemeMode.light;
  }
}

// Globální provider pro ThemeMode
final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(() {
  return ThemeNotifier();
});
