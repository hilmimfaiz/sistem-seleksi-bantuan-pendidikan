import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/mahasiswa_model.dart';
import '../../../../providers/app_providers.dart';
import '../../../../shared/widgets/app_widgets.dart';

class EditMahasiswaDialog extends ConsumerStatefulWidget {
  final MahasiswaModel mahasiswa;
  
  const EditMahasiswaDialog({super.key, required this.mahasiswa});

  @override
  ConsumerState<EditMahasiswaDialog> createState() =>
      _EditMahasiswaDialogState();
}

class _EditMahasiswaDialogState extends ConsumerState<EditMahasiswaDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nimCtrl;
  late TextEditingController _namaCtrl;
  late TextEditingController _prodiCtrl;
  late TextEditingController _fakultasCtrl;
  late TextEditingController _angkatanCtrl;
  late TextEditingController _alamatCtrl;
  late TextEditingController _hpCtrl;
  
  late String _jenisKelamin;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final m = widget.mahasiswa;
    _nimCtrl = TextEditingController(text: m.nim);
    _namaCtrl = TextEditingController(text: m.nama);
    _prodiCtrl = TextEditingController(text: m.programStudi);
    _fakultasCtrl = TextEditingController(text: m.fakultas);
    _angkatanCtrl = TextEditingController(text: m.angkatan.toString());
    _alamatCtrl = TextEditingController(text: m.alamat);
    _hpCtrl = TextEditingController(text: m.nomorHp);
    _jenisKelamin = m.jenisKelamin;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final data = {
        'nim': _nimCtrl.text.trim(),
        'nama': _namaCtrl.text.trim(),
        'program_studi': _prodiCtrl.text.trim(),
        'fakultas': _fakultasCtrl.text.trim(),
        'angkatan': int.parse(_angkatanCtrl.text),
        'jenis_kelamin': _jenisKelamin,
        'alamat': _alamatCtrl.text.trim(),
        'nomor_hp': _hpCtrl.text.trim(),
      };

      await ref.read(mahasiswaRepositoryProvider).updateMahasiswa(widget.mahasiswa.id, data);
      
      if (mounted) {
        Navigator.pop(context, true); // Return true indicating success
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Edit Mahasiswa',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 32),
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profil Section
                      Text('Profil Mahasiswa', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              controller: _nimCtrl,
                              label: 'NIM',
                              prefixIcon: Icons.badge_rounded,
                              validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppTextField(
                              controller: _angkatanCtrl,
                              label: 'Angkatan',
                              prefixIcon: Icons.date_range_rounded,
                              keyboardType: TextInputType.number,
                              validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: _namaCtrl,
                        label: 'Nama Lengkap',
                        prefixIcon: Icons.person_rounded,
                        validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              controller: _fakultasCtrl,
                              label: 'Fakultas',
                              prefixIcon: Icons.domain_rounded,
                              validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppTextField(
                              controller: _prodiCtrl,
                              label: 'Program Studi',
                              prefixIcon: Icons.school_rounded,
                              validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardTheme.color,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.outlineVariant),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.wc_rounded, color: AppColors.textTertiary),
                            const SizedBox(width: 12),
                            const Text('Jenis Kelamin'),
                            const Spacer(),
                            DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _jenisKelamin,
                                items: const [
                                  DropdownMenuItem(value: 'LAKI_LAKI', child: Text('Laki-laki')),
                                  DropdownMenuItem(value: 'PEREMPUAN', child: Text('Perempuan')),
                                ],
                                onChanged: (v) {
                                  if (v != null) setState(() => _jenisKelamin = v);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: _hpCtrl,
                        label: 'Nomor HP',
                        prefixIcon: Icons.phone_rounded,
                        keyboardType: TextInputType.phone,
                        validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: _alamatCtrl,
                        label: 'Alamat',
                        prefixIcon: Icons.location_on_rounded,
                        maxLines: 3,
                        validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Simpan Perubahan',
              isLoading: _isLoading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
