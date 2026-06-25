import 'dart:html' as html;
import 'dart:async';

void setWebBackgroundColor(String hexColor) {
  // Pevné zpoždění 50ms zaručí, že jakékoliv předchozí překreslení UI je dokončené
  Timer(const Duration(milliseconds: 50), () {
    // 1. Změna CSS pozadí
    html.document.documentElement?.style.backgroundColor = hexColor;
    html.document.body?.style.backgroundColor = hexColor;

    // 2. Najdeme VŠECHNY theme-color meta tagy a přepíšeme je, kdyby náhodou existoval nějaký duplicitní
    var metaTags = html.document.querySelectorAll('meta[name="theme-color"]');
    if (metaTags.isNotEmpty) {
      for (var meta in metaTags) {
        meta.setAttribute('content', hexColor);
      }
    } else {
      var newMeta = html.MetaElement()
        ..name = 'theme-color'
        ..content = hexColor;
      html.document.head?.append(newMeta);
    }
  });
}
