import 'package:flutter/foundation.dart';
import '../models/sim_trade.dart';
import '../models/token_data.dart';
import 'debug_logger.dart';

class TpLevelConfig {
  double targetPct;
  double closeRatio;
  TpLevelConfig({required this.targetPct, required this.closeRatio});
}

class SimulatorEngine extends ChangeNotifier {
  bool autoTradeEnabled = true;
  double spotBalanceUsdt = 1000.0;
  double futuresBalanceUsdt = 1000.0;

  double stakePerTradeUsdt = 100.0;
  int futuresLeverage = 5;
  double limitOffsetPct = 0.15;
  double stopLossPct = 1.5;
  bool autoBreakEvenOnTp1 = true;
  int maxConcurrentTrades = 5;

  List<TpLevelConfig> tpConfigs = [
    TpLevelConfig(targetPct: 1.5, closeRatio: 0.40),
    TpLevelConfig(targetPct: 3.0, closeRatio: 0.35),
    TpLevelConfig(targetPct: 5.5, closeRatio: 0.25),
  ];

  final List<SimTrade> _trades = [];
  List<SimTrade> get trades => List.unmodifiable(_trades);

  List<SimTrade> get activeTrades =>
      _trades.where((t) => t.status != TradeStatus.closed).toList();

  List<SimTrade> get closedTrades =>
      _trades.where((t) => t.status == TradeStatus.closed).toList();

  double get totalRealizedPnl =>
      _trades.fold(0.0, (sum, t) => sum + t.realizedPnlUsdt);

  double get totalUnrealizedPnl =>
      activeTrades.fold(0.0, (sum, t) => sum + t.unrealizedPnlUsdt);

  void addTpLevel() {
    final nextPct = (tpConfigs.isNotEmpty ? tpConfigs.last.targetPct : 1.5) + 2.0;
    tpConfigs.add(TpLevelConfig(targetPct: nextPct, closeRatio: 0.20));
    _normalizeTpRatios();
    notifyListeners();
  }

  void removeTpLevel(int index) {
    if (tpConfigs.length <= 1) return;
    tpConfigs.removeAt(index);
    _normalizeTpRatios();
    notifyListeners();
  }

  void _normalizeTpRatios() {
    final sum = tpConfigs.fold(0.0, (s, e) => s + e.closeRatio);
    if (sum > 0) {
      for (final c in tpConfigs) {
        c.closeRatio = double.parse((c.closeRatio / sum).toStringAsFixed(2));
      }
    }
  }

  void resetBalances() {
    spotBalanceUsdt = 1000.0;
    futuresBalanceUsdt = 1000.0;
    _trades.clear();
    DebugLogger.instance.log('SIM', 'Portefeuilles Spot/Futures réinitialisés à 1000 USDT.');
    notifyListeners();
  }

