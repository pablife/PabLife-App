import 'file_exporter_stub.dart'
    if (dart.library.html) 'file_exporter_web.dart';

Future<void> saveCsvFile(String content, String filename) async {
  await fileExporterSaveCsv(content, filename);
}
