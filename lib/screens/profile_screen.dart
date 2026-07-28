import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../network/api_client.dart';
import '../constants/api_endpoints.dart';
import 'login_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:dio/dio.dart' as dio_package;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiClient _apiClient = ApiClient();
  final _storage = const FlutterSecureStorage();

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  // Controller Tambahan untuk Fitur Ganti Password
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmController =
      TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  File? _imageFile;
  String? _avatarUrl;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  // 1. MEMPERBAIKI AUTO-FILL: Mengambil data user yang tersimpan di database
  Future<void> _fetchUserProfile() async {
    try {
      setState(() => _isLoading = true);

      final response = await _apiClient.dio.get('/user');

      if (response.statusCode == 200) {
        final userData = response.data;
        setState(() {
          _nameController.text = userData['name'] ?? '';
          _emailController.text = userData['email'] ?? '';

          // Sinkronisasi field foto profil dari database (bisa bernama 'avatar' atau 'avatar_path')
          final String? dbAvatar =
              userData['avatar_path'] ?? userData['avatar'];
          if (dbAvatar != null && dbAvatar.isNotEmpty) {
            _avatarUrl =
                "${ApiEndpoints.baseUrl.replaceAll('/api', '')}/storage/$dbAvatar";
          } else {
            _avatarUrl = null;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Error fetching profile: $e");
    }
  }

  // 2. Mengambil Gambar Baru dari Galeri/Kamera
  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: Color(0xFFF5A623),
                ),
                title: const Text('Pilih dari Galeri'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? pickedFile = await _picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 80,
                  );
                  if (pickedFile != null) {
                    setState(() {
                      _imageFile = File(pickedFile.path);
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_camera,
                  color: Color(0xFFF5A623),
                ),
                title: const Text('Ambil dari Kamera'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? pickedFile = await _picker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 80,
                  );
                  if (pickedFile != null) {
                    setState(() {
                      _imageFile = File(pickedFile.path);
                    });
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // 3. MENYESUAIKAN API: Mengirim Data Profil & Password Baru ke /user/update
  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _isSaving = true);

      Map<String, dynamic> bodyData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
      };

      // Jika user mengisi field password, ikut kirimkan ke API Laravel Anda
      if (_passwordController.text.isNotEmpty) {
        bodyData['password'] = _passwordController.text;
        bodyData['password_confirmation'] = _passwordConfirmController.text;
      }

      // Jika ada file avatar baru
      if (_imageFile != null) {
        String fileName = _imageFile!.path.split('/').last;
        bodyData['avatar'] = await dio_package.MultipartFile.fromFile(
          _imageFile!.path,
          filename: fileName,
        );
      }

      dio_package.FormData formData = dio_package.FormData.fromMap(bodyData);

      final response = await _apiClient.dio.post(
        '/user/update',
        data: formData,
      );

      if (response.statusCode == 200 || response.data['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profil berhasil diperbarui!'),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Bersihkan field input password setelah sukses ganti password
        _passwordController.clear();
        _passwordConfirmController.clear();

        _fetchUserProfile(); // Reload data terbaru
      }
    } catch (e) {
      debugPrint("Error updating profile: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memperbarui profil')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _logout(BuildContext context) async {
    try {
      await _apiClient.dio.post(ApiEndpoints.logout);
    } catch (e) {}
    await _storage.delete(key: 'access_token');
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFFF5A623)),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF7F7F7),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFF5A623), width: 1.4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F7F7),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFFDBE00)),
              )
            : RefreshIndicator(
                onRefresh: _fetchUserProfile,
                color: const Color(0xFFFDBE00),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: _pickImage,
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: const Color(0xFFFFE9A8),
                                backgroundImage: _imageFile != null
                                    ? FileImage(_imageFile!)
                                    : (_avatarUrl != null
                                          ? NetworkImage(_avatarUrl!)
                                                as ImageProvider
                                          : null),
                                child: _imageFile == null && _avatarUrl == null
                                    ? const Icon(
                                        Icons.person_rounded,
                                        size: 56,
                                        color: Color(0xFFF5A623),
                                      )
                                    : null,
                              ),
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF5A623),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Section 1: Detail Profil Teks
                        TextFormField(
                          controller: _nameController,
                          decoration: _fieldDecoration(
                            label: 'Nama Lengkap',
                            icon: Icons.person_outline_rounded,
                          ),
                          validator: (value) =>
                              (value == null || value.trim().isEmpty)
                              ? 'Nama tidak boleh kosong'
                              : null,
                        ),
                        const SizedBox(height: 18),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _fieldDecoration(
                            label: 'Alamat Email',
                            icon: Icons.email_outlined,
                          ),
                          validator: (value) =>
                              (value == null || value.trim().isEmpty)
                              ? 'Email tidak boleh kosong'
                              : null,
                        ),

                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20.0),
                          child: Divider(thickness: 1),
                        ),

                        // Section 2: Form Ganti Password (Opsional)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Ganti Password (Kosongkan jika tidak diubah)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: _fieldDecoration(
                            label: 'Password Baru',
                            icon: Icons.lock_outline_rounded,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.grey.shade600,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value != null &&
                                value.isNotEmpty &&
                                value.length < 6) {
                              return 'Password minimal 6 karakter';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _passwordConfirmController,
                          obscureText: _obscureConfirmPassword,
                          decoration: _fieldDecoration(
                            label: 'Konfirmasi Password Baru',
                            icon: Icons.lock_clock_outlined,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.grey.shade600,
                              ),
                              onPressed: () => setState(
                                () => _obscureConfirmPassword =
                                    !_obscureConfirmPassword,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (_passwordController.text.isNotEmpty &&
                                (value == null || value.isEmpty)) {
                              return 'Konfirmasi password wajib diisi';
                            }
                            if (value != _passwordController.text) {
                              return 'Konfirmasi password tidak cocok';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),

                        // Aksi Simpan & Keluar
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF5A623),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          onPressed: _isSaving ? null : _updateProfile,
                          child: _isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Simpan Perubahan',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            minimumSize: const Size(double.infinity, 50),
                            side: BorderSide(color: Colors.red.shade200),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.logout_rounded, size: 18),
                          label: const Text(
                            'Keluar dari Akun',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          onPressed: () => _logout(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
