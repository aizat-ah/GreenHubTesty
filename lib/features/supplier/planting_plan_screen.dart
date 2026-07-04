// lib/features/supplier/planting_plan_screen.dart
//
// Planting Plan screen (Supplier role).
//
// Reached from the Crop Planting Suggestions screen via the "My Plan"
// button in the header. Gives the supplier a dedicated view of every crop
// they've tapped "Add to planting plan" on (see `plannedCropsProvider`),
// enriched with that crop's latest demand stats when available, so it
// reads as an actual plan rather than just a list of names.
//
// `plannedCropsProvider` streams the plan live from Firestore
// (plannedCrops/{supplierUid}) — see its doc comment in
// crop_suggestion_provider.dart — so the plan persists across app
// restarts and devices.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../models/crop_suggestion_model.dart';
import '../../providers/crop_suggestion_provider.dart';

class PlantingPlanScreen extends ConsumerWidget {
  const PlantingPlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plannedAsync = ref.watch(plannedCropsProvider);
    final resultAsync = ref.watch(cropSuggestionProvider);

    // Match each planned crop name against the latest suggestion data (if
    // available) so we can show real stats. A crop can still be "planned"
    // even if it's since dropped out of the current demand window — it
    // just renders with a lighter, stat-less card.
    final knownByName = resultAsync.maybeWhen(
      data: (r) => {
        for (final s in r.allSuggestions) s.cropName.toLowerCase(): s,
      },
      orElse: () => <String, CropSuggestion>{},
    );

    final entries = (plannedAsync.value ?? const <String>{}).toList()..sort();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _Header(onBack: () => context.pop(), count: entries.length),
            Expanded(
              child: plannedAsync.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : entries.isEmpty
                      ? const _EmptyState()
                      : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                      children: [
                        Text(
                          '${entries.length} crop'
                          '${entries.length == 1 ? '' : 's'} in your plan',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.textLight,
                          ),
                        ),
                        const SizedBox(height: 12),
                        for (final name in entries) ...[
                          _PlanCard(
                            cropName: name,
                            suggestion: knownByName[name.toLowerCase()],
                          ),
                          const SizedBox(height: 12),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final VoidCallback onBack;
  final int count;
  const _Header({required this.onBack, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 20, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            color: AppTheme.textDark,
          ),
          const SizedBox(width: 4),
          Text(
            'My Planting Plan',
            style: GoogleFonts.poppins(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
              letterSpacing: -0.3,
            ),
          ),
          const Spacer(),
          if (count > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Plan card ────────────────────────────────────────────────────────────────

class _PlanCard extends ConsumerWidget {
  final String cropName;
  final CropSuggestion? suggestion;
  const _PlanCard({required this.cropName, required this.suggestion});

  Color _badgeColor(DemandLevel level) {
    switch (level) {
      case DemandLevel.hot:
        return const Color(0xFFE76F51);
      case DemandLevel.trending:
        return const Color(0xFF2E7D32);
      case DemandLevel.steady:
        return const Color(0xFF1565C0);
      case DemandLevel.low:
        return AppTheme.textMid;
    }
  }

  Color _badgeBg(DemandLevel level) {
    switch (level) {
      case DemandLevel.hot:
        return const Color(0xFFF4A261).withValues(alpha: 0.16);
      case DemandLevel.trending:
        return const Color(0xFF2E7D32).withValues(alpha: 0.12);
      case DemandLevel.steady:
        return const Color(0xFF1565C0).withValues(alpha: 0.10);
      case DemandLevel.low:
        return AppTheme.surfaceDim;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = suggestion;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDim,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(s?.emoji ?? '🌱',
                    style: const TextStyle(fontSize: 23)),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cropName,
                      style: GoogleFonts.poppins(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 5),
                    if (s != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: _badgeBg(s.demandLevel),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(s.demandLevel.emoji,
                                style: const TextStyle(fontSize: 11)),
                            const SizedBox(width: 4),
                            Text(
                              s.demandLevel.label,
                              style: GoogleFonts.poppins(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: _badgeColor(s.demandLevel),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Text(
                        'No recent demand data for this crop',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: AppTheme.textLight,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => ref
                    .read(plannedCropsControllerProvider)
                    .toggle(cropName),
                icon: const Icon(Icons.close_rounded, size: 20),
                color: AppTheme.textLight,
                tooltip: 'Remove from plan',
              ),
            ],
          ),
          if (s != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MiniStat(
                    label: 'Orders (window)',
                    value: '${s.ordersInWindow}',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MiniStat(
                    label: 'Trend',
                    value: s.trendLabel,
                    valueColor:
                        s.isTrendingUp ? AppTheme.success : AppTheme.error,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MiniStat(
                    label: 'Suggested',
                    value: s.action.label,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              s.reason,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: AppTheme.textMid,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _MiniStat({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDim,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textLight),
          ),
        ],
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Text('📋', style: TextStyle(fontSize: 32)),
            ),
            const SizedBox(height: 18),
            Text(
              'Your planting plan is empty',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap "Add to planting plan" on a crop suggestion to start '
              'building your plan.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppTheme.textMid,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
