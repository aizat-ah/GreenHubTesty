import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../models/sales_report_model.dart';
import '../services/sales_report_service.dart';

final salesReportNotifierProvider = StateNotifierProvider.autoDispose<
    SalesReportNotifier, AsyncValue<SalesReportData?>>((ref) {
  return SalesReportNotifier(ref.watch(salesReportServiceProvider));
});

/// Holds the state of a single "Generate Report" action (UC010).
/// `AsyncValue.data(null)` = nothing generated yet.
class SalesReportNotifier extends StateNotifier<AsyncValue<SalesReportData?>> {
  SalesReportNotifier(this._service) : super(const AsyncValue.data(null));

  final SalesReportService _service;

  DateTime? _lastStart;
  DateTime? _lastEnd;

  Future<void> generate({required DateTime start, required DateTime end}) async {
    _lastStart = start;
    _lastEnd = end;
    state = const AsyncValue.loading();
    try {
      final data = await _service.generateReport(start: start, end: end);
      state = AsyncValue.data(data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Retries the last-attempted range, for the exception-flow "Retry" action.
  Future<void> retry() async {
    if (_lastStart == null || _lastEnd == null) return;
    await generate(start: _lastStart!, end: _lastEnd!);
  }

  void reset() {
    _lastStart = null;
    _lastEnd = null;
    state = const AsyncValue.data(null);
  }
}
