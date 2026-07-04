import 'package:flutter/material.dart';
import '../network/api_client.dart';
import '../utils/formatter.dart';

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

  num _safeParse(dynamic value) {
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '0') ?? 0;
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
      appBar: AppBar(
        title: const Text(
          'Laporan Akuntabilitas Dana',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_campaignDetails != null) ...[
              Text(
                _campaignDetails!['title'] ?? '',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Transparansi penggunaan & penyaluran dana donasi secara real-time',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const Divider(height: 28, thickness: 1),
            ],

            const Text(
              'Ringkasan Keuangan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              color: Colors.blue.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  children: [
                    _buildReportRow(
                      'Total Dana Terkumpul',
                      CurrencyFormatter.toRupiah(
                        _safeParse(report['total_collected']),
                      ),
                      Colors.green,
                    ),
                    const SizedBox(height: 12),
                    _buildReportRow(
                      'Total Dana Disalurkan',
                      '- ${CurrencyFormatter.toRupiah(_safeParse(report['total_distributed']))}',
                      Colors.orange.shade800,
                    ),
                    const Divider(
                      height: 24,
                      thickness: 1,
                      color: Colors.blueAccent,
                    ),
                    _buildReportRow(
                      'Sisa Saldo Kas',
                      CurrencyFormatter.toRupiah(
                        _safeParse(report['remaining_balance']),
                      ),
                      Colors.blue.shade800,
                      isBold: true,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            const Text(
              'Riwayat Distribusi & Penyaluran',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            distributions.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 30),
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
                        elevation: 0.5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    CurrencyFormatter.toRupiah(
                                      _safeParse(dist['amount_distributed']),
                                    ),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange.shade800,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      dist['date'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: RichText(
                                  text: TextSpan(
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontSize: 13.5,
                                      height: 1.4,
                                    ),
                                    children: [
                                      const TextSpan(
                                        text: 'Penerima: ',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      TextSpan(
                                        text: '${dist['beneficiary_name']}\n',
                                      ),
                                      const TextSpan(
                                        text: 'Keterangan: ',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      TextSpan(text: '${dist['notes']}'),
                                    ],
                                  ),
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
            color: isBold ? Colors.blue.shade900 : Colors.black87,
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
