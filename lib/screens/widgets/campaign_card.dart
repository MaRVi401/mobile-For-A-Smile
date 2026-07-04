import 'package:flutter/material.dart';
import '../../utils/formatter.dart';
import '../campaign_detail_screen.dart';
import '../campaign_report_screen.dart';

class CampaignCard extends StatelessWidget {
  final Map<String, dynamic> campaign;

  const CampaignCard({super.key, required this.campaign});

  @override
  Widget build(BuildContext context) {
    final int campaignId = campaign['id'] ?? 0;
    final String title = campaign['title'] ?? 'Tanpa Judul';
    String? imageUrl = campaign['image_url'];

    // --- PENANGANAN DAN PERBAIKAN URL GAMBAR ---
    if (imageUrl != null && imageUrl.isNotEmpty) {
      if (imageUrl.contains('localhost')) {
        imageUrl = imageUrl.replaceAll('localhost', '10.0.2.2');
      }
    }

    // --- AMANKAN PARSING TIPE DATA ---
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

    double progressValue = progressPercentage > 0
        ? (progressPercentage / 100.0)
        : 0.0;
    if (progressValue > 1.0) progressValue = 1.0;
    if (progressValue < 0.0) progressValue = 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Render Gambar Utama dengan Kunci Unik Otomatis
          imageUrl != null && imageUrl.isNotEmpty
              ? Image.network(
                  imageUrl,
                  // Trik Inti: ValueKey menggunakan URL gambar dinamis. Jika URL atau datanya berubah,
                  // Flutter dipaksa untuk membuang element lama dan mendownload gambar terbaru secara bersih.
                  key: ValueKey(imageUrl),
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Image.asset(
                    'assets/images/fas-logo.png',
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.contain,
                  ),
                )
              : Image.asset(
                  'assets/images/fas-logo.png',
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.contain,
                ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 14),

                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progressValue,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.blue,
                    ),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Terkumpul',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          CurrencyFormatter.toRupiah(totalCollected),
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
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          CurrencyFormatter.toRupiah(targetAmount),
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
                const Divider(height: 24, thickness: 0.8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
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
                            'Detail',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            backgroundColor: Colors.blue.shade50,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
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
                            'Laporan',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.orange.shade800,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            backgroundColor: Colors.orange.shade50,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade600,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${progressPercentage.round()}%',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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
