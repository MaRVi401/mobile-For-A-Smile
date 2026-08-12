import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'formatter.dart';

class InvoiceHelper {
  /// Fungsi 1: Membuka Sistem UI Print / Save PDF bawaan HP
  static Future<void> showAndDownloadPdf({
    required String orderId,
    required num amount,
    required String campaignTitle,
    required bool isAnonymous,
    required String? notes,
    required String? donorName,
  }) async {
    final pdf = await _generatePdfDocument(
      orderId: orderId,
      amount: amount,
      campaignTitle: campaignTitle,
      isAnonymous: isAnonymous,
      notes: notes,
      donorName: donorName,
    );

    // Membuka UI Cetak / Opsi Simpan sebagai PDF
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Invoice-$orderId.pdf',
    );
  }

  /// Fungsi 2: Langsung menyimpan file PDF ke folder lokal perangkat
  static Future<void> savePdfDirectlyToStorage(
    BuildContext context, {
    required String orderId,
    required num amount,
    required String campaignTitle,
    required bool isAnonymous,
    required String? notes,
    required String? donorName,
  }) async {
    try {
      final pdf = await _generatePdfDocument(
        orderId: orderId,
        amount: amount,
        campaignTitle: campaignTitle,
        isAnonymous: isAnonymous,
        notes: notes,
        donorName: donorName,
      );

      final bytes = await pdf.save();
      Directory? directory;

      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory != null) {
        final filePath = '${directory.path}/Invoice-$orderId.pdf';
        final file = File(filePath);
        await file.writeAsBytes(bytes);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Invoice berhasil disimpan di: ${file.path}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error saving PDF: $e");
      // Fallback jika direktori publik gagal diakses: gunakan share sheet
      final pdf = await _generatePdfDocument(
        orderId: orderId,
        amount: amount,
        campaignTitle: campaignTitle,
        isAnonymous: isAnonymous,
        notes: notes,
        donorName: donorName,
      );
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'Invoice-$orderId.pdf',
      );
    }
  }

  /// Helper Internal untuk membuat struktur dokumen PDF
  static Future<pw.Document> _generatePdfDocument({
    required String orderId,
    required num amount,
    required String campaignTitle,
    required bool isAnonymous,
    required String? notes,
    required String? donorName,
  }) async {
    final pdf = pw.Document();
    final nameToDisplay = isAnonymous
        ? 'Hamba Allah'
        : (donorName ?? 'Donatur');
    final formattedAmount = CurrencyFormatter.toRupiah(amount);
    final nowFormatted = DateTime.now().toString().substring(0, 16);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'BUKTI DONASI',
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'For A Smile Foundation',
                        style: const pw.TextStyle(
                          fontSize: 14,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Divider(),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),

                // Rincian Transaksi
                _buildPdfRow('No. Transaksi (Order ID)', orderId),
                _buildPdfRow('Waktu Transaksi', '$nowFormatted WIB'),
                _buildPdfRow('Nama Donatur', nameToDisplay),
                _buildPdfRow('Kampanye', campaignTitle),
                _buildPdfRow(
                  'Pesan / Doa',
                  (notes != null && notes.isNotEmpty) ? notes : '-',
                ),
                _buildPdfRow('Status Pembayaran', 'BERHASIL / SETTLEMENT'),

                pw.SizedBox(height: 20),
                pw.Divider(),

                // Total Donasi
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Total Donasi',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      formattedAmount,
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.red700,
                      ),
                    ),
                  ],
                ),
                pw.Divider(),
                pw.Spacer(),

                // Footer
                pw.Center(
                  child: pw.Text(
                    'Terima kasih atas kepedulian dan kebaikan Anda.',
                    style: const pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.grey600,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf;
  }

  static pw.Widget _buildPdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(color: PdfColors.grey700)),
          pw.Expanded(
            child: pw.Text(
              value,
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  /// Helper internal untuk parse angka aman dari String/num
  static num _safeParse(dynamic value) {
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '0') ?? 0;
  }

  /// Cetak Seluruh Ringkasan Riwayat Transaksi Donasi ke Storage
  /// Cetak Seluruh Ringkasan Riwayat Transaksi Donasi ke Storage
  static Future<void> saveHistoryPdfToStorage(
    BuildContext context, {
    required List<dynamic> transactions,
    required String userName,
  }) async {
    try {
      final pdf = pw.Document();
      final nowFormatted = DateTime.now().toString().substring(0, 16);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (pw.Context context) {
            return [
              // Header
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'LAPORAN RIWAYAT DONASI',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'For A Smile Foundation',
                      style: const pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Divider(),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),

              // Info Donatur
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Nama: $userName',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    'Dicetak: $nowFormatted WIB',
                    style: const pw.TextStyle(
                      color: PdfColors.grey700,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 14),

              // Tabel Riwayat Transaksi
              pw.TableHelper.fromTextArray(
                headers: [
                  'Order ID',
                  'Tanggal',
                  'Kampanye',
                  'Status',
                  'Nominal',
                ],
                data: transactions.map((item) {
                  final num amount = _safeParse(item['amount']);

                  // Perbaikan: Evaluasi string tanggal secara aman
                  final String createdStr =
                      item['created_at']?.toString() ?? '';
                  final String rawDate = createdStr.length >= 10
                      ? createdStr.substring(0, 10)
                      : '-';

                  final String title =
                      item['campaign']?['title'] ?? 'Donasi Umum';
                  final String status = (item['status'] ?? 'pending')
                      .toString()
                      .toUpperCase();

                  return [
                    item['order_id'] ?? '-',
                    rawDate,
                    title.length > 25 ? '${title.substring(0, 22)}...' : title,
                    status,
                    CurrencyFormatter.toRupiah(amount),
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.amber800,
                ),
                rowDecoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                  ),
                ),
                cellAlignment: pw.Alignment.centerLeft,
                cellAlignments: {4: pw.Alignment.centerRight},
              ),
            ];
          },
        ),
      );

      final bytes = await pdf.save();
      Directory? directory;

      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory != null) {
        final filePath =
            '${directory.path}/Riwayat-Donasi-${DateTime.now().millisecondsSinceEpoch}.pdf';
        final file = File(filePath);
        await file.writeAsBytes(bytes);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Laporan Riwayat berhasil disimpan di: ${file.path}',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error saving History PDF: $e");
    }
  }
}
