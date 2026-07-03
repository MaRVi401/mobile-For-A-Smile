import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../constants/api_endpoints.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final Dio _dio = Dio();

  void _register() async {
    try {
      Response response = await _dio.post(
        ApiEndpoints.register,
        data: {
          'name': _nameController.text,
          'email': _emailController.text,
          'password': _passwordController.text,
          'password_confirmation': _confirmPasswordController.text,
        },
        options: Options(headers: {'Accept': 'application/json'}),
      );

      if (response.statusCode == 210 || response.data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registrasi Berhasil! Silakan Login.')),
        );
        Navigator.pop(context);
      }
    } on DioException catch (e) {
      String errMsg = 'Registrasi gagal';

      if (e.response != null && e.response!.data != null) {
        var data = e.response!.data;

        // Jika Laravel mengirimkan objek map 'errors'
        if (data['errors'] != null) {
          Map<String, dynamic> errors = data['errors'];

          // Ambil pesan error pertama yang ditemukan dari field mana saja yang gagal
          // Contoh: Jika email duplikat, akan mengambil "Email sudah terdaftar."
          var firstKey = errors.keys.first;
          errMsg = errors[firstKey][0];
        } else {
          errMsg = data['message'] ?? 'Registrasi gagal';
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
      appBar: AppBar(title: const Text('Daftar Akun Donasi')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nama Lengkap'),
              ),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Konfirmasi Password',
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _register,
                child: const Text('Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
