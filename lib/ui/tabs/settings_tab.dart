import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../services/binance_service.dart';
import '../../services/simulator_engine.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final binance = context.watch<BinanceService>();
    final sim = context.watch<SimulatorEngine>();
    final preset = binance.activePreset;

    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFF000000),
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Sensibilité & Paramètres'),
        backgroundColor: const Color(0xFF1C1C1E).withOpacity(0.85),
      ),
      child: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'DÉTECTEUR DE VÉLOCITÉ DE RANG',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: CupertinoColors.systemGrey),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sauts de rang requis: ${preset.requiredRankJumps} places',
                    style: const TextStyle(color: CupertinoColors.white),
                  ),
                  CupertinoSlider(
                    value: preset.requiredRankJumps.toDouble(),
                    min: 1,
                    max: 15,
                    divisions: 14,
                    onChanged: (v) {
                      preset.requiredRankJumps = v.round();
                      binance.notifyListeners();
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Fenêtre de détection: ${preset.windowSeconds} secondes',
                    style: const TextStyle(color: CupertinoColors.white),
                  ),
                  CupertinoSlider(
                    value: preset.windowSeconds.toDouble(),
                    min: 30,
                    max: 600,
                    divisions: 19,
                    onChanged: (v) {
                      preset.windowSeconds = v.round();
                      binance.notifyListeners();
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Scanner uniquement Jetons Spéciaux ⭐',
                        style: TextStyle(color: CupertinoColors.white),
                      ),
                      CupertinoSwitch(
                        value: preset.specialTokensOnly,
                        onChanged: (v) {
                          preset.specialTokensOnly = v;
                          binance.notifyListeners();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'PARAMÈTRES SIMULATEUR & ORDRES LIMITES',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: CupertinoColors.systemGrey),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mise par trade: ${sim.stakePerTradeUsdt.toStringAsFixed(0)} USDT',
                    style: const TextStyle(color: CupertinoColors.white),
                  ),
                  CupertinoSlider(
                    value: sim.stakePerTradeUsdt,
                    min: 20,
                    max: 500,
                    divisions: 24,
                    onChanged: (v) {
                      sim.stakePerTradeUsdt = v;
                      sim.notifyListeners();
                    },
                  ),
                  Text(
                    'Levier Futures: ${sim.futuresLeverage}x',
                    style: const TextStyle(color: CupertinoColors.white),
                  ),
                  CupertinoSlider(
                    value: sim.futuresLeverage.toDouble(),
                    min: 1,
                    max: 20,
                    divisions: 19,
                    onChanged: (v) {
                      sim.futuresLeverage = v.round();
                      sim.notifyListeners();
                    },
                  ),
                  Text(
                    'Décalage Ordre Limite: ${sim.limitOffsetPct.toStringAsFixed(2)}%',
                    style: const TextStyle(color: CupertinoColors.white),
                  ),
                  CupertinoSlider(
                    value: sim.limitOffsetPct,
                    min: 0.0,
                    max: 1.0,
                    divisions: 20,
                    onChanged: (v) {
                      sim.limitOffsetPct = v;
                      sim.notifyListeners();
                    },
                  ),
                  Text(
                    'Stop-Loss initial: -${sim.stopLossPct.toStringAsFixed(1)}%',
                    style: const TextStyle(color: CupertinoColors.white),
                  ),
                  CupertinoSlider(
                    value: sim.stopLossPct,
                    min: 0.5,
                    max: 5.0,
                    divisions: 18,
                    onChanged: (v) {
                      sim.stopLossPct = v;
                      sim.notifyListeners();
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Break-Even auto après TP1',
                        style: TextStyle(color: CupertinoColors.white),
                      ),
                      CupertinoSwitch(
                        value: sim.autoBreakEvenOnTp1,
                        onChanged: (v) {
                          sim.autoBreakEvenOnTp1 = v;
                          sim.notifyListeners();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
