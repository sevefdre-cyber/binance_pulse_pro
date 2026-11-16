import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/debug_logger.dart';

class DebugTab extends StatelessWidget {
  const DebugTab({super.key});

  @override
  Widget build(BuildContext context) {
    final logger = context.watch<DebugLogger>();
    final entries = logger.logs.reversed.toList();

    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFF000000),
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Journal Debugger'),
        backgroundColor: const Color(0xFF1C1C1E).withOpacity(0.85),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: logger.clear,
          child: const Text('Effacer',
              style: TextStyle(color: Color(0xFFFF453A), fontSize: 14)),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              onPressed: () {
                HapticFeedback.mediumImpact();
                logger.copyToClipboard();
              },
              child: const Icon(CupertinoIcons.doc_on_clipboard, size: 20),
            ),
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              onPressed: () {
                HapticFeedback.mediumImpact();
                logger.shareLogFile();
              },
              child: const Icon(CupertinoIcons.share, size: 20),
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: entries.isEmpty
            ? const Center(
                child: Text(
                  'Aucun événement enregistré.',
                  style: TextStyle(color: CupertinoColors.systemGrey),
                ),
              )
            : ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(12),
                itemCount: entries.length,
                itemBuilder: (ctx, i) {
                  final line = entries[i];
                  Color textColor = CupertinoColors.systemGrey2;
                  if (line.contains('[ALERT-EXPLOSION]') ||
                      line.contains('[SIM-TP')) {
                    textColor = const Color(0xFF30D158);
                  } else if (line.contains('ERROR') ||
                      line.contains('[SIM-SL]')) {
                    textColor = const Color(0xFFFF453A);
                  } else if (line.contains('[SIM-ORDER]')) {
                    textColor = const Color(0xFFFFD60A);
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Text(
                      line,
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 11.5,
                        color: textColor,
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
