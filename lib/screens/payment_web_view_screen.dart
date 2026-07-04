import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaymentWebViewScreen extends StatefulWidget {
  final String url;
  const PaymentWebViewScreen({super.key, required this.url});

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Inisialisasi WebViewController secara dinamis dengan konfigurasi lengkap
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

            // Deteksi otomatis jika transaksi di Midtrans selesai secara sukses
            if (url.contains('status_code=200') || url.contains('finish')) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Terima kasih! Transaksi selesai.'),
                ),
              );
              Navigator.pop(context);
            }
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint("WebView Error: ${error.description}");
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  // Fungsi untuk menampilkan Dialog Konfirmasi Pembatalan Transaksi
  Future<bool> _showCancelDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // User wajib memilih tombol
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
            onPressed: () => Navigator.pop(context, false), // Tidak jadi keluar
            child: const Text(
              'Lanjutkan Bayar',
              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context, true), // Ya, batalkan dan keluar
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
    // PopScope digunakan untuk mencegat aksi Back (tombol fisik HP maupun gesture swipe)
    return PopScope(
      canPop:
          false, // Mengunci agar tidak langsung keluar sebelum dialog muncul
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // Panggil dialog konfirmasi pembatalan
        final shouldPop = await _showCancelDialog(context);
        if (shouldPop && context.mounted) {
          Navigator.pop(context); // Jika pilih Ya, baru keluar dari WebView
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Pembayaran Midtrans',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          elevation: 2,
          // Custom tombol back di AppBar agar melewati fungsi intercept dialog kita
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
            // Konten browser utama Midtrans Snap
            WebViewWidget(controller: _controller),

            // Indikator loading animasi melingkar yang rapi
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
