import 'package:flutter/material.dart';
import '../network/api_client.dart';
import '../constants/api_endpoints.dart';
import '../utils/formatter.dart';
import 'profile_screen.dart';
import 'campaign_screen.dart';
import 'history_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;

  String _userName = 'Donatur';
  String? _avatarUrl;

  // Variabel Informasi Alur Kitabisa Style
  int _totalCampaignsActive = 0;
  int _myTotalDonationsCount = 0;
  double _myTotalDonatedAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _loadKitabisaDashboardData();
  }

  // Pengambilan data paralel (Efisiensi muat data super cepat)
  Future<void> _loadKitabisaDashboardData() async {
    try {
      setState(() => _isLoading = true);

      // Menembak 3 jalur data sekaligus: Profil, Semua Campaign, dan Riwayat Transaksi User
      final responses = await Future.wait([
        _apiClient.dio.get('/user'),
        _apiClient.dio.get('/campaigns'),
        _apiClient.dio.get(
          '/donations/history',
        ), // Mengambil riwayat untuk kalkulasi statistik personal
      ]);

      // 1. Pemetaan Data Profil User
      if (responses[0].statusCode == 200) {
        final userData = responses[0].data;
        _userName = userData['name'] ?? 'Donatur';
        final String? dbAvatar = userData['avatar_path'] ?? userData['avatar'];
        if (dbAvatar != null && dbAvatar.isNotEmpty) {
          _avatarUrl =
              "${ApiEndpoints.baseUrl.replaceAll('/api', '')}/storage/$dbAvatar";
        } else {
          _avatarUrl = null;
        }
      }

      // 2. Pemetaan Data Campaign Global
      if (responses[1].statusCode == 200 &&
          responses[1].data['success'] == true) {
        final List<dynamic> campaigns = responses[1].data['data'] ?? [];
        _totalCampaignsActive = campaigns.length;
      }

      // 3. Kalkulasi Statistik Ala Kitabisa (Total Kantong Donasi Saya)
      if (responses[2].statusCode == 200 &&
          responses[2].data['success'] == true) {
        final List<dynamic> historyData = responses[2].data['data'] ?? [];

        // Filter hanya transaksi yang BERHASIL (settlement / success)
        final successfulDonations = historyData.where((item) {
          final status = item['status']?.toString().toLowerCase() ?? '';
          return status == 'settlement' || status == 'success';
        }).toList();

        _myTotalDonationsCount = successfulDonations.length;

        // Jumlahkan nominal uang yang sudah disumbangkan
        _myTotalDonatedAmount = successfulDonations.fold(0.0, (sum, item) {
          final amountRaw = item['amount'];
          final double amount =
              double.tryParse(amountRaw?.toString() ?? '0') ?? 0.0;
          return sum + amount;
        });
      }
    } catch (e) {
      debugPrint("Error loading Kitabisa Dashboard: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Colors.blue,
                  strokeWidth: 3,
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadKitabisaDashboardData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ================= KEPALA DASHBOARD (HEADER & PROFILE) =================
                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(24),
                            bottomRight: Radius.circular(24),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const ProfileScreen(),
                                      ),
                                    ).then((_) => _loadKitabisaDashboardData());
                                  },
                                  child: CircleAvatar(
                                    radius: 24,
                                    backgroundColor: Colors.blue.shade50,
                                    backgroundImage: _avatarUrl != null
                                        ? NetworkImage(_avatarUrl!)
                                        : null,
                                    child: _avatarUrl == null
                                        ? const Icon(
                                            Icons.person,
                                            color: Colors.blue,
                                            size: 24,
                                          )
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Selamat Datang 👋',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        _userName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.notifications_none_rounded,
                                  color: Colors.black54,
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // ================= KANTONG KEBAIKAN (DOMPET DONASI STYLE KITABISA) =================
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade600,
                                borderRadius: BorderRadius.circular(16),
                                image: const DecorationImage(
                                  image: AssetImage(
                                    'assets/images/pattern.png',
                                  ), // Opsional jika ada aset pola banner
                                  fit: BoxFit.cover,
                                  opacity: 0.1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(
                                        Icons.wallet_giftcard_rounded,
                                        color: Colors.white70,
                                        size: 18,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'Total Donasi Anda',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    CurrencyFormatter.toRupiah(
                                      _myTotalDonatedAmount,
                                    ),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 12.0,
                                    ),
                                    child: Divider(
                                      color: Colors.white24,
                                      height: 1,
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '$_myTotalDonationsCount Kali Berbagi Kebaikan',
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.9,
                                          ),
                                          fontSize: 12,
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const HistoryScreen(),
                                            ),
                                          );
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white24,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: const Row(
                                            children: [
                                              Text(
                                                'Riwayat',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              SizedBox(width: 4),
                                              Icon(
                                                Icons.arrow_forward_ios_rounded,
                                                color: Colors.white,
                                                size: 10,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ================= MENU EKSPLORASI / ANALITIK UTAMA =================
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Menu Penyaluran',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Baris Menu 1: Jelajah Campaign
                            _buildKitabisaMenuCard(
                              icon: Icons.favorite_rounded,
                              iconColor: Colors.pink,
                              title: 'Salurkan Bantuan Baru',
                              subtitle:
                                  'Lihat $_totalCampaignsActive galang dana mendesak yang butuh pertolongan',
                              badgeText: 'Mendesak',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const CampaignScreen(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 12),

                            // Baris Menu 2: Pantau Transaksi Midtrans
                            _buildKitabisaMenuCard(
                              icon: Icons.receipt_long_rounded,
                              iconColor: Colors.blue.shade700,
                              title: 'Status Pembayaran Instan',
                              subtitle:
                                  'Cek token status pending/sukses transaksi Midtrans Snap Anda',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const HistoryScreen(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 12),

                            // Baris Menu 3: Edit Profil Pengguna
                            _buildKitabisaMenuCard(
                              icon: Icons.manage_accounts_rounded,
                              iconColor: Colors.teal,
                              title: 'Pengaturan Akun & Profil',
                              subtitle:
                                  'Perbarui nama lengkap, email instansi, atau ganti password keamanan',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ProfileScreen(),
                                  ),
                                ).then((_) => _loadKitabisaDashboardData());
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // Komponen Pembuat Kartu Menu Eksplorasi Premium ala Kitabisa
  Widget _buildKitabisaMenuCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    String? badgeText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          if (badgeText != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.pink.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                badgeText,
                                style: const TextStyle(
                                  color: Colors.pink,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                const Align(
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.black26,
                    size: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
