import 'dart:convert';
import 'package:web/web.dart' as web;
import 'dart:js_interop';

void downloadCsv(String csvData, String filename) {
  final bytes = utf8.encode(csvData);
  final blob = web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: 'text/csv;charset=utf-8'));
  final url = web.URL.createObjectURL(blob);
  
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = url
    ..download = filename;
  
  anchor.click();
  web.URL.revokeObjectURL(url);
}
