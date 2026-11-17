import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/scan_preset.dart';
import '../models/token_data.dart';
import 'debug_logger.dart';
import 'notification_service.dart';
import 'simulator_engine.dart';

class BinanceService extends ChangeNotifier {
  final SimulatorEngine simulator;

  BinanceService({required this.simulator});

  WebSocketChannel? _channel;
  StreamSubscription? _wsSub;
  Timer? _reconnectTimer;
  Timer? _uiThrottleTimer;

  bool isScanning = false;
  bool isConnected = false;

  double btcPrice = 0.0;
  double btcChange24hPct = 0.0;
  final List<double> _btcRecentPrices = [];
  bool get isBtcBullish {
    if (_btcRecentPrices.length < 10) return btcChange24hPct >= 0;
    final avg = _btcRecentPrices.reduce((a, b) => a + b) / _btcRecentPrices.length;
    return btcPrice >= avg && btcChange24hPct > -1.5;
  }

  final Map<String, TokenData> _tokensMap = {};
  List<TokenData> _rankedList = [];
  List<TokenData> get rankedTokens {
    if (activePreset.specialTokensOnly) {
      return _rankedList.where((t) => t.isSpecial).toList();
    }
    return _rankedList;
  }

  final List<ScanPreset> presets = ScanPreset.defaults();
  int selectedPresetIndex = 0;
  ScanPreset get activePreset => presets[selectedPresetIndex];

  final Set<String> _historyFetching = {};
  bool _dirty = false;

  void selectPreset(int index) {
    selectedPresetIndex = index;
    DebugLogger.instance.log(
      'SCANNER',
      'Profil sélectionné: ${activePreset.name} (${activePreset.requiredRankJumps} sauts / ${activePreset.windowSeconds}s)',
    );
    notifyListeners();
  }

  void toggleSpecialToken(String symbol) {
    final token = _tokensMap[symbol];
    if (token != null) {
      token.isSpecial = !token.isSpecial;
      DebugLogger.instance.log(
        'WATCHLIST',
        '${token.symbol} ${token.isSpecial ? "ajouté aux" : "retiré des"} Jetons Spéciaux.',
      );
      notifyListeners();
    }
  }

