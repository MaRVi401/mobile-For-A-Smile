import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_endpoints.dart';

class ApiClient {
  final Dio _dio = Dio();
  final _storage = const FlutterSecureStorage();

  ApiClient() {
    // 1. Mengatur Base Options secara global
    _dio.options = BaseOptions(
      baseUrl: ApiEndpoints.baseUrl, // Definisikan URL utama Anda di sini
      connectTimeout: const Duration(
        seconds: 10,
      ), // Batas waktu koneksi (opsional)
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );

    // 2. Menggabungkan Interceptor Request & Error
    _dio.interceptors.add(
      InterceptorsWrapper(
        // Menempelkan token sebelum request dikirim
        onRequest: (options, handler) async {
          String? token = await _storage.read(key: 'access_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options); // Perbaikan: hilangkan kata 'return'
        },

        // 3. Tambahan: Menangani response error secara global (misal: Token Expired)
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
            print("Token tidak valid atau expired. Menghapus storage...");

            // Hapus token dari storage karena sudah tidak bisa digunakan
            await _storage.delete(key: 'access_token');

            // TODO: Tambahkan trigger untuk mengarahkan user kembali ke Halaman Login
            // Contoh jika menggunakan navigator key atau event bus / state management
          }
          handler.next(
            e,
          ); // Lanjutkan error agar tetap bisa di-catch di layer UI jika dibutuhkan
        },
      ),
    );
  }

  Dio get dio => _dio;
}
