// lib/features/supplier/crop_suggestion_screen.dart
//
// AI Crop Planting Suggestion screen (Supplier role).
//
// Reached from the Supplier Dashboard "Planting Suggestions" tile
// (route: /supplier/suggestions). Shows AI-generated planting
// recommendations from the demand model, with a transparent heuristic
// fallback when the model isn't available.
//
// Matches the GreenHub design system: rounded-bottom gradient header,
// white 20-radius cards with soft green-tinted shadow, Poppins headings /
// Inter body, primary #2D6A4F actions, orange accent for hot-demand badges.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../models/crop_suggestion_model.dart';
import '../../providers/crop_suggestion_provider.dart';

class CropSuggestionScreen extends ConsumerWidget {
  const CropSuggestionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultAsync = ref.watch(cropSuggestionProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: () async {
          ref.invalidate(cropSuggestionProvider);
          await ref.read(cropSuggestionProvider.future);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Gradient header ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: _Header(
                source: resultAsync.maybeWhen(
                  data: (r) => r.source,
                  orElse: () => SuggestionSource.aiModel,
                ),
                generatedAt: resultAsync.maybeWhen(
                  data: (r) => r.generatedAt,
                  orElse: () => DateTime.now(),
                ),
                onRefresh: () => ref.invalidate(cropSuggestionProvider),
              ),
            ),

            // ── Body ─────────────────────────────────────────────────────
            resultAsync.when(
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: _ErrorState(onRetry: () {
                  ref.invalidate(cropSuggestionProvider);
                }),
              ),
              data: (result) => SliverToBoxAdapter(
                child: _Body(result: result),
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
  final SuggestionSource source;
  final DateTime generatedAt;
  final VoidCallback onRefresh;

  const _Header({
    required this.source,
    required this.generatedAt,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: back + refresh
              Row(
                children: [
                  _CircleIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => context.pop(),
                  ),
                  const Spacer(),
                  _CircleIconButton(
                    icon: Icons.refresh_rounded,
                    onTap: onRefresh,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Title
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🌱', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'Crop Planting Suggestions',
                      style: GoogleFonts.poppins(
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.4,
                        height: 1.15,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Text(
                'Based on recent market demand in Sabah',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  color: Colors.white.withValues(alpha: 0.65),
                ),
              ),
              const SizedBox(height: 16),

              // Source chip + updated timestamp
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                    decoration: BoxDecoration(
                      color: source.isAi
                          ? const Color(0xFFF4A261).withValues(alpha: 0.18)
                          : Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(
                        color: source.isAi
                            ? const Color(0xFFF4A261).withValues(alpha: 0.35)
                            : Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(source.isAi ? '✨' : '📊',
                            style: const TextStyle(fontSize: 12)),
                        const SizedBox(width: 6),
                        Text(
                          source.label,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: source.isAi
                                ? const Color(0xFFF4A261)
                                : Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Updated ${_relative(generatedAt)}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Body ─────────────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  final CropSuggestionResult result;
  const _Body({required this.result});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary strip
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Row(
            children: [
              _SummaryCard(
                value: '${result.cropsAnalyzed}',
                label: 'crops analyzed',
                color: AppTheme.primary,
              ),
              const SizedBox(width: 12),
              _SummaryCard(
                value: '${result.highDemandCount}',
                label: 'high demand',
                color: AppTheme.warning,
              ),
              const SizedBox(width: 12),
              _SummaryCard(
                value: '${result.windowDays}d',
                label: 'demand window',
                color: AppTheme.info,
              ),
            ],
          ),
        ),

        if (result.suggestions.isEmpty) ...[
          // No recent order history to analyze yet.
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: _EmptyState(),
          ),
        ] else ...[
          // Section header
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 12),
            child: Row(
              children: [
                Text(
                  'Top Recommended Crops',
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                    letterSpacing: -0.3,
                  ),
                ),
                const Spacer(),
                Text(
                  'RANKED',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textLight,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),

          // Crop cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                for (final s in result.suggestions) ...[
                  _CropCard(suggestion: s),
                  const SizedBox(height: 14),
                ],
              ],
            ),
          ),

          // Fallback / disclaimer banner
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
            child: _InfoBanner(isFallback: result.isFallback),
          ),
        ],

        // Footer
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 34),
          child: Center(
            child: Text(
              'Last updated ${_relative(result.generatedAt)} · Pull to refresh',
              style: GoogleFonts.inter(
                fontSize: 11.5,
                color: AppTheme.textLight,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Summary card ─────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String value, label;
  final Color color;
  const _SummaryCard({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(15, 14, 15, 14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
                height: 1,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppTheme.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Crop card ────────────────────────────────────────────────────────────────

class _CropCard extends ConsumerWidget {
  final CropSuggestion suggestion;
  const _CropCard({required this.suggestion});

  // Emoji chip tint per demand level.
  Color get _tint {
    switch (suggestion.demandLevel) {
      case DemandLevel.hot:
        return const Color(0xFFE8F5E9);
      case DemandLevel.trending:
        return const Color(0xFFF3E5F5);
      case DemandLevel.steady:
        return const Color(0xFFFFF8E1);
      case DemandLevel.low:
        return AppTheme.surfaceDim;
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

  Color get _barColor => suggestion.demandLevel == DemandLevel.hot &&
          suggestion.action == SuggestedAction.restock
      ? AppTheme.accent
      : AppTheme.primaryLight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPlanned = ref.watch(plannedCropsProvider).contains(
          suggestion.cropName,
        );

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
          // Top row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Emoji chip
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _tint,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(suggestion.emoji,
                    style: const TextStyle(fontSize: 27)),
              ),
              const SizedBox(width: 13),

              // Name + badge
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            suggestion.cropName,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textDark,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '· #${suggestion.rank}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppTheme.textLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: _badgeBg,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(suggestion.demandLevel.emoji,
                              style: const TextStyle(fontSize: 11)),
                          const SizedBox(width: 4),
                          Text(
                            suggestion.demandLevel.label,
                            style: GoogleFonts.poppins(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: _badgeColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Trend + sparkline
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Icon(
                        suggestion.isTrendingUp
                            ? Icons.arrow_drop_up_rounded
                            : Icons.arrow_drop_down_rounded,
                        color: suggestion.isTrendingUp
                            ? AppTheme.success
                            : AppTheme.error,
                        size: 22,
                      ),
                      Text(
                        suggestion.trendLabel,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: suggestion.isTrendingUp
                              ? AppTheme.success
                              : AppTheme.error,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  _Sparkline(values: suggestion.sparkline, color: _barColor),
                ],
              ),
            ],
          ),

          // Reason
          Padding(
            padding: const EdgeInsets.only(top: 13),
            child: Text(
              suggestion.reason,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppTheme.textMid,
                height: 1.45,
              ),
            ),
          ),

          // Action button
          Padding(
            padding: const EdgeInsets.only(top: 13),
            child: GestureDetector(
              onTap: () {
                ref
                    .read(plannedCropsProvider.notifier)
                    .toggle(suggestion.cropName);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isPlanned
                      ? const Color(0xFFE8F5E9)
                      : AppTheme.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isPlanned ? '✓' : suggestion.action.emoji,
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      isPlanned ? 'Added to plan' : suggestion.action.label,
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: isPlanned
                            ? AppTheme.success
                            : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sparkline ────────────────────────────────────────────────────────────────

class _Sparkline extends StatelessWidget {
  final List<double> values; // normalised 0..1
  final Color color;
  const _Sparkline({required this.values, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 22,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < values.length; i++) ...[
            if (i > 0) const SizedBox(width: 2.5),
            Container(
              width: 4,
              height: (values[i].clamp(0.0, 1.0)) * 22,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Info banner ──────────────────────────────────────────────────────────────

class _InfoBanner extends StatelessWidget {
  final bool isFallback;
  const _InfoBanner({required this.isFallback});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.info.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.info.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.info_outline_rounded,
                size: 17, color: AppTheme.info),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isFallback
                      ? 'Showing demand-trend estimates'
                      : 'How suggestions are made',
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.info,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isFallback
                      ? 'The AI model is unavailable right now, so these '
                          'suggestions default to a demand-trend heuristic '
                          'based on your recent sales volume.'
                      : 'Powered by a TensorFlow model trained on historic '
                          'sales. If the model is unavailable, we fall back '
                          'to a demand-trend heuristic based on your recent '
                          'sales volume.',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: AppTheme.textMid,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Error state ──────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.surfaceDim,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(Icons.cloud_off_rounded,
                size: 38, color: AppTheme.textLight.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 18),
          Text(
            'Couldn\'t load suggestions',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Check your connection and try again.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textLight),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 180,
            child: ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────
//
// Shown when there's no recent order history to analyze — distinct from
// _ErrorState (which is a load/network failure). This is a normal, valid
// outcome (e.g. a brand-new marketplace, or before any demo data is
// seeded), so the tone here is informative rather than apologetic.

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.06),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Text('🌱', style: TextStyle(fontSize: 32)),
          ),
          const SizedBox(height: 18),
          Text(
            'Not enough order history yet',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Planting suggestions need at least a couple of weeks of order '
            'activity to spot a trend. Check back once more orders come in.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppTheme.textMid,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared bits ──────────────────────────────────────────────────────────────

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

// Relative "x min ago" formatting for the header/footer timestamps.
String _relative(DateTime t) {
  final diff = DateTime.now().difference(t);
  if (diff.inSeconds < 45) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return DateFormat('dd MMM, hh:mm a').format(t);
}