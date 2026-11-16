enum TradeMarket { spot, futures }
enum TradeSide { long, short }
enum TradeStatus { pendingLimit, open, closed }

class TakeProfitTarget {
  final int index;
  final double targetPct;
  final double closeRatio;
  double targetPrice;
  bool hit;

  TakeProfitTarget({
    required this.index,
    required this.targetPct,
    required this.closeRatio,
    this.targetPrice = 0,
    this.hit = false,
  });
}

class SimTrade {
  final String id;
  final String symbol;
  final TradeMarket market;
  final TradeSide side;
  TradeStatus status;

  final double limitEntryPrice;
  double entryPrice;
  final double initialMarginUsdt;
  final int leverage;
  double remainingQuantity;
  final double initialQuantity;

  double stopLossPrice;
  final double stopLossPct;
  bool breakEvenMoved;
  final List<TakeProfitTarget> tpTargets;

  double realizedPnlUsdt;
  double unrealizedPnlUsdt;
  final DateTime createdAt;
  DateTime? filledAt;
  DateTime? closedAt;
  String triggerReason;

  SimTrade({
    required this.id,
    required this.symbol,
    required this.market,
    required this.side,
    required this.status,
    required this.limitEntryPrice,
    required this.entryPrice,
    required this.initialMarginUsdt,
    required this.leverage,
    required this.initialQuantity,
    required this.stopLossPrice,
    required this.stopLossPct,
    required this.tpTargets,
    required this.triggerReason,
    this.breakEvenMoved = false,
    this.realizedPnlUsdt = 0,
    this.unrealizedPnlUsdt = 0,
    DateTime? createdAt,
  })  : remainingQuantity = initialQuantity,
        createdAt = createdAt ?? DateTime.now();
}
