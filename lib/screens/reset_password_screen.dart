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

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[500]),
            prefixIcon: Icon(icon, color: const Color(0xFFF5A623)),
            filled: true,
            fillColor: const Color(0xFFF2F2F2),
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'Reset Password Baru',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3D9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Kode OTP dikirim ke: ${widget.email}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                _buildField(
                  label: 'Kode OTP',
                  controller: _codeController,
                  hint: 'Masukkan 6 digit OTP',
                  icon: Icons.pin_outlined,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 18),
                _buildField(
                  label: 'Password Baru',
                  controller: _passwordController,
                  hint: 'Masukkan password baru',
                  icon: Icons.lock_outline,
                  obscureText: true,
                ),
                const SizedBox(height: 18),
                _buildField(
                  label: 'Konfirmasi Password Baru',
                  controller: _confirmPasswordController,
                  hint: 'Konfirmasi password baru',
                  icon: Icons.lock_outline,
                  obscureText: true,
                ),

                const SizedBox(height: 28),

                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _resetPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF5A623),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Perbarui Password',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
