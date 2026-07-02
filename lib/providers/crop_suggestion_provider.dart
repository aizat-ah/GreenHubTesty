// lib/providers/crop_suggestion_provider.dart
//
// Riverpod wiring for the AI Crop Planting Suggestion feature.
//
// - `cropSuggestionServiceProvider` exposes the service.
// - `cropSuggestionProvider` is a FutureProvider that runs the engine and
//   hands the screen an AsyncValue<CropSuggestionResult>. Pull-to-refresh /
//   the header refresh button just `ref.invalidate` it.
// - `plannedCropsProvider` keeps the set of crops the supplier has tapped
//   "Add to planting plan" on, so the UI can flip the button to a done
//   state (session-local; persist to Firestore if you need it to survive
//   app restarts).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../models/crop_suggestion_model.dart';
import '../services/crop_suggestion_service.dart';

final cropSuggestionServiceProvider = Provider<CropSuggestionService>(
  (ref) => CropSuggestionService(),
);

/// The demand window in days — kept as a provider so it could later be made
/// user-configurable from the screen.
final demandWindowProvider = StateProvider<int>((ref) => 14);

/// Runs the suggestion engine. Re-runs whenever the window changes or the
/// provider is invalidated (refresh).
final cropSuggestionProvider =
    FutureProvider<CropSuggestionResult>((ref) async {
  final service = ref.watch(cropSuggestionServiceProvider);
  final window = ref.watch(demandWindowProvider);
  return service.generateSuggestions(windowDays: window, topN: 4);
});

/// Crop names the supplier has added to their planting plan this session.
class PlannedCropsNotifier extends StateNotifier<Set<String>> {
  PlannedCropsNotifier() : super(const {});

  void toggle(String cropName) {
    final next = Set<String>.from(state);
    if (next.contains(cropName)) {
      next.remove(cropName);
    } else {
      next.add(cropName);
    }
    state = next;
  }

  bool isPlanned(String cropName) => state.contains(cropName);
}

final plannedCropsProvider =
    StateNotifierProvider<PlannedCropsNotifier, Set<String>>(
  (ref) => PlannedCropsNotifier(),
);