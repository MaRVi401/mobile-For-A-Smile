import 'package:flutter/material.dart';
import '../network/api_client.dart';
import '../utils/formatter.dart';
import 'payment_web_view_screen.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class CampaignDetailScreen extends StatefulWidget {
  final int campaignId;
  const CampaignDetailScreen({super.key, required this.campaignId});

  @override
  State<CampaignDetailScreen> createState() => _CampaignDetailScreenState();
}

class _CampaignDetailScreenState extends State<CampaignDetailScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  Map<String, dynamic>? _detailData;

  @override
  void initState() {
    super.initState();
    _fetchCampaignDetail();
  }

  void _fetchCampaignDetail() async {
    try {
      final response = await _apiClient.dio.get(
        '/campaigns/${widget.campaignId}',
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          _detailData = response.data['data'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint("Error fetching campaign details: $e");
    }
  }

  void _openDonationDialog() {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController notesController = TextEditingController();
    bool isAnonymous = false;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: StatefulBuilder(
              builder: (context, setDialogState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Masukkan Nominal Donasi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (value) {
                        if (value.isEmpty) return;

                        String cleaned = value.replaceAll(
                          RegExp(r'[^0-9]'),
                          '',
                        );
                        int? parsed = int.tryParse(cleaned);

                        if (parsed != null) {
                          String formatted = CurrencyFormatter.toRupiah(
                            parsed,
                          ).replaceAll('Rp', '').replaceAll(' ', '').trim();

                          amountController.value = TextEditingValue(
                            text: formatted,
                            selection: TextSelection.collapsed(
                              offset: formatted.length,
                            ),
                          );
                        }
                      },
                      decoration: InputDecoration(
                        prefixText: 'Rp ',
                        prefixStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        hintText: '10.000',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // CHECKBOX ANONIM (PERBAIKAN FITUR 1)
                    CheckboxListTile(
                      title: const Text(
                        'Sembunyikan nama saya (Hamba Allah)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      value: isAnonymous,
                      onChanged: (bool? value) {
                        setDialogState(() {
                          isAnonymous = value ?? false;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),

                    const SizedBox(height: 8),

                    // INPUT DOA / CATATAN (PERBAIKAN FITUR 2)
                    TextField(
                      controller: notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Pesan / Doa Kebaikan (Opsional)',
                        hintText: 'Tuliskan doa atau ucapan dukungan...',
                        labelStyle: const TextStyle(fontSize: 13),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Batal',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE53935),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                          onPressed: () {
                            final String rawAmount = amountController.text;
                            final String notes = notesController.text;
                            Navigator.pop(context);
                            _processDonation(
                              amountStr: rawAmount,
                              isAnonymous: isAnonymous,
                              notes: notes,
                            );
                          },
                          child: const Text(
                            'Lanjutkan',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _processDonation({
    required String amountStr,
    required bool isAnonymous,
    required String notes,
  }) async {
    String cleanedAmount = amountStr.replaceAll('.', '');
    int? amount = int.tryParse(cleanedAmount);

    if (amount == null || amount < 10000) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nominal donasi minimal Rp 10.000')),
      );
      return;
    }

    try {
      final response = await _apiClient.dio.post(
        '/donations',
        data: {
          'campaign_id': widget.campaignId,
          'amount': amount,
          'is_anonymous': isAnonymous ? 1 : 0,
          'notes': notes,
        },
      );

      if (!mounted) return;

      if (response.statusCode == 201 && response.data['success'] == true) {
        final String redirectUrl =
            response.data['redirect_url'] ?? response.data['snap_url'] ?? '';

        if (redirectUrl.isNotEmpty) {
          final campaign = _detailData?['campaign_details'];

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentWebViewScreen(
                url: redirectUrl,
                transactionData: {
                  'order_id': response.data['data']?['order_id'] ?? 'FAS-000',
                  'amount': amount,
                  'campaign_title': campaign?['title'] ?? 'Donasi Kebaikan',
                  'is_anonymous': isAnonymous,
                  'notes': notes,
                  'donor_name': isAnonymous ? 'Hamba Allah' : 'Donatur',
                },
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal mendapatkan link pembayaran dari server.'),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error processing donation: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal membuat transaksi donasi')),
      );
    }
  }

  num _safeParse(dynamic value) {
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '0') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFFDBE00)),
        ),
      );
    }

    if (_detailData == null) {
      return const Scaffold(
        body: Center(child: Text('Gagal memuat detail data campaign.')),
      );
    }

    final campaign = _detailData!['campaign_details'];
    final report = _detailData!['transparency_report'];
    final List<dynamic> programs = _detailData!['programs'] ?? [];
    final List<dynamic> distributions =
        _detailData!['distribution_history'] ?? [];

    final String? imageUrl = campaign['image_url'];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        centerTitle: true,
        title: Text(
          campaign['title'] ?? 'Detail Campaign',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar utama campaign
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Image.asset(
                        'assets/images/fas-logo.png',
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.contain,
                      ),
                    )
                  : Image.asset(
                      'assets/images/fas-logo.png',
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.contain,
                    ),
            ),

            const SizedBox(height: 16),

            // Deskripsi
            Text(
              'Target Dana: ${CurrencyFormatter.toRupiah(_safeParse(campaign['target_amount']))}',
              style: const TextStyle(
                color: Color(0xFFF5A623),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              campaign['description'] ?? 'Tidak ada deskripsi cerita.',
              style: const TextStyle(
                fontSize: 14,
                height: 1.6,
                color: Colors.black87,
              ),
              textAlign: TextAlign.justify,
            ),

            const SizedBox(height: 24),

            // Program Kerja
            if (programs.isNotEmpty) ...[
              const Text(
                'Program Kegiatan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...programs.map((prog) => _buildProgramCard(prog)),
              const SizedBox(height: 12),
            ],

            const SizedBox(height: 12),

            // Laporan Dana
            const Text(
              'Ringkasan Dana',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14.0),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3D9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildReportRow(
                    'Total Terkumpul',
                    CurrencyFormatter.toRupiah(
                      _safeParse(report['total_collected']),
                    ),
                    Colors.green.shade700,
                  ),
                  const SizedBox(height: 8),
                  _buildReportRow(
                    'Total Disalurkan',
                    CurrencyFormatter.toRupiah(
                      _safeParse(report['total_distributed']),
                    ),
                    const Color(0xFFF5A623),
                  ),
                  const Divider(height: 20),
                  _buildReportRow(
                    'Sisa Saldo Kas',
                    CurrencyFormatter.toRupiah(
                      _safeParse(report['remaining_balance']),
                    ),
                    Colors.blue.shade700,
                    isBold: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Riwayat Penyaluran Donasi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            distributions.isEmpty
                ? const Text(
                    'Belum ada riwayat distribusi dana.',
                    style: TextStyle(color: Colors.grey),
                  )
                : // ================= RIWAYAT PENYALURAN DANA =================
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: distributions.length,
                    itemBuilder: (context, index) {
                      final dist = distributions[index];

                      // 1. Ambil URL PDF dari key baru
                      final String? reportPdfUrl = dist['report_file_url'];
                      final bool hasPdf =
                          reportPdfUrl != null && reportPdfUrl.isNotEmpty;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12.0),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Disalurkan: Rp ${NumberFormat('#,###', 'id_ID').format(dist['amount_distributed'] ?? 0)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFF5A623),
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Penerima: ${dist['beneficiary_name']}\nCatatan: ${dist['notes']}',
                                        style: const TextStyle(
                                          height: 1.4,
                                          fontSize: 12,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  dist['date'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),

                            // 2. Tombol Trigger Modal Pop-up PDF Preview
                            if (hasPdf) ...[
                              const SizedBox(height: 10),
                              InkWell(
                                onTap: () => _showPdfPreviewDialog(
                                  context,
                                  reportPdfUrl,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFEBEE),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(
                                        0xFFE53935,
                                      ).withOpacity(0.3),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.picture_as_pdf_rounded,
                                        size: 16,
                                        color: Color(0xFFE53935),
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'Lihat Dokumen RAB (PDF)',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFE53935),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            icon: const Icon(Icons.volunteer_activism),
            label: const Text(
              'Kirim Donasi Sekarang',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            onPressed: _openDonationDialog,
          ),
        ),
      ),
    );
  }

  Widget _buildProgramCard(dynamic prog) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5A623),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Text(
              prog['program_name'] ?? '',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child:
                      prog['image_url'] != null &&
                          prog['image_url'].toString().isNotEmpty
                      ? Image.network(
                          prog['image_url'],
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.assignment),
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    prog['description'] ?? '',
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportRow(
    String label,
    String value,
    Color color, {
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // Helper dialog untuk preview dokumen PDF tanpa perlu download manual
  void _showPdfPreviewDialog(BuildContext context, String pdfUrl) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        clipBehavior: Clip.antiAlias,
        child: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.8,
          color: Colors.white,
          child: Column(
            children: [
              // Header Pop-up
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                color: const Color(0xFFE53935),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.picture_as_pdf_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Dokumen Laporan / RAB',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Body PDF Preview (Streaming bytes dari API)
              Expanded(
                child: FutureBuilder<Uint8List>(
                  future: () async {
                    final dio = Dio();
                    final response = await dio.get<List<int>>(
                      pdfUrl,
                      options: Options(responseType: ResponseType.bytes),
                    );
                    return Uint8List.fromList(response.data!);
                  }(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: Color(0xFFE53935)),
                            SizedBox(height: 12),
                            Text(
                              'Memuat dokumen PDF...',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    if (snapshot.hasError || !snapshot.hasData) {
                      return Center(
                        child: Text(
                          'Gagal memuat dokumen: ${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      );
                    }

                    return PdfPreview(
                      build: (format) => snapshot.data!,
                      allowPrinting: true,
                      allowSharing: true,
                      canChangeOrientation: false,
                      canChangePageFormat: false,
                      canDebug: false,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
