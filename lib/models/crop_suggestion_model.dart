// lib/models/crop_suggestion_model.dart
//
// Domain model for the AI Crop Planting Suggestion feature.
//
// A CropSuggestion is a single recommendation produced by the suggestion
// engine (see CropSuggestionService). The engine either runs the trained
// TensorFlow demand model OR — when that model can't be loaded/run — falls
// back to a demand-trend heuristic computed straight from recent orders.
// `SuggestionSource` records which path produced the result so the UI can
// show the correct disclaimer.

/// Where a suggestion batch came from.
enum SuggestionSource { aiModel, heuristicFallback }

extension SuggestionSourceExt on SuggestionSource {
  String get label {
    switch (this) {
      case SuggestionSource.aiModel:
        return 'AI model · TensorFlow';
      case SuggestionSource.heuristicFallback:
        return 'Demand-trend heuristic';
    }
  }

  bool get isAi => this == SuggestionSource.aiModel;
}

/// How strong / urgent the demand signal is for a crop.
enum DemandLevel { hot, trending, steady, low }

extension DemandLevelExt on DemandLevel {
  String get label {
    switch (this) {
      case DemandLevel.hot:
        return 'Hot demand';
      case DemandLevel.trending:
        return 'Trending';
      case DemandLevel.steady:
        return 'Steady';
      case DemandLevel.low:
        return 'Low demand';
    }
  }

  String get emoji {
    switch (this) {
      case DemandLevel.hot:
        return '🔥';
      case DemandLevel.trending:
        return '📈';
      case DemandLevel.steady:
        return '🌿';
      case DemandLevel.low:
        return '💤';
    }
  }
}

/// What the supplier is advised to do about the crop.
enum SuggestedAction { plantMore, restock, maintain }

extension SuggestedActionExt on SuggestedAction {
  String get label {
    switch (this) {
      case SuggestedAction.plantMore:
        return 'Add to planting plan';
      case SuggestedAction.restock:
        return 'Restock now';
      case SuggestedAction.maintain:
        return 'Keep steady';
    }
  }

  String get emoji {
    switch (this) {
      case SuggestedAction.plantMore:
        return '🌱';
      case SuggestedAction.restock:
        return '📦';
      case SuggestedAction.maintain:
        return '🌿';
    }
  }
}

/// A single crop recommendation.
class CropSuggestion {
  final String cropName;
  final String emoji;
  final String category;

  /// 1-based rank within the batch (1 = strongest recommendation).
  final int rank;

  /// Order count inside the demand window (e.g. last 14 days).
  final int ordersInWindow;

  /// Order count in the window immediately before it (for trend maths).
  final int ordersPreviousWindow;

  /// Percentage change vs the previous window. Positive = growing.
  final double trendPercent;

  final DemandLevel demandLevel;
  final SuggestedAction action;

  /// One-line human explanation shown on the card.
  final String reason;

  /// Small normalised series (0.0–1.0) driving the sparkline bars.
  final List<double> sparkline;

  const CropSuggestion({
    required this.cropName,
    required this.emoji,
    required this.category,
    required this.rank,
    required this.ordersInWindow,
    required this.ordersPreviousWindow,
    required this.trendPercent,
    required this.demandLevel,
    required this.action,
    required this.reason,
    required this.sparkline,
  });

  bool get isTrendingUp => trendPercent >= 0;

  String get trendLabel =>
      '${trendPercent >= 0 ? '+' : ''}${trendPercent.toStringAsFixed(0)}%';

  CropSuggestion copyWith({int? rank}) {
    return CropSuggestion(
      cropName: cropName,
      emoji: emoji,
      category: category,
      rank: rank ?? this.rank,
      ordersInWindow: ordersInWindow,
      ordersPreviousWindow: ordersPreviousWindow,
      trendPercent: trendPercent,
      demandLevel: demandLevel,
      action: action,
      reason: reason,
      sparkline: sparkline,
    );
  }
}

/// The full result returned by the suggestion engine for one run.
class CropSuggestionResult {
  final List<CropSuggestion> suggestions;
  final SuggestionSource source;
  final DateTime generatedAt;

  /// Length of the demand window analysed, in days.
  final int windowDays;

  /// Total distinct crops the engine looked at.
  final int cropsAnalyzed;

  const CropSuggestionResult({
    required this.suggestions,
    required this.source,
    required this.generatedAt,
    required this.windowDays,
    required this.cropsAnalyzed,
  });

  int get highDemandCount => suggestions
      .where((s) =>
          s.demandLevel == DemandLevel.hot ||
          s.demandLevel == DemandLevel.trending)
      .length;

  bool get isFallback => source == SuggestionSource.heuristicFallback;
}