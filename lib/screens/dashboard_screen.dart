import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../network/api_client.dart';
import '../constants/api_endpoints.dart';
import 'login_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  void _logout(BuildContext context) async {
    final apiClient = ApiClient();
    final storage = const FlutterSecureStorage();

    try {
      // Hit endpoint logout terproteksi dengan token bawaan ApiClient
      await apiClient.dio.post(ApiEndpoints.logout);
    } catch (e) {
      // Jika error backend (misal token expired), tetap lanjut hapus token lokal demi UX
    }

    // Hapus token di HP
    await storage.delete(key: 'access_token');

    // Tendang user kembali ke Login Screen
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
        title: const Text('Dashboard Donasi Online'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'Selamat Datang di Aplikasi Donasi!',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
