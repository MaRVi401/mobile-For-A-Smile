import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../network/api_client.dart';
import '../constants/api_endpoints.dart';
import 'login_screen.dart';
import 'widgets/campaign_card.dart'; // Impor CampaignCard yang sudah dibuat sebelumnya

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  List<dynamic> _campaigns = [];

  @override
  void initState() {
    super.initState();
    _fetchCampaigns(); // Panggil fungsi load data ketika halaman dibuka
  }

  // Fungsi untuk mengambil list data campaign dari backend
  void _fetchCampaigns() async {
    try {
      // Hit endpoint list campaigns (sesuaikan endpoint-nya di ApiEndpoints jika ada path tersendical)
      final response = await _apiClient.dio.get('/campaigns');

      if (response.statusCode == 200) {
        setState(() {
          // Menyesuaikan dengan struktur payload response backend Anda.
          // Jika list data dibungkus objek lain (misal response.data['data']), sesuaikan kodenya.
          _campaigns = response.data is List
              ? response.data
              : (response.data['data'] ?? []);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print("Error fetching campaigns: $e");
    }
  }

  void _logout(BuildContext context) async {
    final storage = const FlutterSecureStorage();

    try {
      await _apiClient.dio.post(ApiEndpoints.logout);
    } catch (e) {
      // Jika error backend tetap lanjut hapus lokal demi UX
    }

    await storage.delete(key: 'access_token');

    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard For A Smile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      // Integrasikan pengecekan state Loading & List Data Campaign di sini
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _campaigns.isEmpty
          ? const Center(
              child: Text(
                'Belum ada program campaign donasi saat ini.',
                style: TextStyle(fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _campaigns.length,
              itemBuilder: (context, index) {
                final campaign = _campaigns[index];
                // Masukkan komponen CampaignCard dan oper data JSON item per index
                return CampaignCard(campaign: campaign);
              },
            ),
    );
  }
}
