class PeriodMetric {
  final double priceChangePct;
  final double volumeChangePct;

  const PeriodMetric({
    required this.priceChangePct,
    required this.volumeChangePct,
  });

  bool get isBullish => priceChangePct >= 0;
}

class TokenData {
  final String symbol;
  final String baseAsset;
  double currentPrice;
  double priceChange24hPct;
  double quoteVolume24h;
  double high24h;
  double low24h;

  int currentRank;
  int previousRank;
  int rankDeltaAccumulator;
  final List<DateTime> upwardMoveTimestamps;
  DateTime? lastAlertTime;

  Map<String, PeriodMetric> historicalMetrics;
  bool historyLoaded;
  bool isSpecial;

  TokenData({
    required this.symbol,
    required this.baseAsset,
    required this.currentPrice,
    required this.priceChange24hPct,
    required this.quoteVolume24h,
    required this.high24h,
    required this.low24h,
    this.currentRank = 0,
    this.previousRank = 0,
    this.rankDeltaAccumulator = 0,
    List<DateTime>? upwardMoveTimestamps,
    this.lastAlertTime,
    Map<String, PeriodMetric>? historicalMetrics,
    this.historyLoaded = false,
    this.isSpecial = false,
  })  : upwardMoveTimestamps = upwardMoveTimestamps ?? [],
        historicalMetrics = historicalMetrics ??
            {
              '1J': PeriodMetric(priceChangePct: priceChange24hPct, volumeChangePct: 0),
              '7J': const PeriodMetric(priceChangePct: 0, volumeChangePct: 0),
              '30J': const PeriodMetric(priceChangePct: 0, volumeChangePct: 0),
              '90J': const PeriodMetric(priceChangePct: 0, volumeChangePct: 0),
              '180J': const PeriodMetric(priceChangePct: 0, volumeChangePct: 0),
            };
}
