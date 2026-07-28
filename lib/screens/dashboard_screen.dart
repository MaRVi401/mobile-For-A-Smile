import 'package:flutter/material.dart';
import '../network/api_client.dart';
import '../constants/api_endpoints.dart';
import '../utils/formatter.dart';
import 'profile_screen.dart';
import 'campaign_screen.dart';
import 'history_screen.dart';
import 'campaign_detail_screen.dart';

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

  // Diturunkan dari historyData yang sudah difetch (bukan API baru)
  DateTime? _lastDonationDate;

  // Campaign terbaru, diambil dari list /campaigns yang sudah difetch (bukan API baru)
  Map<String, dynamic>? _latestCampaign;

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

        // Ambil campaign pertama dari list sebagai "Campaign Terbaru"
        if (campaigns.isNotEmpty) {
          _latestCampaign = Map<String, dynamic>.from(campaigns.first);
        } else {
          _latestCampaign = null;
        }
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

        // Ambil tanggal donasi terakhir dari data yang sudah ada (tanpa API baru)
        DateTime? latest;
        for (final item in successfulDonations) {
          final dateRaw = item['created_at'] ?? item['date'];
          final parsed = DateTime.tryParse(dateRaw?.toString() ?? '');
          if (parsed != null && (latest == null || parsed.isAfter(latest))) {
            latest = parsed;
          }
        }
        _lastDonationDate = latest;
      }
    } catch (e) {
      debugPrint("Error loading Kitabisa Dashboard: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatLastDonation() {
    if (_lastDonationDate == null) return '-';
    final d = _lastDonationDate!;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  String _formatToday() {
    const hari = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    const bulan = [
      '',
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    final now = DateTime.now();
    final namaHari = hari[now.weekday - 1];
    return '$namaHari\n${now.day} ${bulan[now.month]} ${now.year}';
  }

  num _safeParse(dynamic value) {
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '0') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F7F7),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFFDBE00),
                  strokeWidth: 3,
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadKitabisaDashboardData,
                color: const Color(0xFFFDBE00),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ================= KEPALA DASHBOARD (HEADER & PROFILE) =================
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ProfileScreen(),
                                  ),
                                ).then((_) => _loadKitabisaDashboardData());
                              },
                              child: CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.orange.shade100,
                                backgroundImage: _avatarUrl != null
                                    ? NetworkImage(_avatarUrl!)
                                    : null,
                                child: _avatarUrl == null
                                    ? const Icon(
                                        Icons.person,
                                        color: Color(0xFFFDBE00),
                                        size: 26,
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Hallo !',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    _userName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _formatToday().split('\n').first,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                Text(
                                  _formatToday().split('\n').last,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // ================= KANTONG KEBAIKAN (STATISTIK ALA MOCKUP) =================
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 20,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5A623),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildStatItem(
                                  icon: Icons.monetization_on_rounded,
                                  label: 'Total Donasi Anda',
                                  value: CurrencyFormatter.toRupiah(
                                    _myTotalDonatedAmount,
                                  ),
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 50,
                                color: Colors.white38,
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const HistoryScreen(),
                                      ),
                                    );
                                  },
                                  child: _buildStatItem(
                                    icon: Icons.volunteer_activism_rounded,
                                    label: 'Terakhir Donasi',
                                    value: _formatLastDonation(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ================= CAMPAIGN TERBARU =================
                      if (_latestCampaign != null) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Campaign Terbaru',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const CampaignScreen(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Lihat Semua',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFFF5A623),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                          child: _buildLatestCampaignCard(_latestCampaign!),
                        ),
                      ],

                      // ================= MENU EKSPLORASI / ANALITIK UTAMA =================
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Program kampanye',
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
                              title: 'Salurkan Bantuan Baru',
                              subtitle:
                                  'Lihat $_totalCampaignsActive galang dana mendesak yang butuh pertolongan',
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

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFFF5A623), size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.black87, fontSize: 12),
        ),
      ],
    );
  }

  // Card untuk menampilkan campaign terbaru (data diambil dari list /campaigns yang sudah difetch)
  Widget _buildLatestCampaignCard(Map<String, dynamic> campaign) {
    final int campaignId = campaign['id'] ?? 0;
    final String title = campaign['title'] ?? 'Tanpa Judul';
    String? imageUrl = campaign['image_url'];

    if (imageUrl != null && imageUrl.isNotEmpty) {
      if (imageUrl.contains('localhost')) {
        imageUrl = imageUrl.replaceAll('localhost', '10.0.2.2');
      }
    }

    final num targetAmount = _safeParse(campaign['target_amount']);
    final num totalCollected = _safeParse(campaign['total_collected']);
    final num progressPercentage = _safeParse(campaign['progress_percentage']);

    double progressValue = progressPercentage > 0
        ? (progressPercentage / 100.0)
        : 0.0;
    if (progressValue > 1.0) progressValue = 1.0;
    if (progressValue < 0.0) progressValue = 0.0;

    final bool isDone = progressPercentage >= 100;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5A623),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.circle,
                    size: 8,
                    color: isDone
                        ? Colors.green.shade300
                        : Colors.amber.shade100,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isDone ? 'Selesai' : 'Berlangsung',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        key: ValueKey(imageUrl),
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Image.asset(
                              'assets/images/fas-logo.png',
                              width: 90,
                              height: 90,
                              fit: BoxFit.contain,
                            ),
                      )
                    : Image.asset(
                        'assets/images/fas-logo.png',
                        width: 90,
                        height: 90,
                        fit: BoxFit.contain,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: SizedBox(
                        height: 18,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Container(color: Colors.white),
                            FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: progressValue,
                              child: Container(color: Colors.green),
                            ),
                            Center(
                              child: Text(
                                '${progressPercentage.round()}%',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          isDone
              ? Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Berhasil Terkumpul ${CurrencyFormatter.toRupiah(totalCollected)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                )
              : Text(
                  'Terkumpul ${CurrencyFormatter.toRupiah(totalCollected)} Dari ${CurrencyFormatter.toRupiah(targetAmount)}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          CampaignDetailScreen(campaignId: campaignId),
                    ),
                  ).then((_) => _loadKitabisaDashboardData());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDone
                      ? Colors.grey.shade400
                      : const Color(0xFFE53935),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Donasi Sekarang',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          CampaignDetailScreen(campaignId: campaignId),
                    ),
                  ).then((_) => _loadKitabisaDashboardData());
                },
                child: const Text(
                  'Lihat detail kampanye',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Komponen Pembuat Kartu Menu — gaya rounded border kuning ala mockup
  Widget _buildKitabisaMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFE9A8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black, width: 1.2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: const Color(0xFFF5A623), size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Colors.black54,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.black45,
                  size: 12,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
