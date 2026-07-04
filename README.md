# Mobile for a Smile (for_asmile_app)

[![Flutter Version](https://img.shields.io/badge/Flutter-%5E3.8.1-blue.svg)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey.svg)]()

**Mobile for a Smile** adalah aplikasi mobile berbasis Flutter yang dirancang khusus sebagai platform donasi online. Aplikasi ini memungkinkan pengguna untuk menjelajahi berbagai kampanye kebaikan, memberikan kontribusi donasi secara real-time, memantau laporan transparansi dana, serta mengelola riwayat transaksi secara aman.

---

## 🚀 Fitur Utama

- **Sistem Autentikasi Lengkap**: Registrasi, Login, Lupa Kata Sandi (Forgot Password), dan Reset Kata Sandi.
- **Dashboard Interaktif**: Menampilkan ringkasan informasi, banner, dan daftar kampanye pilihan.
- **Manajemen Kampanye**: Jelajahi daftar kampanye aktif beserta detail lengkap per kampanye.
- **Laporan Transparansi (Campaign Reports)**: Pengguna dapat melihat pembaruan dan laporan penggunaan dana dari kampanye yang didukung.
- **Gerbang Pembayaran Terintegrasi**: Menggunakan komponen *WebView* untuk penyelesaian pembayaran donasi secara aman.
- **Riwayat Donasi**: Catatan lengkap transaksi donasi yang pernah dilakukan oleh pengguna.
- **Manajemen Profil**: Pengaturan akun pengguna termasuk opsi pembaruan foto profil melalui *Image Picker*.

---

## 🛠️ Tech Stack & Dependensi

Aplikasi ini dibangun menggunakan modul-modul andal berikut:
- **Core**: Flutter SDK & Dart SDK (`^3.8.1`)
- **State Management & Network**: `dio` (untuk konsumsi REST API secara efisien)
- **Local Storage**: `flutter_secure_storage` (untuk penyimpanan token autentikasi yang aman)
- **UI & Widget**: `webview_flutter` (gerbang pembayaran), `image_picker` (unggah gambar/foto profil), `cupertino_icons`
- **Utility**: `intl` (format mata uang, tanggal, dan lokalisasi)

---

## 📋 Prasyarat Sistem

Sebelum memulai, pastikan perangkat pengembangan Anda telah memenuhi spesifikasi berikut:

1. **Flutter SDK**: Versi `>= 3.8.1`
2. **Dart SDK**: Sesuai bawaan Flutter yang terpasang
3. **Android Studio / VS Code** (beserta ekstensi Flutter & Dart)
4. **Android SDK Platform** & **Android NDK (Versi 26.x.x)**

---

## ⚙️ Konfigurasi Khusus (Android NDK 26)

Proyek ini memerlukan **Android NDK versi 26**. Pastikan Anda mengaturnya di level proyek Android Anda.

### 1. Unduh NDK 26 via Android Studio
1. Buka Android Studio.
2. Pergi ke **Tools > SDK Manager > SDK Tools**.
3. Centang opsi **Show Package Details** di pojok kanan bawah.
4. Cari bagian **NDK (Side by side)**, lalu centang versi **26.x.x** (misal: `26.1.10909125`).
5. Klik **Apply** dan tunggu proses unduhan selesai.

### 2. Verifikasi File `android/app/build.gradle.kts`
Pastikan properti `ndkVersion` telah merujuk pada versi 26 di dalam blok `android`:

```kotlin
android {
    compileSdk = 34 // atau versi SDK yang Anda gunakan
    ndkVersion = "26.1.10909125" // Sesuaikan dengan detail sub-versi NDK 26 Anda

    defaultConfig {
        applicationId = "com.example.for_asmile_app"
        minSdk = 21
        targetSdk = 34
        // ...
    }
}

```
---
# 🌐 Konfigurasi API Endpoint

Sebelum menjalankan aplikasi, ubah file berikut:

```
lib/constants/api_endpoints.dart
```

Sesuaikan nilai:

```dart
static const String baseUrl = "...";
```

Gunakan sesuai kebutuhan.

## Menggunakan Ngrok (Direkomendasikan)

```dart
static const String baseUrl =
    "https://xxxx.ngrok-free.app/api";
```

---

## Menggunakan Android Emulator (AVD)

```dart
static const String baseUrl =
    "http://10.0.2.2:8000/api";
```

---

### Menggunakan HP Fisik (Real Device)

Gunakan alamat IP lokal komputer/laptop yang menjalankan server Laravel.

Pastikan:

- Laptop dan HP berada pada jaringan Wi-Fi yang sama.
- Server Laravel sedang berjalan (`php artisan serve`).

Contoh:

```dart
static const String baseUrl =
    "http://<IP-LAPTOP>:8000/api";
```

Misalnya jika IP laptop adalah:

```text
192.168.18.27
```

maka:

```dart
static const String baseUrl =
    "http://192.168.18.27:8000/api";
```

> 💡 Untuk mengetahui IP laptop:
>
> **Windows**
> ```bash
> ipconfig
> ```
> Lihat bagian **IPv4 Address**.
>
> **Linux/macOS**
> ```bash
> ifconfig
> ```
> atau
> ```bash
> ip addr

---

Endpoint lainnya akan terbentuk secara otomatis.

```dart
static const String register = "$baseUrl/register";
static const String login = "$baseUrl/login";
static const String logout = "$baseUrl/logout";
static const String forgotPassword = "$baseUrl/forgot-password";
static const String resetPassword = "$baseUrl/reset-password";
```
---

## 🏃 Langkah Instalasi & Menjalankan Aplikasi

Ikuti urutan langkah di bawah ini untuk menduplikasi proyek ke perangkat lokal Anda:

### 1. Clone Repositori

Buka terminal/command prompt Anda, arahkan ke direktori kerja, lalu jalankan perintah:

```bash
git clone https://github.com/MaRVi401/mobile-For-A-Smile.git for_asmile

```

### 2. Masuk ke Direktori Proyek

```bash
cd for_asmile

```

### 3. Bersihkan Cache & Unduh Dependensi

Jalankan perintah berikut untuk mengunduh semua package yang terdaftar di dalam `pubspec.yaml`:

```bash
flutter clean
flutter pub get

```

### 4. Setup Aset Gambar

Pastikan direktori aset gambar telah tersedia karena aplikasi merujuk langsung pada folder tersebut:

```text
for_asmile_app/
└── assets/
    └── images/
        └── fas-logo.png  <-- Pastikan logo atau aset dasar diletakkan di sini

```

### 5. Hubungkan Perangkat (Device)

Pastikan Emulator Android/iOS telah berjalan, atau perangkat fisik Anda telah terhubung menggunakan kabel data dengan fitur *USB Debugging* aktif. Cek kesiapan perangkat dengan:

```bash
flutter devices

```

### 6. Jalankan Aplikasi

Eksekusi perintah berikut untuk mematangkan kompilasi dan menjalankan aplikasi pada mode *debug*:

```bash
flutter run

```

---

## 🗂️ Struktur Direktori Utama

```text
lib/
├── main.dart                      # Titik masuk utama (Entry point) jalannya aplikasi
├── constants/
│   └── api_endpoints.dart         # Pengelolaan alamat URL dan endpoint API
├── network/
│   └── api_client.dart            # Konfigurasi Dio Link, Header, & Interceptor HTTP
├── utils/
│   └── formatter.dart             # Helper pemformatan Rupiah (IDR) & Tanggal
└── screens/                       # Manajemen Halaman / Antarmuka (UI)
    ├── widgets/
    │   └── campaign_card.dart     # Komponen kartu kampanye donasi (Reusable)
    ├── login_screen.dart          # Halaman Masuk Akun
    ├── register_screen.dart       # Halaman Daftar Akun
    ├── forgot_password_screen.dart# Halaman Request OTP/Link Lupa Sandi
    ├── reset_password_screen.dart # Halaman Pembuatan Sandi Baru
    ├── dashboard_screen.dart      # Ringkasan menu utama & banner kampanye
    ├── main_navigation.dart       # Pengendali navigasi bawah (Bottom Navigation Bar)
    ├── campaign_screen.dart       # Daftar penjelajahan kampanye
    ├── campaign_detail_screen.dart# Informasi lengkap per kampanye donasi
    ├── campaign_report_screen.dart# Laporan penggunaan dana donasi
    ├── payment_web_view_screen.dart# Webview untuk pemrosesan gerbang pembayaran
    ├── history_screen.dart        # Log riwayat donasi pengguna
    └── profile_screen.dart        # Informasi akun & kontrol upload foto profil

```

---

## 🔒 Catatan Keamanan & Produksi

* **Token REST API**: Aplikasi ini menyimpan token autentikasi di dalam *Keychain* (iOS) atau *Keystore* (Android) melalui package `flutter_secure_storage`. Jangan memodifikasi konfigurasi enkripsi ini secara sembarangan untuk menjaga data kredensial pengguna.
* **Production Build**: Saat ingin melakukan rilis ke Play Store atau App Store, ubah konfigurasi lingkungan dari *Development* ke *Production* pada file konfigurasi endpoint API, lalu build menggunakan perintah `flutter build apk --release` atau `flutter build appbundle`.