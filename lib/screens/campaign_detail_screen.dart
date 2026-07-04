import 'package:flutter/material.dart';
import '../network/api_client.dart';

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

  // Fungsi aksi tombol donasi (Store/Checkout ke Midtrans)
  void _openDonationDialog() {
    final TextEditingController amountController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Masukkan Nominal Donasi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                prefixText: 'Rp ',
                border: OutlineInputBorder(),
                hintText: 'Minimal 10.000',
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _processDonation(amountController.text);
                },
                child: const Text('Lanjutkan Pembayaran'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _processDonation(String amountStr) async {
    int? amount = int.tryParse(amountStr);
    if (amount == null || amount < 10000) {
      if (!mounted) return; // Guard check
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

      // Validasi penanganan BuildContext melintasi celah async gap
      if (!mounted) return;

      if (response.statusCode == 201 && response.data['success'] == true) {
        String redirectUrl = response.data['redirect_url'];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Token Transaksi Berhasil Dibuat. Buka link: $redirectUrl',
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error processing donation: $e");
      if (!mounted) return; // Validasi celah async gap pada block catch
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal membuat transaksi donasi')),
      );
    }
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

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(title: Text(campaign['title'] ?? 'Detail Campaign')),
        body: Column(
          children: [
            // Gambar Utama Campaign
            campaign['image_url'] != null
                ? Image.network(
                    campaign['image_url'],
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit
                        .cover, // FIX: Menggunakan BoxFit.cover, bukan 'Cover'
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 200,
                      color: Colors.grey.shade200,
                      child: const Icon(
                        Icons.broken_image,
                        size: 50,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : Container(
                    height: 200,
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.image, size: 50),
                  ),

            // TabBar untuk memisah konten
            const TabBar(
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.blue,
              tabs: [
                Tab(text: 'Deskripsi'),
                Tab(text: 'Program Kerja'),
                Tab(text: 'Laporan Dana'),
              ],
            ),

            // TabBarView Konten Utama
            Expanded(
              child: TabBarView(
                children: [
                  // Tab 1: Deskripsi & Cerita
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          campaign['title'] ?? '',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Target Penggalangan: Rp ${campaign['target_amount']}',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Divider(height: 24),
                        Text(
                          campaign['description'] ??
                              'Tidak ada deskripsi cerita.',
                          style: const TextStyle(fontSize: 15, height: 1.5),
                        ),
                      ],
                    ),
                  ),

                  // Tab 2: List Program Kerja
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
                              margin: const EdgeInsets.only(
                                bottom: 12.0,
                              ), // FIX: Menggunakan EdgeInsets.only
                              child: ListTile(
                                leading: prog['image_url'] != null
                                    ? Image.network(
                                        prog['image_url'],
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                      )
                                    : const Icon(Icons.assignment),
                                title: Text(
                                  prog['program_name'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(prog['description'] ?? ''),
                              ),
                            );
                          },
                        ),

                  // Tab 3: Transparansi Laporan Dana & Penyaluran
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
                        const SizedBox(height: 8),
                        _buildReportRow(
                          'Total Terkumpul',
                          'Rp ${report['total_collected']}',
                          Colors.green,
                        ),
                        _buildReportRow(
                          'Total Disalurkan',
                          'Rp ${report['total_distributed']}',
                          Colors.orange,
                        ),
                        _buildReportRow(
                          'Sisa Saldo Kas',
                          'Rp ${report['remaining_balance']}',
                          Colors.blue,
                        ),
                        const Divider(height: 32),
                        const Text(
                          'Riwayat Penyaluran Donasi',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
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
                                    color: Colors.grey.shade50,
                                    margin: const EdgeInsets.only(
                                      bottom: 8.0,
                                    ), // FIX: Menggunakan EdgeInsets.only
                                    child: ListTile(
                                      title: Text(
                                        'Disalurkan: Rp ${dist['amount_distributed']}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange,
                                        ),
                                      ),
                                      subtitle: Text(
                                        'Penerima: ${dist['beneficiary_name']}\nCatatan: ${dist['notes']}',
                                      ),
                                      trailing: Text(
                                        dist['date'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 12,
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
          padding: const EdgeInsets.all(12.0),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
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

  Widget _buildReportRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
