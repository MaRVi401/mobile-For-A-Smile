import 'package:flutter/material.dart';
import '../network/api_client.dart';
import 'campaign_detail_screen.dart';

class CampaignScreen extends StatefulWidget {
  const CampaignScreen({super.key});

  @override
  State<CampaignScreen> createState() => _CampaignScreenState();
}

class _CampaignScreenState extends State<CampaignScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  List<dynamic> _campaigns = [];

  // Filter pencarian lokal (tidak menambah request API baru)
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchCampaigns();
  }

  void _fetchCampaigns() async {
    try {
      final response = await _apiClient.dio.get('/campaigns');
      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          _campaigns = response.data['data'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint("Error fetching campaigns: $e");
    }
  }

  // Fungsi tambahan untuk menangani alur pembersihan cache RAM & hit ulang API
  Future<void> _handleRefresh() async {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    _fetchCampaigns();
  }

  List<dynamic> get _filteredCampaigns {
    if (_searchQuery.trim().isEmpty) return _campaigns;
    final q = _searchQuery.toLowerCase();
    return _campaigns.where((c) {
      final title = (c['title'] ?? '').toString().toLowerCase();
      return title.contains(q);
    }).toList();
  }

  num _safeParse(dynamic value) {
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '0') ?? 0;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: Column(
          children: [
            // ================= HEADER: SEARCH =================
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                  decoration: InputDecoration(
                    hintText: 'Cari Kampanye',
                    hintStyle: TextStyle(color: Colors.grey.shade600),
                    prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),

            // ================= FILTER TAHUN (UI saja, belum fungsional) =================
            // Padding(
            //   padding: const EdgeInsets.symmetric(horizontal: 16),
            //   child: Align(
            //     alignment: Alignment.centerLeft,
            //     child: Container(
            //       padding: const EdgeInsets.symmetric(
            //         horizontal: 12,
            //         vertical: 8,
            //       ),
            //       decoration: BoxDecoration(
            //         color: const Color(0xFFFDBE00),
            //         borderRadius: BorderRadius.circular(10),
            //       ),
            //       child: const Row(
            //         mainAxisSize: MainAxisSize.min,
            //         children: [
            //           Text(
            //             'Tahun 2026',
            //             style: TextStyle(
            //               fontWeight: FontWeight.bold,
            //               color: Colors.black87,
            //               fontSize: 13,
            //             ),
            //           ),
            //           SizedBox(width: 6),
            //           Icon(
            //             Icons.keyboard_arrow_down_rounded,
            //             size: 18,
            //             color: Colors.black87,
            //           ),
            //         ],
            //       ),
            //     ),
            //   ),
            // ),
            const SizedBox(height: 8),

            // ================= LIST CAMPAIGN =================
            Expanded(
              child: RefreshIndicator(
                onRefresh: _handleRefresh,
                color: const Color(0xFFFDBE00),
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFFDBE00),
                        ),
                      )
                    : _filteredCampaigns.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 200),
                          Center(
                            child: Text(
                              'Belum ada program campaign donasi saat ini.',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: _filteredCampaigns.length,
                        itemBuilder: (context, index) {
                          final campaign = _filteredCampaigns[index];
                          return _buildCampaignCard(campaign);
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCampaignCard(dynamic campaign) {
    final String? imageUrl = campaign['image_url'];
    final num target = _safeParse(campaign['target_amount']);
    final num collected = _safeParse(campaign['total_collected']);
    final double progress = target > 0
        ? (collected / target).clamp(0, 1).toDouble()
        : 0.0;
    final bool isDone = progress >= 1.0;
    final String status =
        campaign['status']?.toString() ?? (isDone ? 'selesai' : 'berlangsung');
    final bool isActive = status.toLowerCase() != 'selesai' && !isDone;

    // Ambil daftar 5 donatur terbaru dari response API
    final List<dynamic> recentDonors = campaign['recent_donors'] ?? [];

    String? processedImageUrl = imageUrl;
    if (processedImageUrl != null && processedImageUrl.isNotEmpty) {
      if (processedImageUrl.contains('localhost')) {
        processedImageUrl = processedImageUrl.replaceAll(
          'localhost',
          '10.0.2.2',
        );
      }
    }

    final bool isValidUrl =
        processedImageUrl != null &&
        processedImageUrl.trim().isNotEmpty &&
        !processedImageUrl.endsWith('/storage/') &&
        !processedImageUrl.endsWith('/null');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5A623),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge status
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.circle,
                  size: 8,
                  color: isActive
                      ? Colors.amber.shade100
                      : Colors.green.shade300,
                ),
                const SizedBox(width: 4),
                Text(
                  isActive ? 'Berlangsung' : 'Selesai',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: isValidUrl
                    ? Image.network(
                        processedImageUrl!,
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Image.asset(
                          'assets/images/fas-logo.png', // <-- Fallback jika gagal muat dari network
                          width: 90,
                          height: 90,
                          fit: BoxFit.contain,
                        ),
                      )
                    : Image.asset(
                        'assets/images/fas-logo.png', // <-- Fallback jika URL di database null/kosong
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
                      campaign['title'] ?? '-',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        children: [
                          Container(height: 18, color: Colors.white),
                          FractionallySizedBox(
                            widthFactor: progress,
                            child: Container(height: 18, color: Colors.green),
                          ),
                          SizedBox(
                            height: 18,
                            child: Center(
                              child: Text(
                                '${(progress * 100).toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          isActive
              ? Text(
                  'Terkumpul ${_formatRupiah(collected)} Dari ${_formatRupiah(target)}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                )
              : Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Berhasil Terkumpul ${_formatRupiah(collected)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

          // ================= KONTEN BARU: 5 DONATUR TERAKHIR (DROPDOWN) =================
          if (recentDonors.isNotEmpty) ...[
            const SizedBox(height: 12),
            Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 0,
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  dense: true,
                  iconColor: Colors.white,
                  collapsedIconColor: Colors.white,
                  leading: const Icon(
                    Icons.volunteer_activism_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                  title: Text(
                    'Lihat Donatur Terakhir (${recentDonors.length})',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  children: recentDonors.map((donor) {
                    final String name = donor['donor_name'] ?? 'Hamba Allah';
                    final num amount = _safeParse(donor['amount']);
                    final String? notes = donor['notes'];
                    final String? avatarUrl =
                        donor['avatar_url'] ?? donor['user']?['avatar_url'];
                    final bool isAnonymous = name == 'Hamba Allah';

                    return Container(
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ================= AVATAR PROFIL =================
                          ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: SizedBox(
                              width: 30,
                              height: 30,
                              child: isAnonymous
                                  ? Container(
                                      color: Colors.grey.shade200,
                                      child: Icon(
                                        Icons.visibility_off_outlined,
                                        size: 16,
                                        color: Colors.grey.shade600,
                                      ),
                                    )
                                  : (avatarUrl != null && avatarUrl.isNotEmpty)
                                  ? Image.network(
                                      avatarUrl,
                                      width: 30,
                                      height: 30,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                                color: const Color(0xFFFFF3D9),
                                                child: const Icon(
                                                  Icons.person,
                                                  size: 18,
                                                  color: Color(0xFFF5A623),
                                                ),
                                              ),
                                    )
                                  : Container(
                                      color: const Color(0xFFFFF3D9),
                                      child: const Icon(
                                        Icons.person,
                                        size: 18,
                                        color: Color(0xFFF5A623),
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      _formatRupiah(amount),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFE53935),
                                      ),
                                    ),
                                  ],
                                ),
                                if (notes != null &&
                                    notes.toString().trim().isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    '"$notes"',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.grey.shade700,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],

          // ==================================================================
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
                          CampaignDetailScreen(campaignId: campaign['id']),
                    ),
                  ).then((_) => _handleRefresh());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isActive
                      ? const Color(0xFFE53935)
                      : Colors.grey.shade400,
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
                          CampaignDetailScreen(campaignId: campaign['id']),
                    ),
                  ).then((_) => _handleRefresh());
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

  String _formatRupiah(num value) {
    final str = value.toInt().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      final posFromRight = str.length - i;
      buffer.write(str[i]);
      if (posFromRight > 1 && posFromRight % 3 == 1) {
        buffer.write('.');
      }
    }
    return 'Rp ${buffer.toString()}';
  }
}
