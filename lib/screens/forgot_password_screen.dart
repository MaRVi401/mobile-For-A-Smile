import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../constants/api_endpoints.dart';
import 'reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final Dio _dio = Dio();

  void _sendOtp() async {
    try {
      Response response = await _dio.post(
        ApiEndpoints.forgotPassword,
        data: {'email': _emailController.text},
        options: Options(headers: {'Accept': 'application/json'}),
      );

      if (response.data['success'] == true) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response.data['message'])));

        // Pindah ke halaman Reset Password sambil membawa data email
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ResetPasswordScreen(email: _emailController.text),
          ),
        );
      }
    } on DioException catch (e) {
      String errMsg = e.response?.data['message'] ?? 'Gagal mengirim kode';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errMsg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lupa Password')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Masukkan Email Anda',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _sendOtp,
              child: const Text('Kirim Kode OTP'),
            ),
          ],
        ),
      ),
    );
  }
}
