import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class DebugLogger extends ChangeNotifier {
  static final DebugLogger instance = DebugLogger._internal();
  DebugLogger._internal();

  final List<String> _logs = [];
  final DateFormat _fmt = DateFormat('HH:mm:ss.SSS');
  static const int _maxLogs = 1500;

  List<String> get logs => List.unmodifiable(_logs);

  void log(String tag, String message) {
    final entry = '[${_fmt.format(DateTime.now())}] [$tag] $message';
    _logs.add(entry);
    if (_logs.length > _maxLogs) {
      _logs.removeAt(0);
    }
    debugPrint(entry);
    notifyListeners();
  }

  void clear() {
    _logs.clear();
    log('SYSTEM', 'Journal de débogage effacé.');
  }

  String exportAsText() {
    final header = '=== BINANCE PULSE PRO DEBUG LOG ===\n'
        'Date: ${DateTime.now().toIso8601String()}\n'
        'Total entrées: ${_logs.length}\n'
        '====================================\n\n';
    return header + _logs.join('\n');
  }

  Future<void> copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: exportAsText()));
    log('SYSTEM', 'Journal copié dans le presse-papiers.');
  }

  Future<void> shareLogFile() async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/binance_pulse_debug_${DateTime.now().millisecondsSinceEpoch}.txt');
      await file.writeAsString(exportAsText());
      await Share.shareXFiles([XFile(file.path)],
          text: 'Journal Debug Binance Pulse Pro');
      log('SYSTEM', 'Fichier journal partagé avec succès.');
    } catch (e) {
      log('ERROR', 'Échec partage journal: $e');
    }
  }
}
