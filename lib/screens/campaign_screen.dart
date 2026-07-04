import 'package:flutter/material.dart';
import '../network/api_client.dart';
import 'widgets/campaign_card.dart';
import 'campaign_detail_screen.dart'; // Import halaman detail

class CampaignScreen extends StatefulWidget {
  const CampaignScreen({super.key});

  @override
  State<CampaignScreen> createState() => _CampaignScreenState();
}

class _CampaignScreenState extends State<CampaignScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  List<dynamic> _campaigns = [];

  @override
  void initState() {
    super.initState();
    _fetchCampaigns();
  }

  void _fetchCampaigns() async {
    try {
      final response = await _apiClient.dio.get('/campaigns');
      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          _campaigns = response.data['data'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint("Error fetching campaigns: $e");
    }
  }

  // Fungsi tambahan untuk menangani alur pembersihan cache RAM & hit ulang API
  Future<void> _handleRefresh() async {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    _fetchCampaigns();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: Colors.blue,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _campaigns.isEmpty
            ? Center(
                // FIX PERMANEN: Kata 'const' di depan ListView SEKARANG SUDAH DIHAPUS TOTAL
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 200),
                    Center(
                      child: Text(
                        'Belum ada program campaign donasi saat ini.',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                itemCount: _campaigns.length,
                itemBuilder: (context, index) {
                  final campaign = _campaigns[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              CampaignDetailScreen(campaignId: campaign['id']),
                        ),
                      ).then((_) {
                        _handleRefresh();
                      });
                    },
                    child: CampaignCard(campaign: campaign),
                  );
                },
              ),
      ),
    );
  }
}