  Future<void> startScanner() async {
    if (isScanning) return;
    isScanning = true;
    DebugLogger.instance.log('WS', 'Démarrage du flux WebSocket Binance (!ticker@arr)...');
    notifyListeners();

    _connectWebSocket();

    // Rafraîchissement fluide de l'UI pour éviter les surcharges de notifications
    _uiThrottleTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (_dirty) {
        _dirty = false;
        notifyListeners();
      }
    });
  }

  void stopScanner() {
    isScanning = false;
    isConnected = false;
    _reconnectTimer?.cancel();
    _uiThrottleTimer?.cancel();
    _wsSub?.cancel();
    _channel?.sink.close();
    DebugLogger.instance.log('WS', 'Scanner WebSocket arrêté manuellement.');
    notifyListeners();
  }

  void _connectWebSocket() {
    try {
      // Utilisation du port 443 standard (universellement autorisé)
      final uri = Uri.parse('wss://stream.binance.com/ws/!ticker@arr');
      DebugLogger.instance.log('WS', 'Connexion à l\'URI WebSocket: $uri');
      
      _channel = WebSocketChannel.connect(uri);
      isConnected = true;
      DebugLogger.instance.log('WS', 'Connecté au flux WebSocket Binance.');

      _wsSub = _channel!.stream.listen(
        (rawMessage) => _handleTickerArray(rawMessage),
        onError: (err) {
          isConnected = false;
          DebugLogger.instance.log('WS-ERROR', 'Erreur WebSocket: $err');
          _scheduleReconnect();
        },
        onDone: () {
          isConnected = false;
          DebugLogger.instance.log('WS', 'Flux WebSocket fermé par le serveur.');
          if (isScanning) _scheduleReconnect();
        },
      );
    } catch (e) {
      isConnected = false;
      DebugLogger.instance.log('WS-ERROR', 'Exception connexion WebSocket: $e');
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (!isScanning) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      DebugLogger.instance.log('WS', 'Tentative de reconnexion WebSocket...');
      _connectWebSocket();
    });
  }

  void _handleTickerArray(dynamic rawMessage) {
    try {
      final List<dynamic> tickers = jsonDecode(rawMessage as String);
      final now = DateTime.now();
      int count = 0;

      for (final item in tickers) {
        // Clés abrégées officielles du flux WebSocket Binance !ticker@arr
        final String symbol = item['s'] ?? '';
        if (!symbol.endsWith('USDT')) continue;
        if (symbol.contains('UPUSDT') ||
            symbol.contains('DOWNUSDT') ||
            symbol.contains('BULLUSDT') ||
            symbol.contains('BEARUSDT')) {
          continue;
        }

        final double lastPrice = double.tryParse(item['c'] ?? '0') ?? 0;
        final double pricePct24h = double.tryParse(item['P'] ?? '0') ?? 0;
        final double quoteVol = double.tryParse(item['q'] ?? '0') ?? 0;
        final double high = double.tryParse(item['h'] ?? '0') ?? 0;
        final double low = double.tryParse(item['l'] ?? '0') ?? 0;

        if (lastPrice <= 0) continue;

        count++;

        if (symbol == 'BTCUSDT') {
          btcPrice = lastPrice;
          btcChange24hPct = pricePct24h;
          _btcRecentPrices.add(lastPrice);
          if (_btcRecentPrices.length > 60) {
            _btcRecentPrices.removeAt(0);
          }
        }

        simulator.onPriceTick(symbol, lastPrice);

        if (quoteVol < activePreset.minVolume24hUsdt &&
            !(_tokensMap[symbol]?.isSpecial ?? false)) {
          continue;
        }

        final existing = _tokensMap[symbol];
        if (existing == null) {
          _tokensMap[symbol] = TokenData(
            symbol: symbol,
            baseAsset: symbol.replaceAll('USDT', ''),
            currentPrice: lastPrice,
            priceChange24hPct: pricePct24h,
            quoteVolume24h: quoteVol,
            high24h: high,
            low24h: low,
          );
        } else {
          existing.currentPrice = lastPrice;
          existing.priceChange24hPct = pricePct24h;
          existing.quoteVolume24h = quoteVol;
          existing.high24h = high;
          existing.low24h = low;
          existing.historicalMetrics['1J'] = PeriodMetric(
            priceChangePct: pricePct24h,
            volumeChangePct: existing.historicalMetrics['1J']?.volumeChangePct ?? 0,
          );
        }
      }

      final list = _tokensMap.values.toList()
        ..sort((a, b) => b.priceChange24hPct.compareTo(a.priceChange24hPct));

      for (int i = 0; i < list.length; i++) {
        final token = list[i];
        final newRank = i + 1;

        if (token.currentRank > 0 && newRank < token.currentRank) {
          final int jumped = token.currentRank - newRank;
          for (int k = 0; k < jumped; k++) {
            token.upwardMoveTimestamps.add(now);
          }
        }

        token.previousRank = token.currentRank == 0 ? newRank : token.currentRank;
        token.currentRank = newRank;

        token.upwardMoveTimestamps.removeWhere(
          (ts) => now.difference(ts).inSeconds > activePreset.windowSeconds,
        );
        token.rankDeltaAccumulator = token.upwardMoveTimestamps.length;

        final bool isEligible = !activePreset.specialTokensOnly || token.isSpecial;
        final bool cooldownOk = token.lastAlertTime == null ||
            now.difference(token.lastAlertTime!).inSeconds > 120;

        if (isEligible &&
            cooldownOk &&
            token.rankDeltaAccumulator >= activePreset.requiredRankJumps &&
            token.priceChange24hPct >= activePreset.minPriceChange1d) {
          token.lastAlertTime = now;
          final btcBiasText = isBtcBullish ? 'HAUSSIER (LONG)' : 'BAISSIER (SHORT)';
          final reason =
              '${token.symbol} a gagné +${token.rankDeltaAccumulator} rangs en ${activePreset.windowSeconds}s (Rang #${token.currentRank})';

          DebugLogger.instance.log('ALERT-EXPLOSION', '🚀 $reason | BTC: $btcBiasText');

          NotificationService.instance.showExplosionAlert(
            symbol: token.symbol,
            jumps: token.rankDeltaAccumulator,
            windowSec: activePreset.windowSeconds,
            price: token.currentPrice,
            change24h: token.priceChange24hPct,
            btcBias: btcBiasText,
          );

          simulator.onTokenSignal(
            token: token,
            isBtcBullish: isBtcBullish,
            reason: reason,
          );
        }

        if (i < 35 && !token.historyLoaded && !_historyFetching.contains(token.symbol)) {
          _fetchHistoricalKlines(token);
        }
      }

      _rankedList = list;
      _dirty = true;
    } catch (e, st) {
      DebugLogger.instance.log('WS-ERROR', 'Erreur de décodage WS: $e');
    }
  }

  Future<void> _fetchHistoricalKlines(TokenData token) async {
    _historyFetching.add(token.symbol);
    try {
      final url = Uri.parse(
          'https://api.binance.com/api/v3/klines?symbol=${token.symbol}&interval=1d&limit=181');
      final res = await http.get(url).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final List<dynamic> klines = jsonDecode(res.body);
        if (klines.length >= 2) {
          final currentClose = double.parse(klines.last[4].toString());
          final currentVol = double.parse(klines.last[7].toString());

          PeriodMetric calcPeriod(int daysAgo) {
            final idx = (klines.length - 1 - daysAgo).clamp(0, klines.length - 1);
            final pastClose = double.parse(klines[idx][4].toString());
            final pastVol = double.parse(klines[idx][7].toString());
            final pPct = pastClose > 0
                ? ((currentClose - pastClose) / pastClose) * 100
                : 0.0;
            final vPct =
                pastVol > 0 ? ((currentVol - pastVol) / pastVol) * 100 : 0.0;
            return PeriodMetric(priceChangePct: pPct, volumeChangePct: vPct);
          }

          token.historicalMetrics = {
            '1J': PeriodMetric(
              priceChangePct: token.priceChange24hPct,
              volumeChangePct: calcPeriod(1).volumeChangePct,
            ),
            '7J': calcPeriod(7),
            '30J': calcPeriod(30),
            '90J': calcPeriod(90),
            '180J': calcPeriod(180),
          };
          token.historyLoaded = true;
          _dirty = true;
        }
      }
    } catch (e) {
      DebugLogger.instance.log('REST-WARN', 'Historique ${token.symbol}: $e');
    } finally {
      _historyFetching.remove(token.symbol);
    }
  }
}
