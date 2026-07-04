import 'package:flutter/material.dart';
import '../campaign_detail_screen.dart';
import '../campaign_report_screen.dart';

class CampaignCard extends StatelessWidget {
  final Map<String, dynamic> campaign;

  const CampaignCard({super.key, required this.campaign});

  @override
  Widget build(BuildContext context) {
    final int campaignId = campaign['id'] ?? 0;
    final String title = campaign['title'] ?? 'Tanpa Judul';
    final String? imageUrl = campaign['image_url'];

    // Amankan parsing tipe data JSON dari Laravel
    final num targetAmount = campaign['target_amount'] is num
        ? campaign['target_amount']
        : (num.tryParse(campaign['target_amount']?.toString() ?? '0') ?? 0);

    final num totalCollected = campaign['total_collected'] is num
        ? campaign['total_collected']
        : (num.tryParse(campaign['total_collected']?.toString() ?? '0') ?? 0);

    final num progressPercentage = campaign['progress_percentage'] is num
        ? campaign['progress_percentage']
        : (num.tryParse(campaign['progress_percentage']?.toString() ?? '0') ??
              0);

    // Hitung persentase progress untuk LinearProgressIndicator (skala 0.0 - 1.0)
    double progressValue = progressPercentage > 0
        ? (progressPercentage / 100.0)
        : 0.0;
    if (progressValue > 1.0) progressValue = 1.0;
    if (progressValue < 0.0) progressValue = 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Gambar Campaign (Dilengkapi Fallback ke Gambar Aset Default)
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: imageUrl != null && imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    // Jika URL ada tapi gagal load (misal masalah internet/server)
                    errorBuilder: (context, error, stackTrace) => Image.asset(
                      'assets/images/fas-logo.png',
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit
                          .contain, // contain agar logo yayasan tidak terpotong
                    ),
                  )
                : Image.asset(
                    'assets/images/fas-logo.png',
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.contain,
                  ),
          ),

          // Konten Teks & Progress
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Judul Campaign
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),

                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progressValue,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.blue,
                    ),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 10),

                // Informasi Dana Terkumpul & Target
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Terkumpul',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          'Rp $totalCollected',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Target',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          'Rp $targetAmount',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Badge Persentase & Row Aksi Tombol
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Sisi Kiri: Tombol Navigasi Aksi Ekstra
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CampaignDetailScreen(
                                  campaignId: campaignId,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.info_outline, size: 16),
                          label: const Text(
                            'Detail Campaign',
                            style: TextStyle(fontSize: 12),
                          ),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(60, 30),
                          ),
                        ),
                        const SizedBox(width: 16),
                        TextButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CampaignReportScreen(
                                  campaignId: campaignId,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.assignment_outlined, size: 16),
                          label: const Text(
                            'Riwayat Distribusi',
                            style: TextStyle(fontSize: 12),
                          ),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(70, 30),
                            foregroundColor: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    // Sisi Kanan: Status Persentase
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${progressPercentage.round()}%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
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
    );
  }
}
