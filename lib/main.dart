import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'services/binance_service.dart';
import 'services/debug_logger.dart';
import 'services/notification_service.dart';
import 'services/simulator_engine.dart';
import 'ui/home_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarBrightness: Brightness.dark,
    statusBarIconBrightness: Brightness.light,
  ));

  await NotificationService.instance.init();
  DebugLogger.instance.log('BOOT', 'Application Binance Pulse Pro démarrée.');

  final simulator = SimulatorEngine();
  final binance = BinanceService(simulator: simulator);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: DebugLogger.instance),
        ChangeNotifierProvider.value(value: simulator),
        ChangeNotifierProvider.value(value: binance),
      ],
      child: const BinancePulseApp(),
    ),
  );
}

class BinancePulseApp extends StatelessWidget {
  const BinancePulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      title: 'Binance Pulse Pro',
      debugShowCheckedModeBanner: false,
      theme: CupertinoThemeData(
        brightness: Brightness.dark,
        primaryColor: Color(0xFF30D158),
        scaffoldBackgroundColor: Color(0xFF000000),
      ),
      home: HomeShell(),
    );
  }
}
