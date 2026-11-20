import 'dart:convert';
import 'dart:io';

Future<String?> triggerPlatformPrintHtml(
    String htmlContent, String title) async {
  try {
    final safeTitle = title.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
    final file = File('${Directory.systemTemp.path}/$safeTitle.html');
    await file.writeAsBytes(utf8.encode(htmlContent), flush: true);
    if (Platform.isWindows) {
      await Process.run('cmd', ['/c', 'start', '', file.path]);
      return file.path;
    } else if (Platform.isMacOS) {
      await Process.run('open', [file.path]);
      return file.path;
    } else if (Platform.isLinux) {
      await Process.run('xdg-open', [file.path]);
      return file.path;
    }
    return file.path;
  } catch (_) {
    return null;
  }
}

Future<String?> triggerPlatformDownloadCsv(
    String csvContent, String fileName) async {
  try {
    final bytes = [0xEF, 0xBB, 0xBF, ...utf8.encode(csvContent)];
    Directory targetDir = Directory.systemTemp;
    final userProfile =
        Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'];
    if (userProfile != null && userProfile.isNotEmpty) {
      final downloadsDir = Directory('$userProfile/Downloads');
      if (await downloadsDir.exists()) {
        targetDir = downloadsDir;
      }
    }
    final file = File('${targetDir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    if (Platform.isWindows) {
      await Process.run('cmd', ['/c', 'start', '', file.path]);
    }
    return file.path;
  } catch (_) {
    return null;
  }
}

