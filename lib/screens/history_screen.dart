import 'package:flutter/material.dart';
import '../network/api_client.dart';
import '../utils/formatter.dart';
import 'package:intl/intl.dart'; // Bawaan pubspec.yaml Anda untuk memformat tanggal

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  List<dynamic> _transactionHistory = [];

  @override
  void initState() {
    super.initState();
    _fetchTransactionHistory();
  }

  // Mengambil data riwayat dari endpoint GET /donations/history sesuai routes/api.php
  Future<void> _fetchTransactionHistory() async {
    try {
      setState(() => _isLoading = true);

      final response = await _apiClient.dio.get('/donations/history');

      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          _transactionHistory = response.data['data'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Error fetching transaction history: $e");
    }
  }

  // Helper untuk parsing angka/string nominal secara aman ke bentuk num
  num _safeParse(dynamic value) {
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '0') ?? 0;
  }

  // Helper memformat string tanggal ISO dari Laravel (created_at) menjadi format Indonesia
  String _formatLaravelDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return '-';
    try {
      DateTime dateTime = DateTime.parse(rawDate).toLocal();
      return DateFormat('dd MMM yyyy, HH:mm').format(dateTime);
    } catch (e) {
      return rawDate;
    }
  }

  // Helper pemetaan warna status sesuai dengan Midtrans Notification
  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'settlement':
      case 'success':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'capture':
        return Colors.blue;
      case 'deny':
      case 'failure':
      case 'expire':
      case 'cancel':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Helper untuk mempermudah pembacaan status di sisi pengguna mobile
  String _getStatusText(String? status) {
    switch (status?.toLowerCase()) {
      case 'settlement':
      case 'success':
        return 'BERHASIL';
      case 'pending':
        return 'MENUNGGU';
      case 'expire':
        return 'KADALUWARSA';
      case 'cancel':
        return 'BATAL';
      default:
        return status?.toUpperCase() ?? 'PENDING';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Karena AppBar dihapus, SafeArea digunakan agar konten tidak terpotong status bar HP (baterai/jam)
    return SafeArea(
      child: Scaffold(
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.blue))
            : _transactionHistory.isEmpty
            ? RefreshIndicator(
                onRefresh: _fetchTransactionHistory,
                child: ListView(
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                    const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_rounded,
                            size: 72,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Belum ada riwayat transaksi donasi.',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: _fetchTransactionHistory,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 16.0,
                  ),
                  itemCount: _transactionHistory.length,
                  itemBuilder: (context, index) {
                    final item = _transactionHistory[index];

                    final campaignTitle =
                        item['campaign']?['title'] ?? 'Donasi Umum';
                    final orderId = item['order_id'] ?? '-';
                    final status = item['status'] ?? 'pending';
                    final amount = _safeParse(item['amount']);
                    final dateFormatted = _formatLaravelDate(
                      item['created_at'],
                    );

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.volunteer_activism_rounded,
                                    color: Colors.blue,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        campaignTitle,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'ID: $orderId',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 11,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Badge Status Transaksi
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(
                                      status,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    _getStatusText(status),
                                    style: TextStyle(
                                      color: _getStatusColor(status),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 20, thickness: 0.5),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  dateFormatted,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  CurrencyFormatter.toRupiah(amount),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
