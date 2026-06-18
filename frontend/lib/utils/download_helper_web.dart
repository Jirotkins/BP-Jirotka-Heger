import 'dart:html' as html;
import 'dart:convert';

void downloadCsv(String csvData, String filename) {
  final bytes = utf8.encode(csvData);
  final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute("download", filename)
    ..click();
  html.Url.revokeObjectUrl(url);
}
