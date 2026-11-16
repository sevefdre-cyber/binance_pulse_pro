import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../models/sim_trade.dart';
import '../../services/binance_service.dart';
import '../../services/simulator_engine.dart';

class SimulatorTab extends StatelessWidget {
  const SimulatorTab({super.key});

  @override
  Widget build(BuildContext context) {
    final sim = context.watch<SimulatorEngine>();
    final binance = context.read<BinanceService>();

    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFF000000),
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Simulateur Spot & Futures'),
        backgroundColor: const Color(0xFF1C1C1E).withOpacity(0.85),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: sim.resetBalances,
          child: const Text('Reset', style: TextStyle(fontSize: 14)),
        ),
      ),
      child: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: _BalanceCard(
                    title: 'PORTEFEUILLE SPOT',
                    amount: sim.spotBalanceUsdt,
                    badge: 'LONG 1x',
                    color: const Color(0xFF30D158),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _BalanceCard(
                    title: 'PORTEFEUILLE FUTURES',
                    amount: sim.futuresBalanceUsdt,
                    badge: 'LONG/SHORT ${sim.futuresLeverage}x',
                    color: CupertinoColors.activeBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _PnlColumn('PnL Réalisé', sim.totalRealizedPnl),
                  _PnlColumn('PnL Latent', sim.totalUnrealizedPnl),
                  Column(
                    children: [
                      const Text('Auto-Trade',
                          style: TextStyle(
                              fontSize: 11, color: CupertinoColors.systemGrey)),
                      const SizedBox(height: 4),
                      CupertinoSwitch(
                        value: sim.autoTradeEnabled,
                        onChanged: (v) {
                          sim.autoTradeEnabled = v;
                          sim.notifyListeners();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Paliers Ordre Limite (TP1, TP2, TP3...)',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: CupertinoColors.white),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: sim.addTpLevel,
                  child: const Text('+ Ajouter TP'),
                ),
              ],
            ),
            ...List.generate(sim.tpConfigs.length, (idx) {
              final cfg = sim.tpConfigs[idx];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Text(
                      'TP${idx + 1}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF30D158)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Cible: +${cfg.targetPct.toStringAsFixed(1)}%  |  Clôture: ${(cfg.closeRatio * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                            fontSize: 13, color: CupertinoColors.white),
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        cfg.targetPct += 0.5;
                        sim.notifyListeners();
                      },
                      child: const Icon(CupertinoIcons.plus_circle, size: 20),
                    ),
                    if (sim.tpConfigs.length > 1)
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => sim.removeTpLevel(idx),
                        child: const Icon(CupertinoIcons.trash,
                            size: 18, color: Color(0xFFFF453A)),
                      ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 18),
            Text(
              'Positions & Ordres Limites (${sim.trades.length})',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: CupertinoColors.white),
            ),
            const SizedBox(height: 8),
            if (sim.trades.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'Aucune position simulée.\nLe bot placera automatiquement un ordre limite dès qu\'un jeton déclenchera le détecteur.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: CupertinoColors.systemGrey),
                  ),
                ),
              )
            else
              ...sim.trades.map((t) => _TradeCard(
                    trade: t,
                    onClose: () {
                      final current = binance.rankedTokens
                          .where((tok) => tok.symbol == t.symbol)
                          .firstOrNull
                          ?.currentPrice;
                      sim.closeTradeManually(t, current ?? t.entryPrice);
                    },
                  )),
          ],
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final String title;
  final double amount;
  final String badge;
  final Color color;

  const _BalanceCard({
    required this.title,
    required this.amount,
    required this.badge,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 10, color: CupertinoColors.systemGrey)),
          const SizedBox(height: 4),
          Text(
            '${amount.toStringAsFixed(2)} \$',
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: CupertinoColors.white),
          ),
          const SizedBox(height: 4),
          Text(badge,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

class _PnlColumn extends StatelessWidget {
  final String label;
  final double value;
  const _PnlColumn(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final color = value >= 0
        ? const Color(0xFF30D158)
        : const Color(0xFFFF453A);
    return Column(
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: CupertinoColors.systemGrey)),
        const SizedBox(height: 4),
        Text(
          '${value >= 0 ? "+" : ""}${value.toStringAsFixed(2)} \$',
          style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w800, color: color),
        ),
      ],
    );
  }
}

class _TradeCard extends StatelessWidget {
  final SimTrade trade;
  final VoidCallback onClose;

  const _TradeCard({required this.trade, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final isLong = trade.side == TradeSide.long;
    final totalPnl = trade.realizedPnlUsdt + trade.unrealizedPnlUsdt;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: isLong
                          ? const Color(0xFF30D158)
                          : const Color(0xFFFF453A),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${trade.side.name.toUpperCase()} ${trade.leverage}x',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: CupertinoColors.black),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    trade.symbol,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: CupertinoColors.white),
                  ),
                ],
              ),
              Text(
                trade.status == TradeStatus.pendingLimit
                    ? '⏳ LIMITE @ ${trade.limitEntryPrice.toStringAsFixed(5)}'
                    : '${totalPnl >= 0 ? "+" : ""}${totalPnl.toStringAsFixed(2)} USDT',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: trade.status == TradeStatus.pendingLimit
                      ? const Color(0xFFFFD60A)
                      : (totalPnl >= 0
                          ? const Color(0xFF30D158)
                          : const Color(0xFFFF453A)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            trade.triggerReason,
            style: const TextStyle(
                fontSize: 11, color: CupertinoColors.systemGrey),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ...trade.tpTargets.map((tp) => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: tp.hit
                          ? const Color(0xFF30D158).withOpacity(0.25)
                          : const Color(0xFF2C2C2E),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: tp.hit
                            ? const Color(0xFF30D158)
                            : CupertinoColors.systemGrey4,
                      ),
                    ),
                    child: Text(
                      '${tp.hit ? "✓ " : ""}TP${tp.index} (+${tp.targetPct}%)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: tp.hit
                            ? const Color(0xFF30D158)
                            : CupertinoColors.white,
                      ),
                    ),
                  )),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2E),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  trade.breakEvenMoved
                      ? '🛡️ SL: Break-Even'
                      : 'SL: -${trade.stopLossPct}%',
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFFFF9F0A)),
                ),
              ),
            ],
          ),
          if (trade.status != TradeStatus.closed) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: CupertinoButton(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                color: const Color(0xFF2C2C2E),
                onPressed: onClose,
                child: const Text('Fermer Position',
                    style: TextStyle(fontSize: 12, color: Color(0xFFFF453A))),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
