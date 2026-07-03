import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../constants/api_endpoints.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  const ResetPasswordScreen({super.key, required this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final Dio _dio = Dio();

  void _resetPassword() async {
    try {
      Response response = await _dio.post(
        ApiEndpoints.resetPassword,
        data: {
          'email': widget.email,
          'code': int.parse(_codeController.text), // Harus angka sesuai backend
          'password': _passwordController.text,
          'password_confirmation': _confirmPasswordController.text,
        },
        options: Options(headers: {'Accept': 'application/json'}),
      );

      if (response.data['success'] == true) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response.data['message'])));

        // Balikkan user ke halaman Login paling awal
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } on DioException catch (e) {
      String errMsg = e.response?.data['message'] ?? 'Gagal reset password';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errMsg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password Baru')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Text(
                'Kode OTP dikirim ke: ${widget.email}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Masukkan 6 Digit OTP',
                ),
              ),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password Baru'),
              ),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Konfirmasi Password Baru',
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _resetPassword,
                child: const Text('Perbarui Password'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
