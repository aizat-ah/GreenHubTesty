import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/invoice_model.dart';
import '../models/order_model.dart';
import '../models/user_models.dart';

/// Renders an [InvoiceModel] + its [OrderModel] into a PDF and hands it to
/// the OS share/save sheet via `printing`. Mirrors the visual style of
/// report_pdf_service.dart (Sales Report) so both PDFs feel consistent.
class InvoicePdfService {
  static final _dateFmt = DateFormat('d MMM yyyy');
  static final _timestampFmt = DateFormat('d MMM yyyy, HH:mm');
  static const _brandGreen = PdfColor.fromInt(0xFF2D6A4F);

  Future<void> shareInvoice({
    required InvoiceModel invoice,
    required OrderModel order,
    required UserModel supplier,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(invoice),
        build: (context) => [
          pw.SizedBox(height: 16),
          _buildPartiesRow(supplier, order),
          pw.SizedBox(height: 24),
          _buildSectionTitle('Order Items'),
          pw.SizedBox(height: 8),
          _buildItemsTable(order),
          pw.SizedBox(height: 16),
          _buildTotalRow(invoice),
          if (invoice.note.isNotEmpty) ...[
            pw.SizedBox(height: 24),
            _buildSectionTitle('Note'),
            pw.SizedBox(height: 8),
            pw.Text(invoice.note, style: const pw.TextStyle(fontSize: 11)),
          ],
          pw.SizedBox(height: 24),
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 8),
          pw.Text(
            'Order #${order.id.substring(0, 8).toUpperCase()}  •  Status: ${order.status.label}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'invoice_${invoice.id.substring(0, 8)}.pdf',
    );
  }

  pw.Widget _buildHeader(InvoiceModel invoice) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'GreenHub Invoice',
          style: pw.TextStyle(
            fontSize: 22,
            fontWeight: pw.FontWeight.bold,
            color: _brandGreen,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Invoice ID: ${invoice.id}',
          style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
        ),
        pw.Text(
          'Date Issued: ${_dateFmt.format(invoice.dateIssued)}',
          style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
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

  pw.Widget _buildPartiesRow(UserModel supplier, OrderModel order) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(child: _buildPartyCard('Supplier', [
          supplier.name,
          supplier.email,
          supplier.phone,
        ])),
        pw.SizedBox(width: 12),
        pw.Expanded(child: _buildPartyCard('Delivery Contact', [
          order.customerName,
          order.customerPhone,
        ])),
      ],
    );
  }

  pw.Widget _buildPartyCard(String label, List<String> lines) {
    return pw.Container(
      width: double.infinity,
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
          for (final line in lines.where((l) => l.isNotEmpty))
            pw.Text(line, style: const pw.TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  pw.Widget _buildItemsTable(OrderModel order) {
    return pw.TableHelper.fromTextArray(
      headers: ['Product', 'Qty', 'Unit Price', 'Line Total'],
      data: order.items
          .map((item) => [
                '${item.productName} (${item.unit})',
                '${item.quantity}',
                'RM ${item.price.toStringAsFixed(2)}',
                'RM ${item.subtotal.toStringAsFixed(2)}',
              ])
          .toList(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
      headerDecoration: const pw.BoxDecoration(color: _brandGreen),
      cellStyle: const pw.TextStyle(fontSize: 10),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.center,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerRight,
      },
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    );
  }

  pw.Widget _buildTotalRow(InvoiceModel invoice) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey100,
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Text(
          'Total Amount: RM ${invoice.totalAmount.toStringAsFixed(2)}',
          style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: _brandGreen),
        ),
      ),
    );
  }
}
