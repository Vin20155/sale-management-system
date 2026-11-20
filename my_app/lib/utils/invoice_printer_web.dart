// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

Future<String?> triggerPlatformPrintHtml(
    String htmlContent, String title) async {
  try {
    final bytes = Uint8List.fromList(utf8.encode(htmlContent));
    final blob = html.Blob([bytes], 'text/html;charset=utf-8');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.window.open(url, '_blank');
    Future.delayed(const Duration(seconds: 15), () {
      html.Url.revokeObjectUrl(url);
    });
    return 'browser_print';
  } catch (_) {
    return null;
  }
}

Future<String?> triggerPlatformDownloadCsv(
    String csvContent, String fileName) async {
  try {
    // Prepend UTF-8 BOM (\uFEFF) and encode as Uint8List so Excel renders Khmer & symbols properly
    final bytes = Uint8List.fromList(utf8.encode('\uFEFF$csvContent'));
    final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..style.display = 'none';
    html.document.body?.append(anchor);
    anchor.click();
    Future.delayed(const Duration(seconds: 5), () {
      anchor.remove();
      html.Url.revokeObjectUrl(url);
    });
    return fileName;
  } catch (_) {
    return null;
  }
}
