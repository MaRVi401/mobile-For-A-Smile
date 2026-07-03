import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  // Pastikan inisialisasi Flutter selesai sebelum cek storage
  WidgetsFlutterBinding.ensureInitialized();

  const storage = FlutterSecureStorage();
  String? token = await storage.read(key: 'access_token');

  // Jika token sudah ada di HP, langsung masuk Dashboard. Jika tidak, ke Login.
  runApp(
    MyApp(
      initialScreen: token != null
          ? const DashboardScreen()
          : const LoginScreen(),
    ),
  );
}

class MyApp extends StatelessWidget {
  final Widget initialScreen;
  const MyApp({super.key, required this.initialScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Donasi Online',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: initialScreen,
    );
  }
}
