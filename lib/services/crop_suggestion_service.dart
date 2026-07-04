// lib/services/crop_suggestion_service.dart
//
// Produces AI crop-planting suggestions for the supplier.
//
// Strategy:
//   1. Pull the recent order history (last `windowDays * 2` days) so we can
//      compare the current window against the previous one.
//   2. Try the trained TensorFlow model (`_DemandModel`). If the model asset
//      is missing, fails to load, or throws at inference time, we DON'T crash
//      — we log and fall back to a transparent demand-trend heuristic.
//   3. Either way we return a `CropSuggestionResult` tagged with its
//      `SuggestionSource`, so the UI can show the right disclaimer.
//
// The heuristic ranks crops purely on recent sales volume + trend, which is
// exactly what the SRS calls for as the graceful-degradation path.

import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import '../models/order_model.dart';
import '../models/crop_suggestion_model.dart';

class CropSuggestionService {
  CropSuggestionService({DemandModelPredictor? model})
      : _model = model ?? DemandModelPredictor();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final DemandModelPredictor _model;

  CollectionReference get _orders => _db.collection('orders');

  /// Emoji lookup for common Sabah produce. Falls back to a seedling.
  static const Map<String, String> _emojiFor = {
    'sayur manis': '🥬',
    'terung': '🍆',
    'pisang': '🍌',
    'cili padi': '🌶️',
    'ubi kayu': '🍠',
    'tomato': '🍅',
    'timun': '🥒',
    'bayam': '🥬',
    'kangkung': '🥬',
    'jagung': '🌽',
    'nanas': '🍍',
    'betik': '🍈',
  };

  /// Main entry point used by the provider.
  ///
  /// [windowDays] is the demand window (default 14). [topN] caps how many
  /// crops are surfaced on the screen.
  Future<CropSuggestionResult> generateSuggestions({
    int windowDays = 14,
    int topN = 4,
  }) async {
    final now = DateTime.now();
    final windowStart = now.subtract(Duration(days: windowDays));
    final prevWindowStart = now.subtract(Duration(days: windowDays * 2));

    // ── 1. Gather recent demand, aggregated per crop ────────────────────────
    final demand = await _aggregateDemand(
      since: prevWindowStart,
      windowStart: windowStart,
      windowDays: windowDays,
    );

    if (demand.isEmpty) {
      return CropSuggestionResult(
        suggestions: const [],
        allSuggestions: const [],
        source: SuggestionSource.heuristicFallback,
        generatedAt: now,
        windowDays: windowDays,
        cropsAnalyzed: 0,
      );
    }

    // ── 2. Try the AI model, fall back to the heuristic ─────────────────────
    SuggestionSource source;
    List<CropSuggestion> ranked;
    try {
      // Build each crop's [week1, week2, week3, week4] input vector from
      // its full daily-bucket history — this is the model's expected input.
      final entries = demand.entries.toList();
      final weeklyHistories = entries
          .map((e) => _weeklyQuantities(e.value.dailyBuckets))
          .toList();

      final scores = await _model.rankDemand(weeklyHistories);
      ranked = _buildSuggestions(
        demand,
        modelScores: scores,
        windowDays: windowDays,
      );
      source = SuggestionSource.aiModel;
    } catch (e) {
      // Model unavailable → transparent heuristic. This is expected if the
      // .tflite asset is missing, the input shape doesn't match (e.g.
      // windowDays was changed to something not a multiple of 7), or
      // inference otherwise fails — and must never surface as an error to
      // the supplier.
      // ignore: avoid_print
      print('[CropSuggestionService] AI model unavailable, '
          'falling back to heuristic: $e');
      ranked = _buildSuggestions(demand, modelScores: null, windowDays: windowDays);
      source = SuggestionSource.heuristicFallback;
    }

    ranked.sort((a, b) => a.rank.compareTo(b.rank));
    final top = ranked.take(topN).toList();

    return CropSuggestionResult(
      suggestions: top,
      allSuggestions: ranked,
      source: source,
      generatedAt: now,
      windowDays: windowDays,
      cropsAnalyzed: demand.length,
    );
  }

  // ─── Demand aggregation ───────────────────────────────────────────────────
  //
  // NOTE: dailyBuckets now spans the FULL `windowDays * 2` range (not just
  // the current window) — this is what changed to support the real AI
  // model, which needs 4 full weeks (28 days) of history. The heuristic
  // path's sparkline still only uses the current-window slice; see
  // `_buildSuggestions` where it's sliced back down.

