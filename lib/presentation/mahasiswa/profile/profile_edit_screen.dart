import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/mahasiswa_model.dart';
import '../../../data/repositories/mahasiswa_repository.dart';
import '../../../providers/app_providers.dart';
import '../../../shared/widgets/app_widgets.dart';

class MahasiswaProfileEditScreen extends ConsumerStatefulWidget {
  const MahasiswaProfileEditScreen({super.key});

  @override
  ConsumerState<MahasiswaProfileEditScreen> createState() =>
      _MahasiswaProfileEditScreenState();
}

class _MahasiswaProfileEditScreenState
    extends ConsumerState<MahasiswaProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nimCtrl = TextEditingController();
  final _namaCtrl = TextEditingController();
  final _prodiCtrl = TextEditingController();
  final _fakultasCtrl = TextEditingController();
  final _angkatanCtrl = TextEditingController();
  final _alamatCtrl = TextEditingController();
  final _hpCtrl = TextEditingController();

  String _jenisKelamin = 'LAKI_LAKI';
  bool _isLoading = false;
  bool _isEdit = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final profile = await ref.read(mahasiswaRepositoryProvider).getMyProfile();
    if (profile != null && mounted) {
      setState(() {
        _isEdit = true;
        _nimCtrl.text = profile.nim;
        _namaCtrl.text = profile.nama;
        _prodiCtrl.text = profile.programStudi;
        _fakultasCtrl.text = profile.fakultas;
        _angkatanCtrl.text = profile.angkatan.toString();
        _alamatCtrl.text = profile.alamat;
        _hpCtrl.text = profile.nomorHp;
        _jenisKelamin = profile.jenisKelamin;
      });
    }
  }

  @override
  void dispose() {
    _nimCtrl.dispose();
    _namaCtrl.dispose();
    _prodiCtrl.dispose();
    _fakultasCtrl.dispose();
    _angkatanCtrl.dispose();
    _alamatCtrl.dispose();
    _hpCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final data = {
        'nim': _nimCtrl.text.trim(),
        'nama': _namaCtrl.text.trim(),
        'program_studi': _prodiCtrl.text.trim(),
        'fakultas': _fakultasCtrl.text.trim(),
        'angkatan': int.parse(_angkatanCtrl.text.trim()),
        'jenis_kelamin': _jenisKelamin,
        'alamat': _alamatCtrl.text.trim(),
        'nomor_hp': _hpCtrl.text.trim(),
      };

      final repo = ref.read(mahasiswaRepositoryProvider);
      if (_isEdit) {
        await repo.updateProfile(data);
      } else {
        await repo.createProfile(data);
      }

      ref.invalidate(myProfileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil berhasil disimpan ✓'),
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
        title: Text(_isEdit ? 'Edit Profil' : 'Lengkapi Profil'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextField(
                label: 'NIM',
                hint: '2021001',
                controller: _nimCtrl,
                prefixIcon: Icons.badge_outlined,
                validator: (v) => v?.isEmpty == true ? 'NIM tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Nama Lengkap',
                hint: 'Ahmad Fauzi',
                controller: _namaCtrl,
                prefixIcon: Icons.person_outline,
                validator: (v) => v?.isEmpty == true ? 'Nama tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Program Studi',
                hint: 'Teknik Informatika',
                controller: _prodiCtrl,
                prefixIcon: Icons.school_outlined,
                validator: (v) => v?.isEmpty == true ? 'Program studi tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Fakultas',
                hint: 'Fakultas Teknik',
                controller: _fakultasCtrl,
                prefixIcon: Icons.business_outlined,
                validator: (v) => v?.isEmpty == true ? 'Fakultas tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Angkatan',
                hint: '2021',
                controller: _angkatanCtrl,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.calendar_today_outlined,
                validator: (v) {
                  if (v?.isEmpty == true) return 'Angkatan tidak boleh kosong';
                  final year = int.tryParse(v!);
                  if (year == null || year < 2000 || year > 2030) {
                    return 'Angkatan tidak valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Jenis Kelamin
              Text(
                'Jenis Kelamin',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _jenisKelamin = 'LAKI_LAKI'),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: _jenisKelamin == 'LAKI_LAKI'
                              ? AppColors.primaryContainer
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _jenisKelamin == 'LAKI_LAKI'
                                ? AppColors.primary
                                : AppColors.outline,
                            width: _jenisKelamin == 'LAKI_LAKI' ? 2 : 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.male_rounded,
                                color: _jenisKelamin == 'LAKI_LAKI'
                                    ? AppColors.primary
                                    : AppColors.textTertiary),
                            const SizedBox(width: 6),
                            Text('Laki-laki',
                                style: TextStyle(
                                  color: _jenisKelamin == 'LAKI_LAKI'
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                )),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _jenisKelamin = 'PEREMPUAN'),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: _jenisKelamin == 'PEREMPUAN'
                              ? AppColors.primaryContainer
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _jenisKelamin == 'PEREMPUAN'
                                ? AppColors.primary
                                : AppColors.outline,
                            width: _jenisKelamin == 'PEREMPUAN' ? 2 : 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.female_rounded,
                                color: _jenisKelamin == 'PEREMPUAN'
                                    ? AppColors.primary
                                    : AppColors.textTertiary),
                            const SizedBox(width: 6),
                            Text('Perempuan',
                                style: TextStyle(
                                  color: _jenisKelamin == 'PEREMPUAN'
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                )),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              AppTextField(
                label: 'Nomor HP',
                hint: '08123456789',
                controller: _hpCtrl,
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_outlined,
                validator: (v) {
                  if (v?.isEmpty == true) return 'Nomor HP tidak boleh kosong';
                  if (!RegExp(r'^(\+62|62|0)[0-9]{9,12}$').hasMatch(v!)) {
                    return 'Format nomor HP tidak valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Alamat Lengkap',
                hint: 'Jl. Merdeka No.1, Jakarta',
                controller: _alamatCtrl,
                prefixIcon: Icons.location_on_outlined,
                maxLines: 3,
                validator: (v) => v?.isEmpty == true ? 'Alamat tidak boleh kosong' : null,
              ),
              const SizedBox(height: 28),
              AppButton(
                label: _isEdit ? 'Simpan Perubahan' : 'Simpan Profil',
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
}
