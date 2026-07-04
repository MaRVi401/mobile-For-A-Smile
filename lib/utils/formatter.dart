import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String toRupiah(num amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID', // Gunakan locale Indonesia untuk format mata uang Rupiah
      symbol: 'Rp ', // Gunakan spasi setelah simbol mata uang
      decimalDigits: 0, // Menghilangkan buntut desimal .00
    );
    return formatter.format(amount);
  }
}
