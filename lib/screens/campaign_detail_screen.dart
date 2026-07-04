import 'package:flutter/material.dart';
import '../network/api_client.dart';
import '../utils/formatter.dart';
import 'payment_web_view_screen.dart';
import 'package:flutter/services.dart';

class CampaignDetailScreen extends StatefulWidget {
  final int campaignId;
  const CampaignDetailScreen({super.key, required this.campaignId});

  @override
  State<CampaignDetailScreen> createState() => _CampaignDetailScreenState();
}

class _CampaignDetailScreenState extends State<CampaignDetailScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  Map<String, dynamic>? _detailData;

  @override
  void initState() {
    super.initState();
    _fetchCampaignDetail();
  }

  void _fetchCampaignDetail() async {
    try {
      final response = await _apiClient.dio.get(
        '/campaigns/${widget.campaignId}',
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          _detailData = response.data['data'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint("Error fetching campaign details: $e");
    }
  }

  void _openDonationDialog() {
    final TextEditingController amountController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Masukkan Nominal Donasi',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                // Menggunakan Formatter bawaan Flutter untuk membatasi hanya angka
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (value) {
                  if (value.isEmpty) return;

                  // Bersihkan karakter non-angka terlebih dahulu
                  String cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
                  int? parsed = int.tryParse(cleaned);

                  if (parsed != null) {
                    // Menggunakan CurrencyFormatter bawaan utils/formatter.dart kamu
                    // Kita hilangkan simbol "Rp" dan spasi-nya agar hanya menyisakan format titik saja (10.000)
                    String formatted = CurrencyFormatter.toRupiah(
                      parsed,
                    ).replaceAll('Rp', '').replaceAll(' ', '').trim();

                    // Set ulang teks secara real-time tanpa merusak posisi kursor ketikan
                    amountController.value = TextEditingValue(
                      text: formatted,
                      selection: TextSelection.collapsed(
                        offset: formatted.length,
                      ),
                    );
                  }
                },
                decoration: InputDecoration(
                  prefixText: 'Rp ',
                  prefixStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  hintText: '10.000',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Batal',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    onPressed: () {
                      final String rawText = amountController.text;
                      Navigator.pop(context);
                      _processDonation(rawText);
                    },
                    child: const Text(
                      'Lanjutkan',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _processDonation(String amountStr) async {
    // Bersihkan semua karakter titik (.) dari string rupiah sebelum dikirim ke API Laravel
    String cleanedAmount = amountStr.replaceAll('.', '');
    int? amount = int.tryParse(cleanedAmount);

    if (amount == null || amount < 10000) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nominal donasi minimal Rp 10.000')),
      );
      return;
    }

    try {
      final response = await _apiClient.dio.post(
        '/donations',
        data: {'campaign_id': widget.campaignId, 'amount': amount},
      );

      if (!mounted) return;

      if (response.statusCode == 201 && response.data['success'] == true) {
        final String redirectUrl =
            response.data['redirect_url'] ?? response.data['snap_url'] ?? '';

        if (redirectUrl.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentWebViewScreen(url: redirectUrl),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal mendapatkan link pembayaran dari server.'),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error processing donation: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal membuat transaksi donasi')),
      );
    }
  }

  num _safeParse(dynamic value) {
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '0') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_detailData == null) {
      return const Scaffold(
        body: Center(child: Text('Gagal memuat detail data campaign.')),
      );
    }

    final campaign = _detailData!['campaign_details'];
    final report = _detailData!['transparency_report'];
    final List<dynamic> programs = _detailData!['programs'] ?? [];
    final List<dynamic> distributions =
        _detailData!['distribution_history'] ?? [];

    final String? imageUrl = campaign['image_url'];

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            campaign['title'] ?? 'Detail Campaign',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        body: Column(
          children: [
            // Gambar Utama Campaign dengan Fitur Fallback Asset Image
            imageUrl != null && imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Image.asset(
                      'assets/images/fas-logo.png',
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.contain,
                    ),
                  )
                : Image.asset(
                    'assets/images/fas-logo.png',
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.contain,
                  ),

            const TabBar(
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.blue,
              labelStyle: TextStyle(fontWeight: FontWeight.bold),
              tabs: [
                Tab(text: 'Deskripsi'),
                Tab(text: 'Program Kerja'),
                Tab(text: 'Laporan Dana'),
              ],
            ),

            Expanded(
              child: TabBarView(
                children: [
                  // Tab 1: Deskripsi
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          campaign['title'] ?? '',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Target Dana: ${CurrencyFormatter.toRupiah(_safeParse(campaign['target_amount']))}',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const Divider(height: 24),
                        Text(
                          campaign['description'] ??
                              'Tidak ada deskripsi cerita.',
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.6,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Tab 2: Program Kerja
                  programs.isEmpty
                      ? const Center(
                          child: Text('Belum ada sub-program kerja.'),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: programs.length,
                          itemBuilder: (context, index) {
                            final prog = programs[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12.0),
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ListTile(
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child:
                                      prog['image_url'] != null &&
                                          prog['image_url']
                                              .toString()
                                              .isNotEmpty
                                      ? Image.network(
                                          prog['image_url'],
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                        )
                                      : Container(
                                          width: 50,
                                          height: 50,
                                          color: Colors.grey.shade200,
                                          child: const Icon(Icons.assignment),
                                        ),
                                ),
                                title: Text(
                                  prog['program_name'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  prog['description'] ?? '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            );
                          },
                        ),

                  // Tab 3: Transparansi Laporan Dana
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ringkasan Dana',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Card(
                          color: Colors.grey.shade50,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: Column(
                              children: [
                                _buildReportRow(
                                  'Total Terkumpul',
                                  CurrencyFormatter.toRupiah(
                                    _safeParse(report['total_collected']),
                                  ),
                                  Colors.green,
                                ),
                                const SizedBox(height: 8),
                                _buildReportRow(
                                  'Total Disalurkan',
                                  CurrencyFormatter.toRupiah(
                                    _safeParse(report['total_distributed']),
                                  ),
                                  Colors.orange.shade800,
                                ),
                                const Divider(height: 20),
                                _buildReportRow(
                                  'Sisa Saldo Kas',
                                  CurrencyFormatter.toRupiah(
                                    _safeParse(report['remaining_balance']),
                                  ),
                                  Colors.blue,
                                  isBold: true,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Riwayat Penyaluran Donasi',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        distributions.isEmpty
                            ? const Text(
                                'Belum ada riwayat distribusi dana.',
                                style: TextStyle(color: Colors.grey),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: distributions.length,
                                itemBuilder: (context, index) {
                                  final dist = distributions[index];
                                  return Card(
                                    color: Colors.white,
                                    margin: const EdgeInsets.only(bottom: 10.0),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: BorderSide(
                                        color: Colors.grey.shade100,
                                      ),
                                    ),
                                    child: ListTile(
                                      title: Text(
                                        'Disalurkan: ${CurrencyFormatter.toRupiah(_safeParse(dist['amount_distributed']))}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange.shade800,
                                        ),
                                      ),
                                      subtitle: Padding(
                                        padding: const EdgeInsets.only(
                                          top: 4.0,
                                        ),
                                        child: Text(
                                          'Penerima: ${dist['beneficiary_name']}\nCatatan: ${dist['notes']}',
                                          style: const TextStyle(height: 1.3),
                                        ),
                                      ),
                                      trailing: Text(
                                        dist['date'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 1,
            ),
            icon: const Icon(Icons.volunteer_activism),
            label: const Text(
              'Kirim Donasi Sekarang',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            onPressed: _openDonationDialog,
          ),
        ),
      ),
    );
  }

  Widget _buildReportRow(
    String label,
    String value,
    Color color, {
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
