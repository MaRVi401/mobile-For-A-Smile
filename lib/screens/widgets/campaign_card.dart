import 'package:flutter/material.dart';
import '../campaign_detail_screen.dart';
import '../campaign_report_screen.dart';

class CampaignCard extends StatelessWidget {
  final Map<String, dynamic> campaign;

  const CampaignCard({super.key, required this.campaign});

  @override
  Widget build(BuildContext context) {
    // Parsing ID secara aman
    final int campaignId = campaign['id'] is int
        ? campaign['id']
        : int.tryParse(campaign['id']?.toString() ?? '1') ?? 1;

    final String title = campaign['title'] ?? 'Campaign Donasi';
    final String imageUrl =
        campaign['image_url'] ?? 'https://via.placeholder.com/150';

    // Konversi aman dari String/Dynamic ke Double untuk menghindari error 'String is not a subtype of num'
    final double currentAmount =
        double.tryParse(campaign['current_amount']?.toString() ?? '0') ?? 0.0;
    final double targetAmount =
        double.tryParse(campaign['target_amount']?.toString() ?? '1') ?? 1.0;

    // Hitung persentase progres donasi
    double progress = currentAmount / targetAmount;
    if (progress > 1.0) progress = 1.0;
    if (progress < 0.0) progress = 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gambar Banner Campaign
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.network(
              imageUrl,
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 160,
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(
                      Icons.broken_image,
                      color: Colors.grey,
                      size: 40,
                    ),
                  ),
                );
              },
            ),
          ),
          // Judul dan Progres Bar Donasi
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                Row(
                  // PERBAIKAN DI SINI: Mengubah 'between' menjadi 'spaceBetween'
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Terkumpul: Rp ${campaign['current_amount'] ?? 0}",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      "${(progress * 100).toStringAsFixed(0)}%",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[200],
                  color: const Color(
                    0xFF2ECC71,
                  ), // Warna Emerald Green aman kustom
                  minHeight: 6,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Tombol Navigasi Detail & Laporan Dana
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          CampaignDetailScreen(campaignId: campaignId),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.chrome_reader_mode_outlined,
                  size: 18,
                  color: Colors.blue,
                ),
                label: const Text(
                  "Detail Program",
                  style: TextStyle(color: Colors.blue),
                ),
              ),
              Container(
                width: 1,
                height: 25,
                color: Colors.grey[300],
              ), // Garis Pembatas Vertikal
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          CampaignReportScreen(campaignId: campaignId),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.bar_chart_rounded,
                  size: 18,
                  color: Colors.orange,
                ),
                label: const Text(
                  "Laporan Dana",
                  style: TextStyle(color: Colors.orange),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