  void onTokenSignal({
    required TokenData token,
    required bool isBtcBullish,
    required String reason,
  }) {
    if (!autoTradeEnabled) return;
    if (activeTrades.length >= maxConcurrentTrades) return;
    if (activeTrades.any((t) => t.symbol == token.symbol)) return;

    final TradeSide side = isBtcBullish ? TradeSide.long : TradeSide.short;
    final TradeMarket market = isBtcBullish
        ? (futuresBalanceUsdt >= stakePerTradeUsdt
            ? TradeMarket.futures
            : TradeMarket.spot)
        : TradeMarket.futures;

    final int effLeverage = market == TradeMarket.spot ? 1 : futuresLeverage;

    if (market == TradeMarket.spot && spotBalanceUsdt < stakePerTradeUsdt) return;
    if (market == TradeMarket.futures && futuresBalanceUsdt < stakePerTradeUsdt) return;

    final double limitPrice = side == TradeSide.long
        ? token.currentPrice * (1 - limitOffsetPct / 100)
        : token.currentPrice * (1 + limitOffsetPct / 100);

    final double qty = (stakePerTradeUsdt * effLeverage) / limitPrice;
    final double slPrice = side == TradeSide.long
        ? limitPrice * (1 - stopLossPct / 100)
        : limitPrice * (1 + stopLossPct / 100);

    final targets = <TakeProfitTarget>[];
    for (int i = 0; i < tpConfigs.length; i++) {
      final cfg = tpConfigs[i];
      final tpPrice = side == TradeSide.long
          ? limitPrice * (1 + cfg.targetPct / 100)
          : limitPrice * (1 - cfg.targetPct / 100);
      targets.add(TakeProfitTarget(
        index: i + 1,
        targetPct: cfg.targetPct,
        closeRatio: cfg.closeRatio,
        targetPrice: tpPrice,
      ));
    }

    if (market == TradeMarket.spot) {
      spotBalanceUsdt -= stakePerTradeUsdt;
    } else {
      futuresBalanceUsdt -= stakePerTradeUsdt;
    }

    final trade = SimTrade(
      id: '${token.symbol}_${DateTime.now().millisecondsSinceEpoch}',
      symbol: token.symbol,
      market: market,
      side: side,
      status: limitOffsetPct <= 0 ? TradeStatus.open : TradeStatus.pendingLimit,
      limitEntryPrice: limitPrice,
      entryPrice: limitPrice,
      initialMarginUsdt: stakePerTradeUsdt,
      leverage: effLeverage,
      initialQuantity: qty,
      stopLossPrice: slPrice,
      stopLossPct: stopLossPct,
      tpTargets: targets,
      triggerReason: reason,
    );

    _trades.insert(0, trade);
    DebugLogger.instance.log(
      'SIM-ORDER',
      'Ordre LIMITE ${side.name.toUpperCase()} [${market.name.toUpperCase()} x$effLeverage] '
      '${token.symbol} @ ${limitPrice.toStringAsFixed(6)} | '
      'TPs: ${targets.map((e) => "TP${e.index}:${e.targetPrice.toStringAsFixed(5)}").join(", ")}',
    );
    notifyListeners();
  }

