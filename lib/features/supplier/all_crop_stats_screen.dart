// lib/features/supplier/all_crop_stats_screen.dart
//
// Full crop stats list (Supplier role).
//
// Reached from the Crop Planting Suggestions screen ("View all crops"
// button). Unlike that screen — which only shows the top-N recommended
// crops — this shows every crop the engine analysed, ranked, so the
// supplier can see which products are selling well and which aren't,
// not just the ones being recommended.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../models/crop_suggestion_model.dart';
import '../../providers/crop_suggestion_provider.dart';

enum _SortBy { rank, orders, trend, name }

final _sortByProvider = StateProvider<_SortBy>((ref) => _SortBy.rank);

class AllCropStatsScreen extends ConsumerWidget {
  const AllCropStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultAsync = ref.watch(cropSuggestionProvider);
    final sortBy = ref.watch(_sortByProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _Header(onBack: () => context.pop()),
            Expanded(
              child: resultAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => _ErrorState(
                  onRetry: () => ref.invalidate(cropSuggestionProvider),
                ),
                data: (result) {
                  if (result.allSuggestions.isEmpty) {
                    return const _EmptyState();
                  }
                  final crops = _sorted(result.allSuggestions, sortBy);
                  return RefreshIndicator(
                    color: AppTheme.primary,
                    onRefresh: () async {
                      ref.invalidate(cropSuggestionProvider);
                      await ref.read(cropSuggestionProvider.future);
                    },
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                      children: [
                        _SortBar(sortBy: sortBy),
                        const SizedBox(height: 14),
                        Text(
                          '${crops.length} crops analyzed · '
                          'last ${result.windowDays} days',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.textLight,
                          ),
                        ),
                        const SizedBox(height: 12),
                        for (final c in crops) ...[
                          _StatRow(suggestion: c),
                          const SizedBox(height: 10),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<CropSuggestion> _sorted(List<CropSuggestion> crops, _SortBy by) {
    final list = List<CropSuggestion>.from(crops);
    switch (by) {
      case _SortBy.rank:
        list.sort((a, b) => a.rank.compareTo(b.rank));
        break;
      case _SortBy.orders:
        list.sort((a, b) => b.ordersInWindow.compareTo(a.ordersInWindow));
        break;
      case _SortBy.trend:
        list.sort((a, b) => b.trendPercent.compareTo(a.trendPercent));
        break;
      case _SortBy.name:
        list.sort(
          (a, b) => a.cropName.toLowerCase().compareTo(b.cropName.toLowerCase()),
        );
        break;
    }
    return list;
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final VoidCallback onBack;
  const _Header({required this.onBack});

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
            'All Crop Stats',
            style: GoogleFonts.poppins(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sort bar ─────────────────────────────────────────────────────────────────

class _SortBar extends ConsumerWidget {
  final _SortBy sortBy;
  const _SortBar({required this.sortBy});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Widget chip(String label, _SortBy value) {
      final selected = sortBy == value;
      return GestureDetector(
        onTap: () => ref.read(_sortByProvider.notifier).state = value,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primary : AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? AppTheme.primary
                  : AppTheme.textLight.withValues(alpha: 0.25),
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppTheme.textMid,
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          chip('Rank', _SortBy.rank),
          const SizedBox(width: 8),
          chip('Most orders', _SortBy.orders),
          const SizedBox(width: 8),
          chip('Trend', _SortBy.trend),
          const SizedBox(width: 8),
          chip('Name', _SortBy.name),
        ],
      ),
    );
  }
}

// ─── Stat row ─────────────────────────────────────────────────────────────────

class _StatRow extends StatelessWidget {
  final CropSuggestion suggestion;
  const _StatRow({required this.suggestion});

  Color get _badgeColor {
    switch (suggestion.demandLevel) {
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

  Color get _badgeBg {
    switch (suggestion.demandLevel) {
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
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.surfaceDim,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Text(suggestion.emoji, style: const TextStyle(fontSize: 21)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        suggestion.cropName,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '#${suggestion.rank}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppTheme.textLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${suggestion.ordersInWindow} orders '
                  '(was ${suggestion.ordersPreviousWindow})',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.textMid,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _badgeBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  suggestion.demandLevel.label,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _badgeColor,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    suggestion.isTrendingUp
                        ? Icons.arrow_drop_up_rounded
                        : Icons.arrow_drop_down_rounded,
                    color: suggestion.isTrendingUp
                        ? AppTheme.success
                        : AppTheme.error,
                    size: 18,
                  ),
                  Text(
                    suggestion.trendLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: suggestion.isTrendingUp
                          ? AppTheme.success
                          : AppTheme.error,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Error / empty states ───────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded,
                size: 38, color: AppTheme.textLight.withValues(alpha: 0.5)),
            const SizedBox(height: 14),
            Text(
              'Couldn\'t load crop stats',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Not enough order history yet to show crop stats.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textMid),
        ),
      ),
    );
  }
}
