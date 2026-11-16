class ScanPreset {
  final String id;
  final String name;
  final String description;
  int requiredRankJumps;
  int windowSeconds;
  double minVolume24hUsdt;
  double minPriceChange1d;
  bool specialTokensOnly;

  ScanPreset({
    required this.id,
    required this.name,
    required this.description,
    required this.requiredRankJumps,
    required this.windowSeconds,
    required this.minVolume24hUsdt,
    required this.minPriceChange1d,
    this.specialTokensOnly = false,
  });

  static List<ScanPreset> defaults() => [
        ScanPreset(
          id: 'scalp_ultra',
          name: 'Ultra-Sensible (Scalping)',
          description: 'Détecte dès 3 montées de rang en 90s. Très réactif.',
          requiredRankJumps: 3,
          windowSeconds: 90,
          minVolume24hUsdt: 5000000,
          minPriceChange1d: 1.5,
        ),
        ScanPreset(
          id: 'intraday_balanced',
          name: 'Équilibré (Intraday)',
          description: '5 montées de rang en 3 min + volume solide.',
          requiredRankJumps: 5,
          windowSeconds: 180,
          minVolume24hUsdt: 15000000,
          minPriceChange1d: 3.0,
        ),
        ScanPreset(
          id: 'swing_explosion',
          name: 'Gros Breakout (Swing)',
          description: '8 montées de rang en 5 min sur forte tendance.',
          requiredRankJumps: 8,
          windowSeconds: 300,
          minVolume24hUsdt: 30000000,
          minPriceChange1d: 5.0,
        ),
      ];
}
