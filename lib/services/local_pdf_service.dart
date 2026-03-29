import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/invoice.dart';

final localPdfServiceProvider = Provider<LocalPdfService>((ref) {
  return LocalPdfService();
});

class LocalPdfService {
  Future<String> generatePdf(Invoice invoice) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20 * PdfPageFormat.mm),
        build: (context) => [
          _buildHeader(invoice),
          pw.SizedBox(height: 8),
          _buildDivider(),
          pw.SizedBox(height: 8),
          _buildParties(invoice),
          pw.SizedBox(height: 8),
          _buildItemsTable(invoice),
          pw.SizedBox(height: 8),
          _buildTotals(invoice),
          pw.SizedBox(height: 12),
          if (invoice.bankAccount != null) _buildPaymentDetails(invoice),
          if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            _buildNotes(invoice.notes!),
          ],
        ],
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/invoice_${invoice.id}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }

  // --- 1. HEADER ---
  pw.Widget _buildHeader(Invoice invoice) {
    final refs = <String>[];
    if (invoice.contractReference != null && invoice.contractReference!.isNotEmpty) {
      refs.add('Contract Ref: ${invoice.contractReference}');
    }
    if (invoice.externalReference != null && invoice.externalReference!.isNotEmpty) {
      refs.add('External Ref: ${invoice.externalReference}');
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Invoice #${invoice.invoiceNumber}',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          invoice.dueDate != null && invoice.dueDate!.isNotEmpty
              ? 'Issue Date: ${invoice.issueDate}  |  Due Date: ${invoice.dueDate}'
              : 'Issue Date: ${invoice.issueDate}',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
        ),
        if (refs.isNotEmpty) ...[
          pw.SizedBox(height: 1),
          pw.Text(
            refs.join('  |  '),
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
        ],
      ],
    );
  }

  pw.Widget _buildDivider() {
    return pw.Divider(color: PdfColors.grey300, thickness: 0.3);
  }

  // --- 2 & 3. FROM / BILL TO ---
  pw.Widget _buildParties(Invoice invoice) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: _buildPartyColumn(
            'From:',
            _companyLines(invoice.company),
          ),
        ),
        pw.SizedBox(width: 10),
        pw.Expanded(
          child: _buildPartyColumn(
            'Bill To:',
            _clientLines(invoice.client),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildPartyColumn(String title, List<String> lines) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title,
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 3),
        ...lines.map((line) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 1),
              child: pw.Text(line, style: const pw.TextStyle(fontSize: 9)),
            )),
      ],
    );
  }

  List<String> _companyLines(dynamic company) {
    if (company == null) return ['N/A'];
    final lines = <String>[];
    if (company.name.isNotEmpty) lines.add(company.name);
    if (company.contactPerson.isNotEmpty) lines.add(company.contactPerson);
    if (company.address.isNotEmpty) lines.add(company.address);
    if (company.phone != null && company.phone!.isNotEmpty) {
      lines.add('Phone: ${company.phone}');
    }
    if (company.vatNumber != null && company.vatNumber!.isNotEmpty) {
      lines.add('VAT: ${company.vatNumber}');
    }
    if (company.regNumber != null && company.regNumber!.isNotEmpty) {
      lines.add('Reg No: ${company.regNumber}');
    }
    return lines;
  }

  List<String> _clientLines(dynamic client) {
    if (client == null) return ['N/A'];
    final lines = <String>[];
    if (client.name.isNotEmpty) lines.add(client.name);
    if (client.contactPerson != null && client.contactPerson!.isNotEmpty) {
      lines.add(client.contactPerson!);
    }
    if (client.email != null && client.email!.isNotEmpty) {
      lines.add(client.email!);
    }
    if (client.address.isNotEmpty) lines.add(client.address);
    if (client.vatNumber != null && client.vatNumber!.isNotEmpty) {
      lines.add('VAT: ${client.vatNumber}');
    }
    if (client.regNumber != null && client.regNumber!.isNotEmpty) {
      lines.add('Reg No: ${client.regNumber}');
    }
    return lines;
  }

  // --- 4. LINE ITEMS TABLE ---
  pw.Widget _buildItemsTable(Invoice invoice) {
    final currency = invoice.currency;

    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
      cellStyle: const pw.TextStyle(fontSize: 9),
      headerDecoration:
          const pw.BoxDecoration(color: PdfColors.grey100),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      columnWidths: {
        0: const pw.FlexColumnWidth(4),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1.5),
      },
      headerAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.center,
        2: pw.Alignment.center,
        3: pw.Alignment.centerRight,
      },
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.center,
        2: pw.Alignment.center,
        3: pw.Alignment.centerRight,
      },
      headers: ['Description', 'Qty', 'Unit Price', 'Total'],
      data: invoice.items
          .map((item) => [
                item.description,
                item.quantity,
                _formatAmount(item.unitPrice, currency),
                _formatAmount(item.total, currency),
              ])
          .toList(),
    );
  }

  // --- 5. TOTALS ---
  pw.Widget _buildTotals(Invoice invoice) {
    final currency = invoice.currency;

    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.SizedBox(
        width: 200,
        child: pw.Column(
          children: [
            _totalRow('Subtotal:', _formatAmount(invoice.subtotal, currency)),
            _totalRow(
              'VAT (${invoice.vatRate}%):',
              _formatAmount(invoice.vatAmount, currency),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              child: _totalRow(
                'Total:',
                _formatAmount(invoice.total, currency),
                bold: true,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _totalRow(String label, String value,
      {bool bold = false, double fontSize = 9}) {
    final style = pw.TextStyle(
      fontSize: fontSize,
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
    );
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: style),
          pw.Text(value, style: style),
        ],
      ),
    );
  }

  // --- 6. PAYMENT DETAILS ---
  pw.Widget _buildPaymentDetails(Invoice invoice) {
    final bank = invoice.bankAccount!;
    final pairs = <MapEntry<String, String>>[];

    if (bank.accountHolder.isNotEmpty) {
      pairs.add(MapEntry('Account Holder:', bank.accountHolder));
    }
    pairs.add(MapEntry('Bank:', bank.bankName));
    if (bank.bankAddress.isNotEmpty) {
      pairs.add(MapEntry('Bank Address:', bank.bankAddress));
    }
    pairs.add(MapEntry('IBAN:', bank.iban));
    pairs.add(MapEntry('SWIFT:', bank.swift));

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Payment Details',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        ...pairs.map((p) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 2),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.SizedBox(
                    width: 80,
                    child: pw.Text(p.key,
                        style: pw.TextStyle(
                            fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Expanded(
                    child:
                        pw.Text(p.value, style: const pw.TextStyle(fontSize: 9)),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  // --- 7. NOTES ---
  pw.Widget _buildNotes(String notes) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Notes',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 3),
        pw.Text(notes, style: const pw.TextStyle(fontSize: 9)),
      ],
    );
  }

  String _formatAmount(String amount, String currency) {
    try {
      final value = double.parse(amount);
      return '${value.toStringAsFixed(2)} $currency';
    } catch (_) {
      return '$amount $currency';
    }
  }
}
