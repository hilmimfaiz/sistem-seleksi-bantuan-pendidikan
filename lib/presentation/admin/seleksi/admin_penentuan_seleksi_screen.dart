import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../../../data/models/app_models.dart';
import '../../../providers/app_providers.dart';

class AdminPenentuanSeleksiScreen extends ConsumerStatefulWidget {
  final ClusterMember member;
  final String pengajuanId;
  const AdminPenentuanSeleksiScreen({super.key, required this.member, required this.pengajuanId});

  @override
  ConsumerState<AdminPenentuanSeleksiScreen> createState() =>
      _AdminPenentuanSeleksiScreenState();
}

class _AdminPenentuanSeleksiScreenState
    extends ConsumerState<AdminPenentuanSeleksiScreen> {
  String? _selectedStatus;
  final _catatanController = TextEditingController();
  final _uktController = TextEditingController();
  double _simulatedUkt = 0;

  Color _getCategoryColor(String kategori) {
    switch (kategori.toLowerCase()) {
      case 'bawah':
      case 'rendah':
      case 'prioritas':
      case 'prioritas tinggi':
        return AppColors.success; // Prioritas means they get the help (Green) - wait, maybe? Let's check context. Usually Priority=Green (Good to give), Non-Priority=Red (Don't give)
      case 'menengah':
      case 'prioritas sedang':
        return AppColors.warning;
      case 'atas':
      case 'tinggi':
      case 'tidak prioritas':
      case 'prioritas rendah':
      case 'prioritas rendah':
      case 'cukup mampu':
        return AppColors.error; // Red because they shouldn't get help
      default:
        return AppColors.primary;
    }
  }

  double _getDiscountPercentage(String kategori) {
    switch (kategori.toLowerCase()) {
      case 'bawah':
      case 'rendah':
      case 'prioritas':
      case 'prioritas tinggi':
      case 'sangat membutuhkan':
        return 0.75; // 75%
      case 'menengah':
      case 'prioritas sedang':
      case 'membutuhkan':
        return 0.50; // 50%
      case 'atas':
      case 'tinggi':
      case 'tidak prioritas':
      case 'prioritas rendah':
      case 'cukup mampu':
        return 0.0; // 0%
      default:
        return 0.0;
    }
  }

  String _formatCurrency(double? amount) {
    if (amount == null) return 'Rp 0';
    final formatter = NumberFormat.currency(
        locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return formatter.format(amount);
  }

  String _getGolonganUkt(double? amount) {
    if (amount == null) return '-';
    if (amount >= 1000000 && amount <= 1500000) return 'Golongan 1';
    if (amount >= 2000000 && amount <= 2500000) return 'Golongan 2';
    if (amount >= 3000000 && amount <= 3500000) return 'Golongan 3';
    if (amount >= 4000000 && amount <= 4500000) return 'Golongan 4';
    if (amount >= 5000000 && amount <= 5500000) return 'Golongan 5';
    if (amount >= 6000000) return 'Golongan 6';
    return '-';
  }

  @override
  void dispose() {
    _catatanController.dispose();
    _uktController.dispose();
    super.dispose();
  }

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.member.uktAwal != null && widget.member.uktAwal! > 0) {
      _simulatedUkt = widget.member.uktAwal!;
      _uktController.text = _simulatedUkt.toInt().toString();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final seleksiAsync = ref.read(seleksiListProvider(const {'page': 1, 'per_page': 100}));
      final seleksiList = seleksiAsync.when(
        data: (data) => (data['items'] as List?) ?? [],
        loading: () => [],
        error: (_, __) => [],
      );
      final seleksiDataRaw = seleksiList.where((s) => s['pengajuan_id'] == widget.pengajuanId).toList();
      if (seleksiDataRaw.isNotEmpty) {
        final seleksiData = seleksiDataRaw.first;
        final existingKelayakan = seleksiData['kelayakan'] as String?;
        if (existingKelayakan == 'LAYAK') _selectedStatus = 'Diterima';
        else if (existingKelayakan == 'TIDAK_LAYAK') _selectedStatus = 'Ditolak';
        else if (existingKelayakan == 'DIPERTIMBANGKAN') _selectedStatus = 'Dipertimbangkan';

        final existingCatatan = seleksiData['keterangan'] as String?;
        if (existingCatatan != null) {
          _catatanController.text = existingCatatan;
        }
        if (mounted) setState(() {});
      }
    });
  }

  Future<void> _saveKeputusan() async {
    if (_selectedStatus == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih status keputusan terlebih dahulu')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final dio = DioClient.instance;
      String kelayakan = '';
      if (_selectedStatus == 'Diterima') {
        kelayakan = 'LAYAK';
      } else if (_selectedStatus == 'Ditolak') {
        kelayakan = 'TIDAK_LAYAK';
      } else {
        kelayakan = 'DIPERTIMBANGKAN';
      }

      final Map<String, dynamic> payload = {
        'kelayakan': kelayakan,
        'keterangan': _catatanController.text,
      };

      if (kelayakan == 'LAYAK' && _simulatedUkt > 0) {
        final percentage = _getDiscountPercentage(widget.member.kmeansKategori);
        final uktAkhir = _simulatedUkt - (_simulatedUkt * percentage);
        payload['ukt_penurunan'] = uktAkhir;
      }

      await dio.post(
        AppEndpoints.seleksiCreate(widget.pengajuanId),
        data: payload,
      );

      // Invalidate providers
      ref.invalidate(seleksiListProvider);
      ref.invalidate(allPengajuanProvider);

      if (mounted) {
        try {
          final player = AudioPlayer();
          player.play(AssetSource('sounds/notification.mp3'));
        } catch (e) {
          print('Error playing audio: $e');
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Keputusan untuk ${widget.member.mahasiswaNama} disimpan!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final catColor = _getCategoryColor(widget.member.kmeansKategori);

    final seleksiAsync = ref.watch(seleksiListProvider(const {'page': 1, 'per_page': 100}));
    final seleksiList = seleksiAsync.when(
      data: (data) => (data['items'] as List?) ?? [],
      loading: () => [],
      error: (_, __) => [],
    );
    final seleksiDataRaw = seleksiList.where((s) => s['pengajuan_id'] == widget.pengajuanId).toList();
    final existingKelayakan = seleksiDataRaw.isNotEmpty ? seleksiDataRaw.first['kelayakan'] as String? : null;

    final isReadOnly = existingKelayakan == 'LAYAK' || existingKelayakan == 'TIDAK_LAYAK';
    final isDipertimbangkan = existingKelayakan == 'DIPERTIMBANGKAN';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Penentuan Hasil Seleksi'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tinjau data pelamar dan tentukan status akhir berdasarkan hasil clustering dan analisis finansial.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.grey[400] : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 24),

            // Detail Pelamar
            _buildSectionTitle('Detail Pelamar', Icons.person_outline),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.outline),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Text(
                      widget.member.mahasiswaNama.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.member.mahasiswaNama,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'NIM: ${widget.member.mahasiswaNim}',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Program Studi: Teknik Informatika', // Fallback or could be dynamic if we have it
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Data Finansial Diverifikasi
            _buildSectionTitle('Data Finansial Diverifikasi', Icons.account_balance_wallet_outlined),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = (constraints.maxWidth - 12) / 2;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: itemWidth,
                      child: _buildInfoBox(
                        'Nominal UKT Awal',
                        '${_getGolonganUkt(widget.member.uktAwal)}\n${_formatCurrency(widget.member.uktAwal)}',
                        Icons.account_balance,
                        AppColors.secondary,
                        theme,
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _buildInfoBox(
                        'Pendapatan Orang Tua',
                        _formatCurrency(widget.member.pendapatanOrangTua),
                        Icons.attach_money,
                        AppColors.primary,
                        theme,
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _buildInfoBox(
                        'Jumlah Tanggungan',
                        '${widget.member.jumlahTanggungan ?? 0} Orang',
                        Icons.people_outline,
                        AppColors.secondary,
                        theme,
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _buildInfoBox(
                        'Pengeluaran Bulanan',
                        _formatCurrency(widget.member.pengeluaranBulanan),
                        Icons.receipt_long,
                        AppColors.warning,
                        theme,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // Hasil Analisis Sistem
            _buildSectionTitle('Hasil Analisis Sistem', Icons.analytics_outlined),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: catColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: catColor.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: catColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.lightbulb_outline, color: catColor),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Rekomendasi Kelompok (K-Means)',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            RichText(
                              text: TextSpan(
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                children: [
                                  TextSpan(text: 'Cluster ${widget.member.kmeansCluster}: '),
                                  TextSpan(
                                    text: widget.member.kmeansKategori.toUpperCase(),
                                    style: TextStyle(color: catColor),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  // Kalkulator Simulasi UKT
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Simulasi Potongan UKT',
                              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _uktController,
                              keyboardType: TextInputType.number,
                              onChanged: (val) {
                                setState(() {
                                  _simulatedUkt = double.tryParse(val.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                                });
                              },
                              decoration: InputDecoration(
                                hintText: 'Masukkan Nominal UKT (Misal: 5000000)',
                                prefixText: 'Rp ',
                                isDense: true,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: catColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Potongan (${(_getDiscountPercentage(widget.member.kmeansKategori) * 100).toInt()}%):',
                                style: theme.textTheme.bodySmall?.copyWith(color: catColor),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatCurrency(_simulatedUkt * _getDiscountPercentage(widget.member.kmeansKategori)),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: catColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_simulatedUkt > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'UKT Akhir: ',
                          style: theme.textTheme.bodySmall,
                        ),
                        Text(
                          _formatCurrency(_simulatedUkt - (_simulatedUkt * _getDiscountPercentage(widget.member.kmeansKategori))),
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Form Keputusan
            _buildSectionTitle('Form Keputusan', Icons.gavel_outlined),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.outline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Status Akhir',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Column(
                    children: [
                      _buildRadioOption('Diterima', AppColors.success, disabled: isReadOnly),
                      _buildRadioOption('Dipertimbangkan', AppColors.warning, disabled: isReadOnly || isDipertimbangkan),
                      _buildRadioOption('Ditolak', AppColors.error, disabled: isReadOnly),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Catatan (Opsional)',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _catatanController,
                    maxLines: 3,
                    enabled: !isReadOnly,
                    decoration: InputDecoration(
                      hintText: 'Tambahkan catatan evaluasi...',
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.outline),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.outline),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.outline.withOpacity(0.5)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: (_isLoading || isReadOnly) ? null : _saveKeputusan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading 
                      ? const SizedBox(
                          height: 20, 
                          width: 20, 
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        )
                      : const Text(
                          'Simpan Hasil Seleksi',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBox(String label, String value, IconData icon, Color color, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRadioOption(String value, Color activeColor, {bool disabled = false}) {
    return RadioListTile<String>(
      title: Text(
        value,
        style: TextStyle(fontSize: 14, color: disabled ? Colors.grey : null),
      ),
      value: value,
      groupValue: _selectedStatus,
      activeColor: activeColor,
      contentPadding: EdgeInsets.zero,
      dense: true,
      onChanged: disabled
          ? null
          : (val) {
              setState(() {
                _selectedStatus = val;
              });
            },
    );
  }
}
