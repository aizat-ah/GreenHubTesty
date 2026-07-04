import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/sales_report_model.dart';

/// Renders a [SalesReportData] into a PDF and hands it to the OS
/// share/save sheet via `printing`.
class ReportPdfService {
  static final _dateFmt = DateFormat('d MMM yyyy');
  static final _timestampFmt = DateFormat('d MMM yyyy, HH:mm');
  static const _brandGreen = PdfColor.fromInt(0xFF2D6A4F);

  Future<void> shareSalesReport(SalesReportData data) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(data),
        build: (context) => [
          pw.SizedBox(height: 16),
          _buildSummaryRow(data),
          pw.SizedBox(height: 24),
          _buildSectionTitle('Revenue by Category'),
          pw.SizedBox(height: 8),
          _buildCategoryChart(data),
          pw.SizedBox(height: 12),
          _buildCategoryTable(data),
          pw.SizedBox(height: 24),
          _buildSectionTitle('Top 10 Selling Products'),
          pw.SizedBox(height: 8),
          _buildTopProductsTable(data),
        ],
      ),
    );

    final rangeLabel = DateFormat('yyyyMMdd').format(data.rangeStart);
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'sales_report_$rangeLabel.pdf',
    );
  }

  pw.Widget _buildHeader(SalesReportData data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'GreenHub Sales Report',
          style: pw.TextStyle(
            fontSize: 22,
            fontWeight: pw.FontWeight.bold,
            color: _brandGreen,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          '${_dateFmt.format(data.rangeStart)} - ${_dateFmt.format(data.rangeEnd)}',
          style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
        ),
        pw.Text(
          'Generated: ${_timestampFmt.format(DateTime.now())}',
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
        ),
        pw.Divider(color: PdfColors.grey300, height: 20),
      ],
    );
  }

  pw.Widget _buildSectionTitle(String title) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        fontSize: 14,
        fontWeight: pw.FontWeight.bold,
        color: _brandGreen,
      ),
    );
  }

  pw.Widget _buildSummaryRow(SalesReportData data) {
    return pw.Row(
      children: [
        pw.Expanded(child: _buildSummaryCard('Total Revenue', 'RM ${data.totalRevenue.toStringAsFixed(2)}')),
        pw.SizedBox(width: 12),
        pw.Expanded(child: _buildSummaryCard('Total Orders', '${data.totalOrders}')),
      ],
    );
  }

  pw.Widget _buildSummaryCard(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
          pw.SizedBox(height: 4),
          pw.Text(value, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  pw.Widget _buildCategoryChart(SalesReportData data) {
    if (data.categoryBreakdown.isEmpty) {
      return pw.SizedBox();
    }

    final maxRevenue = data.categoryBreakdown.fold<double>(
      0,
      (max, c) => c.revenue > max ? c.revenue : max,
    );
    final maxY = maxRevenue <= 0 ? 10.0 : maxRevenue * 1.2;

    return pw.Container(
      height: 220,
      padding: const pw.EdgeInsets.only(top: 8, bottom: 4),
      child: pw.Chart(
        grid: pw.CartesianGrid(
          xAxis: pw.FixedAxis.fromStrings(
            data.categoryBreakdown.map((c) => c.category).toList(),
            textStyle: const pw.TextStyle(fontSize: 7),
            angle: -0.5,
            marginStart: 20,
            marginEnd: 20,
          ),
          yAxis: pw.FixedAxis(
            [0, maxY / 4, maxY / 2, maxY * 3 / 4, maxY],
            format: (v) => v.toStringAsFixed(0),
            textStyle: const pw.TextStyle(fontSize: 7),
            divisions: true,
            divisionsColor: PdfColors.grey300,
          ),
        ),
        datasets: [
          pw.BarDataSet(
            color: _brandGreen,
            width: 14,
            data: [
              for (int i = 0; i < data.categoryBreakdown.length; i++)
                pw.PointChartValue(i.toDouble(), data.categoryBreakdown[i].revenue),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCategoryTable(SalesReportData data) {
    if (data.categoryBreakdown.isEmpty) {
      return pw.Text('No data found for selected criteria.',
          style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600));
    }

    return pw.TableHelper.fromTextArray(
      headers: ['Category', 'Orders', 'Units Sold', 'Revenue'],
      data: data.categoryBreakdown
          .map((c) => [
                c.category,
                '${c.orderCount}',
                '${c.quantitySold}',
                'RM ${c.revenue.toStringAsFixed(2)}',
              ])
          .toList(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
      headerDecoration: const pw.BoxDecoration(color: _brandGreen),
      cellStyle: const pw.TextStyle(fontSize: 10),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.center,
        2: pw.Alignment.center,
        3: pw.Alignment.centerRight,
      },
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    );
  }

  pw.Widget _buildTopProductsTable(SalesReportData data) {
    if (data.topProducts.isEmpty) {
      return pw.Text('No data found for selected criteria.',
          style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600));
    }

    return pw.TableHelper.fromTextArray(
      headers: ['#', 'Product', 'Units Sold'],
      data: data.topProducts
          .asMap()
          .entries
          .map((e) => ['${e.key + 1}', e.value.productName, '${e.value.quantitySold}'])
          .toList(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
      headerDecoration: const pw.BoxDecoration(color: _brandGreen),
      cellStyle: const pw.TextStyle(fontSize: 10),
      cellAlignments: {
        0: pw.Alignment.center,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.center,
      },
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    );
  }
}
