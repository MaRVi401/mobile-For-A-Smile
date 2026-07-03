import 'package:flutter/material.dart';
import '../network/api_client.dart';

class CampaignReportScreen extends StatefulWidget {
  final int campaignId;

  const CampaignReportScreen({super.key, required this.campaignId});

  @override
  State<CampaignReportScreen> createState() => _CampaignReportScreenState(); // Perbaikan: Nama state disamakan
}

class _CampaignReportScreenState extends State<CampaignReportScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  List<dynamic> _reports = [];

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  void _loadReportData() async {
    try {
      // Menggunakan instance dio dari ApiClient Anda
      final response = await _apiClient.dio.get(
        '/campaigns/${widget.campaignId}',
      );

      if (response.statusCode == 200) {
        setState(() {
          _reports = response.data?['reports'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print("Error fetching report: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Laporan Penggunaan Dana")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reports.isEmpty
          ? const Center(child: Text("Belum ada laporan penyaluran dana."))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _reports.length,
              itemBuilder: (context, index) {
                final report = _reports[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const Icon(
                      Icons.assignment_turned_in,
                      color: Colors.green,
                    ), // Perbaikan: Gunakan Colors.green
                    title: Text(report['allocation_name'] ?? 'Penyaluran Dana'),
                    subtitle: Text(report['date'] ?? '-'),
                    trailing: Text(
                      "Rp ${report['amount'] ?? 0}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
