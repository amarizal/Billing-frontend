import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:csv/csv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class ExportService {
  static final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  static Future<void> exportToExcel(Map<String, dynamic> reportData, String title, String filename, {bool isDaily = true}) async {
    final List<List<dynamic>> rows = [];
    final summary = reportData['summary'] ?? {};
    final receipts = reportData['receipts'] as List<dynamic>? ?? [];

    double totalCash = 0;
    double totalQris = 0;
    
    // Header
    rows.add([title.toUpperCase()]);
    rows.add(['Diekspor pada: ${DateFormat('dd MMM yyyy HH:mm').format(DateTime.now())}']);
    rows.add([]);
    rows.add(['RINCIAN TRANSAKSI']);

    // Rincian Transaksi
    if (isDaily) {
      rows.add(['Waktu', 'No. Struk', 'Operator', 'Jenis', 'Metode', 'Total (Rp)']);
    } else {
      rows.add(['Tanggal', 'Waktu', 'No. Struk', 'Operator', 'Jenis', 'Metode', 'Total (Rp)']);
    }

    for (var r in receipts) {
      final createdAt = DateTime.parse(r['createdAt'] as String).toLocal();
      final billingAmt = (r['billingAmount'] as num?)?.toDouble() ?? 0;
      final posAmt = (r['posAmount'] as num?)?.toDouble() ?? 0;
      final totalAmt = (r['totalAmount'] as num?)?.toDouble() ?? 0;
      final paymentMethod = (r['paymentMethod'] as String? ?? 'cash').toLowerCase();
      final receiptNumber = r['receiptNumber'] ?? '-';
      final kasirName = r['kasir']?['name'] ?? '-';

      if (paymentMethod == 'cash') totalCash += totalAmt;
      else if (paymentMethod == 'qris') totalQris += totalAmt;

      String jenis = '';
      if (billingAmt > 0 && posAmt > 0) jenis = 'Billing & POS';
      else if (billingAmt > 0) jenis = 'Billing';
      else if (posAmt > 0) jenis = 'POS';
      else jenis = 'Lainnya';

      if (isDaily) {
        rows.add([
          DateFormat('HH:mm').format(createdAt),
          receiptNumber,
          kasirName,
          jenis,
          paymentMethod.toUpperCase(),
          totalAmt
        ]);
      } else {
        rows.add([
          DateFormat('dd/MM/yyyy').format(createdAt),
          DateFormat('HH:mm').format(createdAt),
          receiptNumber,
          kasirName,
          jenis,
          paymentMethod.toUpperCase(),
          totalAmt
        ]);
      }
    }
    
    rows.add([]);
    rows.add([]);

    // Tabel Ringkasan
    rows.add(['RINGKASAN PENDAPATAN']);
    rows.add(['Kategori', 'Nilai']);
    rows.add(['Total Pendapatan', summary['totalAmount'] ?? 0]);
    rows.add(['Total Cash', totalCash]);
    rows.add(['Total QRIS', totalQris]);
    rows.add(['Pendapatan Billing', summary['totalBilling'] ?? 0]);
    rows.add(['Pendapatan POS', summary['totalPos'] ?? 0]);
    rows.add(['Sesi / Struk Tercetak', summary['totalTransactions'] ?? 0]);

    // Convert to CSV
    String csv = const ListToCsvConverter().convert(rows);
    final bytes = Uint8List.fromList(csv.codeUnits);

    await _shareBytes(bytes, '$filename.csv', 'text/csv');
  }

  static Future<void> exportToPdf(Map<String, dynamic> reportData, String title, String filename, {bool isDaily = true}) async {
    final pdf = pw.Document();

    final summary = reportData['summary'] ?? {};
    final receipts = reportData['receipts'] as List<dynamic>? ?? [];

    double totalCash = 0;
    double totalQris = 0;

    final headers = isDaily 
        ? ['Waktu', 'No. Struk', 'Operator', 'Jenis', 'Metode', 'Total']
        : ['Tanggal', 'Waktu', 'No. Struk', 'Operator', 'Jenis', 'Metode', 'Total'];

    final List<List<dynamic>> tableData = [];
    for (var r in receipts) {
      final createdAt = DateTime.parse(r['createdAt'] as String).toLocal();
      final billingAmt = (r['billingAmount'] as num?)?.toDouble() ?? 0;
      final posAmt = (r['posAmount'] as num?)?.toDouble() ?? 0;
      final totalAmt = (r['totalAmount'] as num?)?.toDouble() ?? 0;
      final paymentMethod = (r['paymentMethod'] as String? ?? 'cash').toLowerCase();
      final receiptNumber = r['receiptNumber'] ?? '-';
      final kasirName = r['kasir']?['name'] ?? '-';

      if (paymentMethod == 'cash') totalCash += totalAmt;
      else if (paymentMethod == 'qris') totalQris += totalAmt;

      String jenis = '';
      if (billingAmt > 0 && posAmt > 0) jenis = 'Billing & POS';
      else if (billingAmt > 0) jenis = 'Billing';
      else if (posAmt > 0) jenis = 'POS';
      else jenis = 'Lainnya';

      if (isDaily) {
        tableData.add([
          DateFormat('HH:mm').format(createdAt),
          receiptNumber,
          kasirName,
          jenis,
          paymentMethod.toUpperCase(),
          _currency.format(totalAmt)
        ]);
      } else {
        tableData.add([
          DateFormat('dd/MM/yyyy').format(createdAt),
          DateFormat('HH:mm').format(createdAt),
          receiptNumber,
          kasirName,
          jenis,
          paymentMethod.toUpperCase(),
          _currency.format(totalAmt)
        ]);
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Text(title, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.Text('Diekspor pada: ${DateFormat('dd MMM yyyy HH:mm').format(DateTime.now())}'),
            pw.SizedBox(height: 24),
            
            // Transaction Table
            if (tableData.isNotEmpty)
              pw.Table.fromTextArray(
                headers: headers,
                data: tableData,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
                cellHeight: 25,
                cellStyle: const pw.TextStyle(fontSize: 9),
                cellAlignments: isDaily 
                    ? { 0: pw.Alignment.centerLeft, 1: pw.Alignment.centerLeft, 2: pw.Alignment.centerLeft, 3: pw.Alignment.centerLeft, 4: pw.Alignment.centerLeft, 5: pw.Alignment.centerRight }
                    : { 0: pw.Alignment.centerLeft, 1: pw.Alignment.centerLeft, 2: pw.Alignment.centerLeft, 3: pw.Alignment.centerLeft, 4: pw.Alignment.centerLeft, 5: pw.Alignment.centerLeft, 6: pw.Alignment.centerRight },
              )
            else
              pw.Text('Tidak ada transaksi.', style: const pw.TextStyle(color: PdfColors.grey)),
            
            pw.SizedBox(height: 32),
            
            // Summary Table
            pw.Container(
              alignment: pw.Alignment.centerRight,
              child: pw.Container(
                width: 250,
                child: pw.Table.fromTextArray(
                  headers: ['Ringkasan Pendapatan', 'Nilai'],
                  data: [
                    ['Total Keseluruhan', _currency.format(summary['totalAmount'] ?? 0)],
                    ['Total CASH', _currency.format(totalCash)],
                    ['Total QRIS', _currency.format(totalQris)],
                    ['Pendapatan Billing', _currency.format(summary['totalBilling'] ?? 0)],
                    ['Pendapatan POS', _currency.format(summary['totalPos'] ?? 0)],
                    ['Sesi / Struk Tercetak', '${summary['totalTransactions'] ?? 0}'],
                  ],
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
                  cellHeight: 25,
                  cellStyle: const pw.TextStyle(fontSize: 10),
                  cellAlignments: {
                    0: pw.Alignment.centerLeft,
                    1: pw.Alignment.centerRight,
                  },
                ),
              ),
            ),
          ];
        },
      ),
    );

    final bytes = await pdf.save();
    
    if (kIsWeb) {
      await Printing.sharePdf(bytes: bytes, filename: '$filename.pdf');
    } else {
      await _shareBytes(bytes, '$filename.pdf', 'application/pdf');
    }
  }

  static Future<void> _shareBytes(Uint8List bytes, String filename, String mimeType) async {
    if (kIsWeb) {
      // share_plus supports downloading files on web
      await Share.shareXFiles(
        [XFile.fromData(bytes, name: filename, mimeType: mimeType)],
        text: 'Laporan Billing PS',
      );
    } else {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], text: 'Laporan Billing PS');
    }
  }
}
