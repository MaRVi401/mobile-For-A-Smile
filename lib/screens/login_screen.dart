import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_endpoints.dart';
import 'dashboard_screen.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final Dio _dio = Dio();
  final _storage = const FlutterSecureStorage();

  void _login() async {
    try {
      Response response = await _dio.post(
        ApiEndpoints.login,
        data: {
          'email': _emailController.text,
          'password': _passwordController.text,
        },
        options: Options(headers: {'Accept': 'application/json'}),
      );

      if (response.data['success'] == true) {
        String token = response.data['access_token'];
        await _storage.write(key: 'access_token', value: token);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      }
    } on DioException catch (e) {
      String errMsg = 'Login gagal';

      if (e.response != null && e.response!.data != null) {
        var data = e.response!.data;

        // Menangani error validasi form (Status Code: 422)
        if (data['errors'] != null) {
          Map<String, dynamic> errors = data['errors'];
          var firstKey = errors.keys.first;
          errMsg = errors[firstKey][0];
        } else {
          // Menangani error akun salah (Status Code: 401)
          errMsg = data['message'] ?? 'Login gagal';
        }
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errMsg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login For A Smile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          // Tambahkan ini agar layar bisa di-scroll jika keyboard muncul
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // --- BERIKUT KODE UNTUK MENAMPILKAN LOGO ---
              Image.asset(
                'assets/images/fas-logo.png', // Logo
                height: 120, // Atur tinggi logo dalam pixel
                fit: BoxFit.contain,
              ),

              // -------------------------------------------
              const SizedBox(height: 30), // Jarak antara logo dan input email

              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border:
                      OutlineInputBorder(), // Membuat tampilan input kotak biar rapi
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _login,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(
                    50,
                  ), // Membuat tombol melebar penuh
                ),
                child: const Text('Login'),
              ),

              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RegisterScreen(),
                  ),
                ),
                child: const Text('Belum punya akun? Daftar disini'),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ForgotPasswordScreen(),
                  ),
                ),
                child: const Text('Lupa Password?'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
