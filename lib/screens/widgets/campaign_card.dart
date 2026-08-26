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

    // --- VALIDASI URL GAMBAR (TIDAK DIUBAH) ---
    bool isValidUrl =
        imageUrl != null &&
        imageUrl.toString().trim().isNotEmpty &&
        !imageUrl.toString().endsWith('/storage/') &&
        !imageUrl.toString().endsWith('/null');

    // --- PENANGANAN DAN PERBAIKAN URL GAMBAR (TIDAK DIUBAH) ---
    if (imageUrl != null && imageUrl.isNotEmpty) {
      if (imageUrl.contains('localhost')) {
        imageUrl = imageUrl.replaceAll('localhost', '10.0.2.2');
      }
    }

    // --- AMANKAN PARSING TIPE DATA (TIDAK DIUBAH) ---
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

    final bool isDone = progressPercentage >= 100;

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5A623),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Baris status + akses laporan
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
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          CampaignReportScreen(campaignId: campaignId),
                    ),
                  );
                },
                child: const Icon(
                  Icons.assignment_outlined,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- GAMBAR THUMBNAIL ---
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child:
                    isValidUrl
                    ? Image.network(
                        imageUrl!,
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

                    // --- PROGRESS BAR: DIPERBAIKI (root cause bug) ---
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: SizedBox(
                        height: 18,
                        // width mengikuti lebar Expanded secara otomatis
                        child: Stack(
                          fit: StackFit
                              .expand, // <- kunci perbaikan: paksa semua child mengisi penuh area Stack
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
                  );
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
                  );
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
}
