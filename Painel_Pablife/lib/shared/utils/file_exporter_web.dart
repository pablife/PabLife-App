import 'dart:convert';
import 'dart:html' as html;

Future<void> fileExporterSaveCsv(String content, String filename) async {
  final bytes = utf8.encode(content);
  final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
  final url = html.Url.createObjectUrlFromBlob(blob);

  final anchor = html.AnchorElement(href: url)..download = filename;
  anchor.click();

  html.Url.revokeObjectUrl(url);
}
