import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/mahasiswa_model.dart';
import '../../../../providers/app_providers.dart';
import '../../../../shared/widgets/app_widgets.dart';

class TambahMahasiswaDialog extends ConsumerStatefulWidget {
  const TambahMahasiswaDialog({super.key});

  @override
  ConsumerState<TambahMahasiswaDialog> createState() =>
      _TambahMahasiswaDialogState();
}

class _TambahMahasiswaDialogState extends ConsumerState<TambahMahasiswaDialog> {
  final _formKey = GlobalKey<FormState>();

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nimCtrl = TextEditingController();
  final _namaCtrl = TextEditingController();
  final _prodiCtrl = TextEditingController();
  final _fakultasCtrl = TextEditingController();
  final _angkatanCtrl = TextEditingController(text: DateTime.now().year.toString());
  final _alamatCtrl = TextEditingController();
  final _hpCtrl = TextEditingController();
  
  String _jenisKelamin = 'LAKI_LAKI'; // Laki-laki default
  double? _selectedUkt;
  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final request = MahasiswaRegisterRequest(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        nim: _nimCtrl.text.trim(),
        nama: _namaCtrl.text.trim(),
        programStudi: _prodiCtrl.text.trim(),
        fakultas: _fakultasCtrl.text.trim(),
        angkatan: int.parse(_angkatanCtrl.text),
        jenisKelamin: _jenisKelamin,
        alamat: _alamatCtrl.text.trim(),
        nomorHp: _hpCtrl.text.trim(),
        uktAwal: _selectedUkt,
      );

      await ref.read(mahasiswaRepositoryProvider).registerMahasiswa(request);
      
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
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
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
                  'Tambah Mahasiswa',
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
                      // Akun Section
                      Text('Kredensial Akun', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: _emailCtrl,
                        label: 'Email',
                        prefixIcon: Icons.email_rounded,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => (v == null || v.isEmpty) ? 'Email wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: _passwordCtrl,
                        label: 'Password',
                        prefixIcon: Icons.lock_rounded,
                        obscureText: true,
                        validator: (v) => (v == null || v.length < 6) ? 'Min 6 karakter' : null,
                      ),
                      
                      const SizedBox(height: 24),
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
                      const SizedBox(height: 12),
                      DropdownButtonFormField<double>(
                        value: _selectedUkt,
                        decoration: InputDecoration(
                          labelText: 'Golongan UKT Awal',
                          prefixIcon: const Icon(Icons.account_balance_rounded),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: AppColors.outlineVariant),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: AppColors.outlineVariant),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).cardTheme.color,
                        ),
                        items: const [
                          DropdownMenuItem(value: 1000000.0, child: Text('Golongan 1 (Rp 1.000.000)')),
                          DropdownMenuItem(value: 1500000.0, child: Text('Golongan 1 (Rp 1.500.000)')),
                          DropdownMenuItem(value: 2000000.0, child: Text('Golongan 2 (Rp 2.000.000)')),
                          DropdownMenuItem(value: 2500000.0, child: Text('Golongan 2 (Rp 2.500.000)')),
                          DropdownMenuItem(value: 3000000.0, child: Text('Golongan 3 (Rp 3.000.000)')),
                          DropdownMenuItem(value: 3500000.0, child: Text('Golongan 3 (Rp 3.500.000)')),
                          DropdownMenuItem(value: 4000000.0, child: Text('Golongan 4 (Rp 4.000.000)')),
                          DropdownMenuItem(value: 4500000.0, child: Text('Golongan 4 (Rp 4.500.000)')),
                          DropdownMenuItem(value: 5000000.0, child: Text('Golongan 5 (Rp 5.000.000)')),
                          DropdownMenuItem(value: 5500000.0, child: Text('Golongan 5 (Rp 5.500.000)')),
                          DropdownMenuItem(value: 6000000.0, child: Text('Golongan 6 (Rp 6.000.000)')),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _selectedUkt = v);
                        },
                        validator: (v) => v == null ? 'Wajib pilih Golongan UKT' : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Simpan',
              isLoading: _isLoading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
