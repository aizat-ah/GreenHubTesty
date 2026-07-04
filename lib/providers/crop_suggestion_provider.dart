// lib/providers/crop_suggestion_provider.dart
//
// Riverpod wiring for the AI Crop Planting Suggestion feature.
//
// - `cropSuggestionServiceProvider` exposes the service.
// - `cropSuggestionProvider` is a FutureProvider that runs the engine and
//   hands the screen an AsyncValue<CropSuggestionResult>. Pull-to-refresh /
//   the header refresh button just `ref.invalidate` it.
// - `plannedCropsProvider` streams the set of crops the current supplier
//   has added to their planting plan, from Firestore
//   (plannedCrops/{supplierUid}), so it survives app restarts and syncs
//   across devices. Writes go through `plannedCropsControllerProvider`.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../models/crop_suggestion_model.dart';
import '../services/crop_suggestion_service.dart';
import '../services/planned_crops_service.dart';
import 'auth_provider.dart';

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

final plannedCropsServiceProvider = Provider<PlannedCropsService>(
  (ref) => PlannedCropsService(),
);

/// Crop names the current supplier has added to their planting plan,
/// streamed live from Firestore. Empty (not an error) while logged out.
final plannedCropsProvider = StreamProvider<Set<String>>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.when(
    data: (user) {
      if (user == null) return Stream.value(<String>{});
      return ref.watch(plannedCropsServiceProvider).streamPlannedCrops(user.uid);
    },
    loading: () => Stream.value(<String>{}),
    error: (_, _) => Stream.value(<String>{}),
  );
});

/// Write-side actions for the planting plan — kept separate from
/// `plannedCropsProvider` since that's a read-only Firestore stream.
class PlannedCropsController {
  PlannedCropsController(this._ref);
  final Ref _ref;

  Future<void> toggle(String cropName) async {
    final user = await _ref.read(currentUserProvider.future);
    if (user == null) return;
    await _ref.read(plannedCropsServiceProvider).toggle(user.uid, cropName);
  }
}

final plannedCropsControllerProvider = Provider<PlannedCropsController>(
  (ref) => PlannedCropsController(ref),
);