  void onPriceTick(String symbol, double price) {
    bool changed = false;

    for (final trade in activeTrades) {
      if (trade.symbol != symbol) continue;

      if (trade.status == TradeStatus.pendingLimit) {
        final bool filled = (trade.side == TradeSide.long && price <= trade.limitEntryPrice) ||
            (trade.side == TradeSide.short && price >= trade.limitEntryPrice);

        final bool missed = (trade.side == TradeSide.long &&
                price > trade.limitEntryPrice * 1.015) ||
            (trade.side == TradeSide.short &&
                price < trade.limitEntryPrice * 0.985);

        if (filled) {
          trade.status = TradeStatus.open;
          trade.entryPrice = trade.limitEntryPrice;
          trade.filledAt = DateTime.now();
          DebugLogger.instance.log(
            'SIM-FILL',
            'Ordre Limite EXÉCUTÉ: ${trade.symbol} ${trade.side.name.toUpperCase()} @ ${trade.entryPrice}',
          );
          changed = true;
        } else if (missed) {
          _refundAndClose(trade, price, 'Ordre limite expiré (prix parti sans repli)');
          changed = true;
        }
        continue;
      }

      final double direction = trade.side == TradeSide.long ? 1.0 : -1.0;
      trade.unrealizedPnlUsdt =
          (price - trade.entryPrice) * trade.remainingQuantity * direction;

      final bool slHit = (trade.side == TradeSide.long && price <= trade.stopLossPrice) ||
          (trade.side == TradeSide.short && price >= trade.stopLossPrice);

      if (slHit) {
        final pnl = (trade.stopLossPrice - trade.entryPrice) *
            trade.remainingQuantity *
            direction;
        trade.realizedPnlUsdt += pnl;
        trade.unrealizedPnlUsdt = 0;
        final remainingRatio = trade.remainingQuantity / trade.initialQuantity;
        final returnedMargin = (trade.initialMarginUsdt * remainingRatio) + pnl;
        _creditBalance(trade.market, returnedMargin.clamp(0, double.infinity));
        trade.remainingQuantity = 0;
        trade.status = TradeStatus.closed;
        trade.closedAt = DateTime.now();

        DebugLogger.instance.log(
          'SIM-SL',
          'STOP-LOSS touché sur ${trade.symbol} @ ${trade.stopLossPrice.toStringAsFixed(6)} | PnL total: ${trade.realizedPnlUsdt.toStringAsFixed(2)} USDT',
        );
        changed = true;
        continue;
      }

      for (final tp in trade.tpTargets) {
        if (tp.hit) continue;
        final bool tpReached = (trade.side == TradeSide.long && price >= tp.targetPrice) ||
            (trade.side == TradeSide.short && price <= tp.targetPrice);

        if (tpReached) {
          tp.hit = true;
          final double qtyToClose = (trade.initialQuantity * tp.closeRatio)
              .clamp(0.0, trade.remainingQuantity);
          final double stepPnl =
              (tp.targetPrice - trade.entryPrice) * qtyToClose * direction;
          final double releasedMargin =
              (trade.initialMarginUsdt * tp.closeRatio) + stepPnl;

          trade.realizedPnlUsdt += stepPnl;
          trade.remainingQuantity -= qtyToClose;
          _creditBalance(trade.market, releasedMargin);

          DebugLogger.instance.log(
            'SIM-TP${tp.index}',
            'TP${tp.index} (+${tp.targetPct}%) ATTEINT sur ${trade.symbol} @ ${tp.targetPrice.toStringAsFixed(6)} | Gain palier: +${stepPnl.toStringAsFixed(2)} USDT',
          );

          if (tp.index == 1 && autoBreakEvenOnTp1 && !trade.breakEvenMoved) {
            trade.stopLossPrice = trade.entryPrice;
            trade.breakEvenMoved = true;
            DebugLogger.instance.log(
              'SIM-BE',
              'Break-Even activé sur ${trade.symbol} (SL déplacé à ${trade.entryPrice})',
            );
          }

          if (trade.remainingQuantity <= trade.initialQuantity * 0.001 ||
              trade.tpTargets.every((t) => t.hit)) {
            trade.remainingQuantity = 0;
            trade.unrealizedPnlUsdt = 0;
            trade.status = TradeStatus.closed;
            trade.closedAt = DateTime.now();
            DebugLogger.instance.log(
              'SIM-CLOSE',
              'Position ${trade.symbol} 100% clôturée en profit ! PnL Net: +${trade.realizedPnlUsdt.toStringAsFixed(2)} USDT',
            );
          }
          changed = true;
        }
      }
    }

    if (changed) notifyListeners();
  }

  void closeTradeManually(SimTrade trade, double currentPrice) {
    if (trade.status == TradeStatus.closed) return;
    if (trade.status == TradeStatus.pendingLimit) {
      _refundAndClose(trade, currentPrice, 'Annulé manuellement');
      notifyListeners();
      return;
    }
    final double direction = trade.side == TradeSide.long ? 1.0 : -1.0;
    final double pnl =
        (currentPrice - trade.entryPrice) * trade.remainingQuantity * direction;
    final double remainingRatio = trade.remainingQuantity / trade.initialQuantity;
    trade.realizedPnlUsdt += pnl;
    _creditBalance(
        trade.market, ((trade.initialMarginUsdt * remainingRatio) + pnl).clamp(0, double.infinity));
    trade.remainingQuantity = 0;
    trade.unrealizedPnlUsdt = 0;
    trade.status = TradeStatus.closed;
    trade.closedAt = DateTime.now();
    DebugLogger.instance.log('SIM-MANUAL', 'Clôture manuelle ${trade.symbol} | PnL: ${trade.realizedPnlUsdt.toStringAsFixed(2)} USDT');
    notifyListeners();
  }

  void _refundAndClose(SimTrade trade, double price, String note) {
    _creditBalance(trade.market, trade.initialMarginUsdt);
    trade.remainingQuantity = 0;
    trade.status = TradeStatus.closed;
    trade.closedAt = DateTime.now();
    DebugLogger.instance.log('SIM-CANCEL', '${trade.symbol}: $note');
  }

  void _creditBalance(TradeMarket market, double amount) {
    if (market == TradeMarket.spot) {
      spotBalanceUsdt += amount;
    } else {
      futuresBalanceUsdt += amount;
    }
  }
}
