class ApiEndpoints {
  // Gunakan '10.0.2.2' jika Anda pakai Emulator Android bawaan.
  // Jika pakai HP fisik, ganti menjadi IP Laptop Anda (misal: '192.168.1.5')
  static const String baseUrl = "https://1bd8-140-213-35-65.ngrok-free.app/api";

  static const String register = "$baseUrl/register";
  static const String login = "$baseUrl/login";
  static const String logout = "$baseUrl/logout";
  static const String forgotPassword = "$baseUrl/forgot-password";
  static const String resetPassword = "$baseUrl/reset-password";
}