  Future<Map<String, _CropDemand>> _aggregateDemand({
    required DateTime since,
    required DateTime windowStart,
    required int windowDays,
  }) async {
    final snap = await _orders
        .where('createdAt', isGreaterThanOrEqualTo: since)
        .get();

    final totalDays = windowDays * 2;
    final map = <String, _CropDemand>{};

    for (final doc in snap.docs) {
      final order =
          OrderModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);

      // Cancelled orders don't represent real demand.
      if (order.status == OrderStatus.cancelled) continue;

      final inCurrentWindow = order.createdAt.isAfter(windowStart);

      for (final item in order.items) {
        final key = item.productName.trim().toLowerCase();
        if (key.isEmpty) continue;

        final d = map.putIfAbsent(
          key,
          () => _CropDemand(
            name: _titleCase(item.productName.trim()),
            category: '',
            dailyBuckets: List<int>.filled(totalDays, 0),
          ),
        );

        // Place this order's quantity into its day bucket across the FULL
        // range (0 = oldest day, totalDays-1 = today), regardless of which
        // window it falls in — the AI model needs the older half too.
        final daysAgo = DateTime.now().difference(order.createdAt).inDays;
        final dayIndex = totalDays - 1 - daysAgo;
        if (dayIndex >= 0 && dayIndex < totalDays) {
          d.dailyBuckets[dayIndex] += item.quantity;
        }

        if (inCurrentWindow) {
          d.currentOrders += 1;
          d.currentUnits += item.quantity;
        } else {
          d.previousOrders += 1;
        }
      }
    }

    return map;
  }

  /// Splits a full daily-bucket history into 7-day weekly totals,
  /// oldest → newest. This is the AI model's input format — it expects
  /// exactly 4 weeks, which is what you get when `windowDays = 14`
  /// (the default) since `totalDays = 28 = 4 × 7`.
  ///
  /// If `demandWindowProvider` is ever changed to something that isn't a
  /// multiple of 7 days, this won't produce exactly 4 weeks, the model
  /// call will fail its shape check, and the service safely falls back
  /// to the heuristic (see the try/catch in `generateSuggestions`).
  List<double> _weeklyQuantities(List<int> dailyBuckets) {
    const weekSize = 7;
    final weekCount = dailyBuckets.length ~/ weekSize;
    final weeks = <double>[];
    for (var w = 0; w < weekCount; w++) {
      final start = w * weekSize;
      final sum = dailyBuckets
          .sublist(start, start + weekSize)
          .fold<int>(0, (a, b) => a + b);
      weeks.add(sum.toDouble());
    }
    return weeks;
  }

  // ─── Suggestion construction ──────────────────────────────────────────────

  List<CropSuggestion> _buildSuggestions(
    Map<String, _CropDemand> demand, {
    required List<double>? modelScores,
    required int windowDays,
  }) {
    final entries = demand.entries.toList();

    // Score each crop. Model scores (when present) drive the ranking;
    // otherwise we compute a heuristic score = volume weighted by trend.
    final scored = <_ScoredCrop>[];
    for (var i = 0; i < entries.length; i++) {
      final d = entries[i].value;
      final trend = _trendPercent(d.currentOrders, d.previousOrders);
      final heuristicScore =
          d.currentOrders * (1 + (trend.clamp(-50, 200) / 100));
      final score = (modelScores != null && i < modelScores.length)
          ? modelScores[i]
          : heuristicScore;
      scored.add(_ScoredCrop(demand: d, trend: trend, score: score));
    }

    scored.sort((a, b) => b.score.compareTo(a.score));

    final result = <CropSuggestion>[];
    for (var i = 0; i < scored.length; i++) {
      final s = scored[i];
      final d = s.demand;
      final level = _demandLevel(d.currentOrders, s.trend);
      final action = _action(level, d);

      result.add(
        CropSuggestion(
          cropName: d.name,
          emoji: _emojiFor[d.name.toLowerCase()] ?? '🌱',
          category: d.category,
          rank: i + 1,
          ordersInWindow: d.currentOrders,
          ordersPreviousWindow: d.previousOrders,
          trendPercent: s.trend,
          demandLevel: level,
          action: action,
          reason: _reason(d, s.trend, level),
          sparkline: _normalise(
            // dailyBuckets now spans the full windowDays*2 history — slice
            // back down to just the current window for the sparkline, so
            // it still shows "recent trend" rather than the full 4 weeks.
            d.dailyBuckets.sublist(d.dailyBuckets.length - windowDays),
          ),
        ),
      );
    }
    return result;
  }

  double _trendPercent(int current, int previous) {
    if (previous <= 0) return current > 0 ? 100.0 : 0.0;
    return ((current - previous) / previous) * 100.0;
  }

  DemandLevel _demandLevel(int orders, double trend) {
    if (orders >= 25 && trend >= 25) return DemandLevel.hot;
    if (trend >= 20) return DemandLevel.trending;
    if (orders >= 10) return DemandLevel.steady;
    return DemandLevel.low;
  }

  SuggestedAction _action(DemandLevel level, _CropDemand d) {
    switch (level) {
      case DemandLevel.hot:
        // Hot + shrinking supply signal → restock; otherwise plant more.
        return d.currentUnits > d.currentOrders * 3
            ? SuggestedAction.restock
            : SuggestedAction.plantMore;
      case DemandLevel.trending:
        return SuggestedAction.plantMore;
      case DemandLevel.steady:
        return SuggestedAction.maintain;
      case DemandLevel.low:
        return SuggestedAction.maintain;
    }
  }

  String _reason(_CropDemand d, double trend, DemandLevel level) {
    final t = trend.round();
    switch (level) {
      case DemandLevel.hot:
        return '${d.currentOrders} orders in the last window — up $t% '
            'from ${d.previousOrders} the prior fortnight.';
      case DemandLevel.trending:
        return '${d.currentOrders} orders this window, climbing $t% '
            'week over week.';
      case DemandLevel.steady:
        return 'Reliable demand — ${d.currentOrders} orders holding steady.';
      case DemandLevel.low:
        return 'Only ${d.currentOrders} orders recently — low priority.';
    }
  }

  /// Normalise daily buckets to 0.0–1.0 for the sparkline, keeping a small
  /// floor so empty days still render a visible sliver.
  List<double> _normalise(List<int> buckets) {
    // Compress a long daily series into ~7 bars for the compact card UI.
    const targetBars = 7;
    final step = max(1, (buckets.length / targetBars).ceil());
    final bars = <int>[];
    for (var i = 0; i < buckets.length; i += step) {
      var sum = 0;
      for (var j = i; j < min(i + step, buckets.length); j++) {
        sum += buckets[j];
      }
      bars.add(sum);
    }
    final peak = bars.fold<int>(0, max);
    if (peak == 0) return List<double>.filled(bars.length, 0.15);
    return bars.map((b) => 0.15 + (b / peak) * 0.85).toList();
  }

  static String _titleCase(String input) => input
      .split(' ')
      .where((w) => w.isNotEmpty)
      .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
      .join(' ');
}

