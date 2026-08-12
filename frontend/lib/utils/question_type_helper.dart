import 'package:flutter/material.dart';
import '../theme/app_themes.dart';

/// Pomocná třída pro mapování typů otázek z backendu na jejich české názvy,
/// cesty (routy) v aplikaci a odpovídající barevné štítky z definovaného tématu.
class QuestionTypeHelper {
  /// Vrací dlouhý, formátovaný český název pro daný [backendType] otázky.
  /// Používá se typicky v titulcích a přehledech.
  static String getLabel(String backendType) {
    switch (backendType) {
      case 'SINGLE_CHOICE':
      case 'MULTI_CHOICE': 
        return 'Výběr z možností';
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

  /// Vrací odpovídající navigační cestu (route path) pro zobrazení/editaci
  /// daného typu otázky podle jejího [backendType].
  static String getRouteForType(String backendType) {
    switch (backendType) {
      case 'SINGLE_CHOICE':
      case 'MULTI_CHOICE':
        return '/multiChoiceQuestion';
      case 'ORDERING':
        return '/orderQuestion';
      case 'MATCHING':
        return '/connectQuestion';
      case 'OPEN_TEXT':
        return '/openQuestion';
      case 'SHORT_ANSWER':
        return '/shortAnswerQuestion';
      default:
        return '/addNewQuestion';
    }
  }

  /// Vrací zkrácený český název otázky (vhodný pro malé štítky, např. v Test Editoru).
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

  /// Vrací mapu barev (klíče 'bg' pro pozadí a 'text' pro písmo) štítku.
  /// Barvy vycházejí z `CustomColors` rozšíření, specifikovaného pro světlý/tmavý režim.
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
