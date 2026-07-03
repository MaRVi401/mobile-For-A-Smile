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
      appBar: AppBar(title: const Text('Login Donasi Online')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _login, child: const Text('Login')),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RegisterScreen()),
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
    );
  }
}
