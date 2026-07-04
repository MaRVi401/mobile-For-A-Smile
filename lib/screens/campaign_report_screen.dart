import 'package:flutter/material.dart';
import '../network/api_client.dart';

class CampaignReportScreen extends StatefulWidget {
  final int campaignId;
  const CampaignReportScreen({super.key, required this.campaignId});

  @override
  State<CampaignReportScreen> createState() => _CampaignReportScreenState();
}

class _CampaignReportScreenState extends State<CampaignReportScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  Map<String, dynamic>? _reportData;
  Map<String, dynamic>? _campaignDetails;

  @override
  void initState() {
    super.initState();
    _fetchReportData();
  }

  void _fetchReportData() async {
    try {
      // Mengambil detail campaign berdasarkan ID dari API Laravel
      final response = await _apiClient.dio.get(
        '/campaigns/${widget.campaignId}',
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          _campaignDetails = response.data['data']['campaign_details'];
          _reportData = response.data['data'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint("Error fetching report data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_reportData == null) {
      return const Scaffold(
        body: Center(child: Text('Gagal memuat laporan keuangan.')),
      );
    }

    final report = _reportData!['transparency_report'] ?? {};
    final List<dynamic> distributions =
        _reportData!['distribution_history'] ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Laporan Akuntabilitas Dana')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Singkat nama Campaign
            if (_campaignDetails != null) ...[
              Text(
                _campaignDetails!['title'] ?? '',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Transparansi penggunaan & penyaluran dana donasi',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const Divider(height: 24),
            ],

            // Ringkasan Dana Box Masuk & Keluar
            const Text(
              'Ringkasan Keuangan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              color: Colors.blue.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildReportRow(
                      'Total Dana Terkumpul',
                      'Rp ${report['total_collected']}',
                      Colors.green,
                    ),
                    const SizedBox(height: 10),
                    _buildReportRow(
                      'Total Dana Disalurkan',
                      '- Rp ${report['total_distributed']}',
                      Colors.orange,
                    ),
                    const Divider(height: 20),
                    _buildReportRow(
                      'Sisa Saldo Kas',
                      'Rp ${report['remaining_balance']}',
                      Colors.blue,
                      isBold: true,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Riwayat Penyaluran Dana di Lapangan
            const Text(
              'Riwayat Distribusi & Penyaluran',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            distributions.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        'Belum ada riwayat distribusi dana untuk campaign ini.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: distributions.length,
                    itemBuilder: (context, index) {
                      final dist = distributions[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12.0),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Rp ${dist['amount_distributed']}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(
                                    dist['date'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              RichText(
                                text: TextSpan(
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 14,
                                  ),
                                  children: [
                                    const TextSpan(
                                      text: 'Penerima: ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    TextSpan(
                                      text: '${dist['beneficiary_name']}\n',
                                    ),
                                    const TextSpan(
                                      text: 'Keterangan: ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    TextSpan(text: '${dist['notes']}'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ],
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