// ─── Internal aggregation holder ──────────────────────────────────────────────

class _CropDemand {
  _CropDemand({
    required this.name,
    required this.category,
    required this.dailyBuckets,
  });

  final String name;
  final String category;
  final List<int> dailyBuckets;

  int currentOrders = 0;
  int previousOrders = 0;
  int currentUnits = 0;
}

class _ScoredCrop {
  _ScoredCrop({
    required this.demand,
    required this.trend,
    required this.score,
  });

  final _CropDemand demand;
  final double trend;
  final double score;
}

// ─── TensorFlow demand model wrapper ──────────────────────────────────────────
//
// Runs the trained crop_demand.tflite model (see ml_training/ for the
// Python training script — a small neural net trained on synthetic
// demand-curve patterns, since real order history is too sparse to train
// from directly).
//
// Input:  4 numbers — a crop's order quantity for each of the last 4
//         weeks (oldest → newest), NORMALIZED by dividing by their own
//         mean. Normalizing makes the model scale-invariant: it learned
//         the general SHAPE of trends (accelerating growth, decline,
//         plateaus) from synthetic data, not absolute volumes, so it
//         transfers to your real (much smaller-scale) marketplace data.
// Output: 1 number — predicted next-week quantity, in the same
//         normalized space. We multiply back by the original mean to get
//         an absolute predicted quantity, which becomes the demand score
//         directly (a crop predicted to have high volume next week ranks
//         higher — this naturally blends "popular" and "trending" the
//         same way the heuristic score does).
//
// If the asset is missing, fails to load, or a crop's history isn't
// exactly 4 weeks (e.g. windowDays was changed to something not a
// multiple of 7), this throws and the service's outer try/catch in
// generateSuggestions() cleanly falls back to the heuristic — this must
// never surface as an error to the supplier.



class ModelUnavailableException implements Exception {
  final String message;
  ModelUnavailableException([this.message = 'Demand model not loaded']);
  @override
  String toString() => 'ModelUnavailableException: $message';
}

class DemandModelPredictor {
  static const String _assetPath = 'assets/models/crop_demand.tflite';
  static const int _expectedWeeks = 4;
  static const double _epsilon = 1e-6;

  Interpreter? _interpreter;

  Future<void> _ensureLoaded() async {
    if (_interpreter != null) return;
    try {
      _interpreter = await Interpreter.fromAsset(_assetPath);
    } catch (e) {
      throw ModelUnavailableException('Failed to load $_assetPath: $e');
    }
  }

  /// Returns a demand score per crop, in the same order as
  /// [weeklyHistories]. Each entry must be exactly 4 weekly quantities
  /// (oldest → newest). Throws [ModelUnavailableException] if the model
  /// can't load or an input doesn't match the expected shape.
  Future<List<double>> rankDemand(List<List<double>> weeklyHistories) async {
    await _ensureLoaded();
    final interpreter = _interpreter;
    if (interpreter == null) {
      throw ModelUnavailableException('Interpreter not available');
    }

    final scores = <double>[];

    for (final weeks in weeklyHistories) {
      if (weeks.length != _expectedWeeks) {
        throw ModelUnavailableException(
          'Expected $_expectedWeeks weeks of history, got ${weeks.length}',
        );
      }

      final mean = weeks.reduce((a, b) => a + b) / weeks.length + _epsilon;
      final normalizedInput = [weeks.map((w) => w / mean).toList()];
      final output = [List.filled(1, 0.0)];

      interpreter.run(normalizedInput, output);

      final predictedNormalized = output[0][0];
      scores.add(predictedNormalized * mean);
    }

    return scores;
  }

  /// Call when the service is no longer needed (e.g. app shutdown) to
  /// free native resources. Not required for correctness during normal
  /// use — the interpreter is small and reused across calls.
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}
