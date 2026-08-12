import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../utils/invoice_helper.dart';

class PaymentWebViewScreen extends StatefulWidget {
  final String url;
  // Tambahkan data transaksi opsional agar invoice lengkap
  final Map<String, dynamic>? transactionData;

  const PaymentWebViewScreen({
    super.key,
    required this.url,
    this.transactionData,
  });

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasTriggeredSuccess = false; // Mencegah dialog muncul berulang kali

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });

            // Deteksi otomatis jika transaksi selesai
            if ((url.contains('status_code=200') || url.contains('finish')) &&
                !_hasTriggeredSuccess) {
              _hasTriggeredSuccess = true;

              // Ambil order_id dari parameter URL jika tidak ada di transactionData
              final Uri uri = Uri.parse(url);
              final String? orderIdParam = uri.queryParameters['order_id'];

              final Map<String, dynamic> data =
                  widget.transactionData ??
                  {
                    'order_id': orderIdParam ?? 'FAS-000',
                    'amount': 0,
                    'campaign_title': 'Donasi Kebaikan',
                    'is_anonymous': false,
                    'notes': '',
                    'donor_name': 'Donatur',
                  };

              _showSuccessDialog(context, data);
            }
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint("WebView Error: ${error.description}");
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  void _showSuccessDialog(
    BuildContext context,
    Map<String, dynamic> transactionData,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Column(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 60),
            SizedBox(height: 10),
            Text(
              'Pembayaran Berhasil!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'Terima kasih atas bantuan dan donasi Anda.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsOverflowDirection: VerticalDirection.up,
        actions: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 45),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.download),
            label: const Text('Simpan Invoice (PDF)'),
            onPressed: () {
              // Perbaikan: Panggil savePdfDirectlyToStorage
              InvoiceHelper.savePdfDirectlyToStorage(
                context,
                orderId: transactionData['order_id'] ?? 'FAS-000',
                amount: transactionData['amount'] ?? 0,
                campaignTitle:
                    transactionData['campaign_title'] ?? 'Donasi Kebaikan',
                isAnonymous: transactionData['is_anonymous'] ?? false,
                notes: transactionData['notes'],
                donorName: transactionData['donor_name'],
              );
            },
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Tutup dialog
              Navigator.popUntil(
                context,
                (route) => route.isFirst,
              ); // Kembali ke Beranda
            },
            child: const Text(
              'Kembali ke Beranda',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _showCancelDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 8),
            Text(
              'Batalkan Transaksi?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: const Text(
          'Apakah anda yakin akan membatalkan transaksi ini? Jika keluar, proses pembayaran saat ini tidak akan tersimpan.',
          style: TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Lanjutkan Bayar',
              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade50,
              foregroundColor: Colors.red,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Ya, Batalkan',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _showCancelDialog(context);
        if (shouldPop && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Pembayaran Midtrans',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          elevation: 2,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final shouldPop = await _showCancelDialog(context);
              if (shouldPop && context.mounted) {
                Navigator.pop(context);
              }
            },
          ),
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(color: Colors.blue),
              ),
          ],
        ),
      ),
    );
  }
}
