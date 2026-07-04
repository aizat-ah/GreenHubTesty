import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../models/sales_report_model.dart';
import '../../providers/sales_report_provider.dart';
import '../../services/report_pdf_service.dart';

enum _RangePreset { today, thisWeek, thisMonth, custom }

class SalesReportScreen extends ConsumerStatefulWidget {
  const SalesReportScreen({super.key});

  @override
  ConsumerState<SalesReportScreen> createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends ConsumerState<SalesReportScreen> {
  static final _dateFmt = DateFormat('d MMM yyyy');

  _RangePreset _selectedPreset = _RangePreset.today;
  DateTimeRange? _customRange;
  bool _isExporting = false;

  DateTimeRange _presetRange(_RangePreset preset) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

    switch (preset) {
      case _RangePreset.today:
        return DateTimeRange(start: todayStart, end: todayEnd);
      case _RangePreset.thisWeek:
        final monday = todayStart.subtract(Duration(days: now.weekday - 1));
        return DateTimeRange(start: monday, end: todayEnd);
      case _RangePreset.thisMonth:
        final firstOfMonth = DateTime(now.year, now.month, 1);
        return DateTimeRange(start: firstOfMonth, end: todayEnd);
      case _RangePreset.custom:
        return _customRange ?? DateTimeRange(start: todayStart, end: todayEnd);
    }
  }

  DateTimeRange get _activeRange => _presetRange(_selectedPreset);

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: now,
      initialDateRange: _customRange,
    );
    if (picked == null) return;

    setState(() {
      _customRange = DateTimeRange(
        start: DateTime(picked.start.year, picked.start.month, picked.start.day),
        end: DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59, 999),
      );
      _selectedPreset = _RangePreset.custom;
    });
  }

  void _onGenerate() {
    final range = _activeRange;
    ref.read(salesReportNotifierProvider.notifier).generate(start: range.start, end: range.end);
  }

  Future<void> _exportPdf(SalesReportData data) async {
    setState(() => _isExporting = true);
    try {
      await ReportPdfService().shareSalesReport(data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export PDF: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportState = ref.watch(salesReportNotifierProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Sales Report')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionLabel('Time Range'),
            const SizedBox(height: 12),
            _buildPresetChips(),
            const SizedBox(height: 12),
            Text(
              '${_dateFmt.format(_activeRange.start)} - ${_dateFmt.format(_activeRange.end)}',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.textMid,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: reportState.isLoading ? null : _onGenerate,
              icon: const Icon(Icons.insert_chart_outlined_rounded),
              label: const Text('Generate Report'),
            ),
            const SizedBox(height: 24),
            _buildResults(reportState),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppTheme.textLight,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildPresetChips() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _PresetChip(
          label: 'Today',
          selected: _selectedPreset == _RangePreset.today,
          onTap: () => setState(() => _selectedPreset = _RangePreset.today),
        ),
        _PresetChip(
          label: 'This Week',
          selected: _selectedPreset == _RangePreset.thisWeek,
          onTap: () => setState(() => _selectedPreset = _RangePreset.thisWeek),
        ),
        _PresetChip(
          label: 'This Month',
          selected: _selectedPreset == _RangePreset.thisMonth,
          onTap: () => setState(() => _selectedPreset = _RangePreset.thisMonth),
        ),
        _PresetChip(
          label: 'Custom Range',
          selected: _selectedPreset == _RangePreset.custom,
          icon: Icons.calendar_month_outlined,
          onTap: _pickCustomRange,
        ),
      ],
    );
  }

  Widget _buildResults(AsyncValue<SalesReportData?> reportState) {
    return reportState.when(
      data: (data) {
        if (data == null) {
          return _buildInfoCard(
            icon: Icons.query_stats_rounded,
            message: 'Select a time range and tap Generate Report to view sales data.',
          );
        }
        if (data.isEmpty) {
          return _buildInfoCard(
            icon: Icons.inbox_outlined,
            message: 'No data found for selected criteria.',
          );
        }
        return _buildReport(data);
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => _buildErrorCard(error),
    );
  }

  Widget _buildInfoCard({required IconData icon, required String message}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.cardDecoration,
      child: Column(
        children: [
          Icon(icon, size: 36, color: AppTheme.textLight),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textMid),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(Object error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, size: 36, color: AppTheme.error),
          const SizedBox(height: 12),
          Text(
            'Failed to generate report.\n$error',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textMid),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => ref.read(salesReportNotifierProvider.notifier).retry(),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChart(List<CategorySales> categories) {
    final maxRevenue = categories.fold<double>(
      0,
      (max, c) => c.revenue > max ? c.revenue : max,
    );
    final maxY = maxRevenue <= 0 ? 10.0 : maxRevenue * 1.2;

    return Container(
      width: double.infinity,
      height: 260,
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 8),
      decoration: AppTheme.cardDecoration,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          alignment: BarChartAlignment.spaceAround,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 4,
            getDrawingHorizontalLine: (value) => FlLine(color: AppTheme.divider, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 64,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= categories.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Transform.rotate(
                      angle: -0.6,
                      alignment: Alignment.topRight,
                      child: Text(
                        categories[index].category,
                        style: GoogleFonts.inter(fontSize: 9, color: AppTheme.textMid),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (int i = 0; i < categories.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: categories[i].revenue,
                    color: AppTheme.primary,
                    width: 18,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReport(SalesReportData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Total Revenue',
                value: 'RM ${data.totalRevenue.toStringAsFixed(2)}',
                icon: Icons.attach_money,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Total Orders',
                value: '${data.totalOrders}',
                icon: Icons.shopping_bag,
                color: AppTheme.info,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildSectionLabel('Revenue by Category'),
        const SizedBox(height: 12),
        _buildCategoryChart(data.categoryBreakdown),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: AppTheme.cardDecoration,
          child: Column(
            children: [
              for (int i = 0; i < data.categoryBreakdown.length; i++)
                _CategoryRow(
                  category: data.categoryBreakdown[i],
                  showDivider: i != data.categoryBreakdown.length - 1,
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildSectionLabel('Top 10 Selling Products'),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: AppTheme.cardDecoration,
          child: Column(
            children: [
              for (int i = 0; i < data.topProducts.length; i++)
                _ProductRow(
                  rank: i + 1,
                  product: data.topProducts[i],
                  showDivider: i != data.topProducts.length - 1,
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: _isExporting ? null : () => _exportPdf(data),
          icon: _isExporting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.picture_as_pdf_outlined),
          label: Text(_isExporting ? 'Preparing PDF...' : 'Export as PDF'),
        ),
      ],
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  const _PresetChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppTheme.primary : AppTheme.divider,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: selected ? Colors.white : AppTheme.textMid),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppTheme.textMid,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.textMid,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final CategorySales category;
  final bool showDivider;

  const _CategoryRow({required this.category, required this.showDivider});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  category.category,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppTheme.textDark),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  '${category.orderCount} orders',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMid),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'RM ${category.revenue.toStringAsFixed(2)}',
                  textAlign: TextAlign.right,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppTheme.primary),
                ),
              ),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1, color: AppTheme.divider, indent: 16, endIndent: 16),
      ],
    );
  }
}

class _ProductRow extends StatelessWidget {
  final int rank;
  final ProductSales product;
  final bool showDivider;

  const _ProductRow({required this.rank, required this.product, required this.showDivider});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$rank',
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.accent),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  product.productName,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppTheme.textDark),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${product.quantitySold} sold',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textMid),
              ),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1, color: AppTheme.divider, indent: 16, endIndent: 16),
      ],
    );
  }
}
