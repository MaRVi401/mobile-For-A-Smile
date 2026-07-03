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
  Map<String, dynamic>? _campaignData;

  @override
  void initState() {
    super.initState();
    _loadCampaignDetail();
  }

  void _loadCampaignDetail() async {
    try {
      // Menggunakan instance dio dari ApiClient Anda
      final response = await _apiClient.dio.get(
        '/campaigns/${widget.campaignId}',
      );

      if (response.statusCode == 200) {
        setState(() {
          _campaignData = response.data;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print("Error fetching detail: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final String description =
        _campaignData?['description'] ?? 'Tidak ada rincian deskripsi program.';

    return Scaffold(
      appBar: AppBar(title: const Text("Detail Program")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _campaignData?['title'] ?? 'Judul Program',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Latar Belakang & Rincian Program:",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 15, height: 1.5),
                    textAlign: TextAlign
                        .justify, // Perbaikan: Gunakan TextAlign, bukan TextAlignment
                  ),
                ],
              ),
            ),
    );
  }
}
