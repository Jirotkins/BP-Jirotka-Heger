import 'package:web/web.dart' as web;

import 'dart:async';

void setWebBackgroundColor(String hexColor) {
  Timer(const Duration(milliseconds: 50), () {
    (web.document.documentElement as web.HTMLElement?)?.style.backgroundColor = hexColor;
    web.document.body?.style.backgroundColor = hexColor;

    var metaTags = web.document.querySelectorAll('meta[name="theme-color"]');
    if (metaTags.length > 0) {
      for (var i = 0; i < metaTags.length; i++) {
        (metaTags.item(i) as web.HTMLMetaElement).content = hexColor;
      }
    } else {
      var newMeta = web.document.createElement('meta') as web.HTMLMetaElement
        ..name = 'theme-color'
        ..content = hexColor;
      web.document.head?.append(newMeta);
    }
  });
}
