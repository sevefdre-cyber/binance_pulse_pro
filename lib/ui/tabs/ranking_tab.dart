import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../services/binance_service.dart';
import '../widgets/mini_candles_widget.dart';

class RankingTab extends StatefulWidget {
  const RankingTab({super.key});

  @override
  State<RankingTab> createState() => _RankingTabState();
}

class _RankingTabState extends State<RankingTab> {
  bool _showVolumeCandles = true;

  @override
  Widget build(BuildContext context) {
    final binance = context.watch<BinanceService>();
    final tokens = binance.rankedTokens;
    final btcBull = binance.isBtcBullish;

    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFF000000),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: const Text('Binance Pulse'),
            backgroundColor: const Color(0xFF1C1C1E).withOpacity(0.75),
            border: null,
            trailing: GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                binance.isScanning
                    ? binance.stopScanner()
                    : binance.startScanner();
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: binance.isScanning
                      ? const Color(0xFF30D158).withOpacity(0.2)
                      : const Color(0xFFFF453A).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: binance.isScanning
                        ? const Color(0xFF30D158)
                        : const Color(0xFFFF453A),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      binance.isScanning
                          ? CupertinoIcons.waveform_path_ecg
                          : CupertinoIcons.play_fill,
                      size: 14,
                      color: binance.isScanning
                          ? const Color(0xFF30D158)
                          : const Color(0xFFFF453A),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      binance.isScanning ? 'LIVE' : 'DÉMARRER',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: binance.isScanning
                            ? const Color(0xFF30D158)
                            : const Color(0xFFFF453A),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1E).withOpacity(0.85),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: btcBull
                            ? const Color(0xFF30D158).withOpacity(0.4)
                            : const Color(0xFFFF453A).withOpacity(0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'FLUX MAÎTRE BTC/USDT',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: CupertinoColors.systemGrey,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              binance.btcPrice > 0
                                  ? '\$${binance.btcPrice.toStringAsFixed(2)} (${binance.btcChange24hPct >= 0 ? "+" : ""}${binance.btcChange24hPct.toStringAsFixed(2)}%)'
                                  : 'En attente du flux...',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: CupertinoColors.white,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: btcBull
                                ? const Color(0xFF30D158)
                                : const Color(0xFFFF453A),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            btcBull
                                ? '🟢 LONG (Spot/Fut)'
                                : '🔴 SHORT (Futures)',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: CupertinoColors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Column(
                children: [
                  SizedBox(
                    height: 34,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: binance.presets.length,
                      itemBuilder: (ctx, idx) {
                        final p = binance.presets[idx];
                        final selected = idx == binance.selectedPresetIndex;
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            binance.selectPreset(idx);
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: selected
                                  ? CupertinoColors.activeBlue
                                  : const Color(0xFF1C1C1E),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              p.name,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: selected
                                    ? CupertinoColors.white
                                    : CupertinoColors.systemGrey,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${tokens.length} jetons classés (Tri: Var. 24h)',
                        style: const TextStyle(
                          fontSize: 12,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                      CupertinoSlidingSegmentedControl<bool>(
                        groupValue: _showVolumeCandles,
                        thumbColor: const Color(0xFF3A3A3C),
                        children: const {
                          true: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text('Bougies Vol %',
                                style: TextStyle(fontSize: 11)),
                          ),
                          false: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text('Bougies Prix %',
                                style: TextStyle(fontSize: 11)),
                          ),
                        },
                        onValueChanged: (v) {
                          if (v != null) {
                            HapticFeedback.selectionClick();
                            setState(() => _showVolumeCandles = v);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (tokens.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Text(
                  'Appuyez sur DÉMARRER en haut à droite\npour lancer le WebSocket Binance.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: CupertinoColors.systemGrey),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final token = tokens[index];
                  final isBull = token.priceChange24hPct >= 0;
                  final moveScore = token.rankDeltaAccumulator;
                  final threshold = binance.activePreset.requiredRankJumps;

                  return Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1E),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: moveScore >= threshold - 1 && moveScore > 0
                            ? const Color(0xFFFFD60A).withOpacity(0.7)
                            : const Color(0xFF2C2C2E),
                        width: moveScore >= threshold - 1 ? 1.2 : 0.6,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44,
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2C2C2E),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    '#${token.currentRank}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: CupertinoColors.white,
                                    ),
                                  ),
                                  if (moveScore > 0)
                                    Text(
                                      '▲+$moveScore',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF30D158),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        token.baseAsset,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: CupertinoColors.white,
                                        ),
                                      ),
                                      const Text(
                                        '/USDT',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: CupertinoColors.systemGrey,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      GestureDetector(
                                        onTap: () {
                                          HapticFeedback.lightImpact();
                                          binance
                                              .toggleSpecialToken(token.symbol);
                                        },
                                        child: Icon(
                                          token.isSpecial
                                              ? CupertinoIcons.star_fill
                                              : CupertinoIcons.star,
                                          size: 16,
                                          color: token.isSpecial
                                              ? const Color(0xFFFFD60A)
                                              : CupertinoColors.systemGrey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    'Vol 24h: ${(token.quoteVolume24h / 1e6).toStringAsFixed(1)}M \$',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: CupertinoColors.systemGrey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '\$${token.currentPrice < 1 ? token.currentPrice.toStringAsFixed(5) : token.currentPrice.toStringAsFixed(3)}',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: CupertinoColors.white,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isBull
                                        ? const Color(0xFF30D158)
                                        : const Color(0xFFFF453A),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${isBull ? "+" : ""}${token.priceChange24hPct.toStringAsFixed(2)}%',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: CupertinoColors.black,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        MiniCandlesRow(
                          metrics: token.historicalMetrics,
                          showVolume: _showVolumeCandles,
                        ),
                      ],
                    ),
                  );
                },
                childCount: tokens.length > 80 ? 80 : tokens.length,
              ),
            ),
        ],
      ),
    );
  }
}
