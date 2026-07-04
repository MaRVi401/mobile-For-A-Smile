import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../network/api_client.dart';
import '../constants/api_endpoints.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _logout(BuildContext context) async {
    final ApiClient apiClient = ApiClient();
    final storage = const FlutterSecureStorage();

    try {
      await apiClient.dio.post(ApiEndpoints.logout);
    } catch (e) {
      // Abaikan error backend demi kelancaran UX lokal
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_pin, size: 80, color: Colors.blue),
            const SizedBox(height: 10),
            const Text(
              'Halaman Edit Profile',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade50,
              ),
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text(
                'Keluar Akun',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () => _logout(context),
            ),
          ],
        ),
      ),
    );
  }
}
