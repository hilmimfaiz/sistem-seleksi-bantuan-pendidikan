import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/app_providers.dart';
import '../../../shared/widgets/app_widgets.dart';

class FinansialEditScreen extends ConsumerStatefulWidget {
  const FinansialEditScreen({super.key});

  @override
  ConsumerState<FinansialEditScreen> createState() => _FinansialEditScreenState();
}

class _FinansialEditScreenState extends ConsumerState<FinansialEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pendapatanCtrl = TextEditingController();
  final _tanggunganCtrl = TextEditingController();
  final _pengeluaranCtrl = TextEditingController();
  final _uangSakuCtrl = TextEditingController();

  int _literasiKeuangan = 5;
  int _gayaHidup = 5;
  bool _isLoading = false;
  bool _isEdit = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final finansial = await ref.read(finansialRepositoryProvider).getMyFinansial();
    if (finansial != null && mounted) {
      setState(() {
        _isEdit = true;
        _pendapatanCtrl.text = finansial.pendapatanOrangTua.toStringAsFixed(0);
        _tanggunganCtrl.text = finansial.jumlahTanggungan.toString();
        _pengeluaranCtrl.text = finansial.pengeluaranBulanan.toStringAsFixed(0);
        _uangSakuCtrl.text = finansial.uangSaku.toStringAsFixed(0);
        _literasiKeuangan = finansial.literasiKeuangan;
        _gayaHidup = finansial.gayaHidup;
      });
    }
  }

  @override
  void dispose() {
    _pendapatanCtrl.dispose();
    _tanggunganCtrl.dispose();
    _pengeluaranCtrl.dispose();
    _uangSakuCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final data = {
        'pendapatan_orang_tua': double.parse(_pendapatanCtrl.text.trim()),
        'jumlah_tanggungan': int.parse(_tanggunganCtrl.text.trim()),
        'pengeluaran_bulanan': double.parse(_pengeluaranCtrl.text.trim()),
        'uang_saku': double.parse(_uangSakuCtrl.text.trim()),
        'literasi_keuangan': _literasiKeuangan,
        'gaya_hidup': _gayaHidup,
      };

      final repo = ref.read(finansialRepositoryProvider);
      if (_isEdit) {
        await repo.updateFinansial(data);
      } else {
        await repo.createFinansial(data);
      }

      ref.invalidate(myFinansialProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data finansial berhasil disimpan ✓'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Data Finansial' : 'Isi Data Finansial'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Data finansial digunakan untuk pengelompokan kemampuan dalam seleksi bantuan pendidikan',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Text('Informasi Pendapatan', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 12),

              AppTextField(
                label: 'Pendapatan Orang Tua (Rp/bulan)',
                hint: '2000000',
                controller: _pendapatanCtrl,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.attach_money_rounded,
                validator: (v) {
                  if (v?.isEmpty == true) return 'Pendapatan tidak boleh kosong';
                  if (double.tryParse(v!) == null) return 'Format angka tidak valid';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Jumlah Tanggungan Keluarga',
                hint: '4',
                controller: _tanggunganCtrl,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.family_restroom_rounded,
                validator: (v) {
                  if (v?.isEmpty == true) return 'Jumlah tanggungan tidak boleh kosong';
                  final n = int.tryParse(v!);
                  if (n == null || n < 0 || n > 20) return 'Antara 0-20';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Pengeluaran Bulanan (Rp)',
                hint: '1500000',
                controller: _pengeluaranCtrl,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.shopping_bag_outlined,
                validator: (v) {
                  if (v?.isEmpty == true) return 'Pengeluaran tidak boleh kosong';
                  if (double.tryParse(v!) == null) return 'Format angka tidak valid';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Uang Saku Per Bulan (Rp)',
                hint: '500000',
                controller: _uangSakuCtrl,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.wallet_outlined,
                validator: (v) {
                  if (v?.isEmpty == true) return 'Uang saku tidak boleh kosong';
                  if (double.tryParse(v!) == null) return 'Format angka tidak valid';
                  return null;
                },
              ),

              const SizedBox(height: 24),
              Text('Penilaian Diri', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 16),

              // Literasi Keuangan Slider
              _buildSliderField(
                context: context,
                label: 'Literasi Keuangan',
                description: 'Seberapa baik Anda memahami dan mengelola keuangan',
                value: _literasiKeuangan.toDouble(),
                min: 1,
                max: 10,
                onChanged: (v) => setState(() => _literasiKeuangan = v.round()),
                color: AppColors.primary,
                lowLabel: 'Rendah',
                highLabel: 'Tinggi',
              ),

              const SizedBox(height: 20),

              // Gaya Hidup Slider
              _buildSliderField(
                context: context,
                label: 'Gaya Hidup',
                description: 'Seberapa sederhana gaya hidup Anda (1=sangat hemat, 10=sangat boros)',
                value: _gayaHidup.toDouble(),
                min: 1,
                max: 10,
                onChanged: (v) => setState(() => _gayaHidup = v.round()),
                color: AppColors.warning,
                lowLabel: 'Sangat Hemat',
                highLabel: 'Boros',
              ),

              const SizedBox(height: 32),
              AppButton(
                label: _isEdit ? 'Simpan Perubahan' : 'Simpan Data Finansial',
                onPressed: _save,
                isLoading: _isLoading,
                icon: Icons.save_rounded,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliderField({
    required BuildContext context,
    required String label,
    required String description,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    required Color color,
    required String lowLabel,
    required String highLabel,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(label,
                    style: Theme.of(context).textTheme.titleSmall),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${value.round()}/10',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(description, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: color,
              thumbColor: color,
              overlayColor: color.withOpacity(0.2),
              inactiveTrackColor: color.withOpacity(0.2),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: (max - min).round(),
              onChanged: onChanged,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(lowLabel,
                  style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
              Text(highLabel,
                  style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
            ],
          ),
        ],
      ),
    );
  }
}
