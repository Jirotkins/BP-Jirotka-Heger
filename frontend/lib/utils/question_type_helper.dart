import 'package:flutter/material.dart';
import '../theme/app_themes.dart';

class QuestionTypeHelper {
  /// Vrací český formátovaný název pro daný typ otázky ze serveru
  static String getLabel(String backendType) {
    switch (backendType) {
      case 'SINGLE_CHOICE':
      case 'MULTI_CHOICE': 
        return 'Výběr z možností'; // V editoru testů se to na kartách trochu zkracuje, to můžeme ošetřit nebo nechat takto
      case 'ORDERING': 
        return 'Seřazení';
      case 'MATCHING': 
        return 'Párování';
      case 'OPEN_TEXT': 
        return 'Otevřená';
      case 'SHORT_ANSWER': 
        return 'Krátká odpověď';
      default: 
        return backendType;
    }
  }

  /// Vrací krátký český název (vhodný do malých štítků, např. v Test Editoru)
  static String getShortLabel(String backendType) {
    switch (backendType) {
      case 'SINGLE_CHOICE':
      case 'MULTI_CHOICE': 
        return 'Výběr';
      case 'ORDERING': 
        return 'Seřazení';
      case 'MATCHING': 
        return 'Párování';
      case 'OPEN_TEXT': 
        return 'Otevřená';
      case 'SHORT_ANSWER': 
        return 'Krátká';
      default: 
        return backendType;
    }
  }

  /// Vrací barvy štítku přesně podle zadání v bakalářské práci
  static Map<String, Color> getColors(BuildContext context, String backendType) {
    final customColors = Theme.of(context).extension<CustomColors>();
    
    switch (backendType) {
      case 'SINGLE_CHOICE':
      case 'MULTI_CHOICE':
        return {
          'bg': customColors?.blueBg ?? Theme.of(context).colorScheme.primaryContainer, 
          'text': customColors?.blueText ?? Theme.of(context).colorScheme.primary
        };
      case 'ORDERING':
        return {
          'bg': customColors?.orangeBg ?? Theme.of(context).colorScheme.primaryContainer, 
          'text': customColors?.orangeText ?? Theme.of(context).colorScheme.primary
        };
      case 'MATCHING':
        return {
          'bg': customColors?.purpleBg ?? Theme.of(context).colorScheme.primaryContainer, 
          'text': customColors?.purpleText ?? Theme.of(context).colorScheme.primary
        };
      case 'OPEN_TEXT':
        return {
          'bg': customColors?.greenBg ?? Theme.of(context).colorScheme.primaryContainer, 
          'text': customColors?.greenText ?? Theme.of(context).colorScheme.primary
        };
      case 'SHORT_ANSWER':
        return {
          'bg': customColors?.redBg ?? Theme.of(context).colorScheme.errorContainer, 
          'text': customColors?.redText ?? Theme.of(context).colorScheme.error
        };
      default:
        return {
          'bg': Theme.of(context).colorScheme.surfaceContainerHighest, 
          'text': Theme.of(context).colorScheme.onSurface
        };
    }
  }
}
