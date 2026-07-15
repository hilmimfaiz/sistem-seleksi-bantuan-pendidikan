import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/app_models.dart';
import '../../../providers/app_providers.dart';
import '../../../shared/widgets/app_widgets.dart';

class PengajuanBaruScreen extends ConsumerStatefulWidget {
  const PengajuanBaruScreen({super.key});

  @override
  ConsumerState<PengajuanBaruScreen> createState() => _PengajuanBaruScreenState();
}

class _PengajuanBaruScreenState extends ConsumerState<PengajuanBaruScreen> {
  String? _selectedBantuanId;
  BantuanModel? _selectedBantuan;
  List<File> _selectedFiles = [];
  bool _isLoading = false;
  String? _pengajuanId;

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      allowMultiple: true,
    );
    if (result != null) {
      setState(() {
        final newFiles = result.paths
            .where((p) => p != null)
            .map((p) => File(p!))
            .toList();
        
        // Hanya tambahkan file yang belum ada (berdasarkan path)
        for (var file in newFiles) {
          if (!_selectedFiles.any((f) => f.path == file.path)) {
            _selectedFiles.add(file);
          }
        }
      });
    }
  }

  Future<void> _submit() async {
    if (_selectedBantuanId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih bantuan terlebih dahulu'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(pengajuanRepositoryProvider);

      // Buat pengajuan
      final pengajuan = await repo.create(_selectedBantuanId!);
      setState(() => _pengajuanId = pengajuan.id);

      // Upload dokumen jika ada
      if (_selectedFiles.isNotEmpty) {
        await repo.uploadDokumen(pengajuan.id, _selectedFiles);
      }

      ref.invalidate(myPengajuanProvider);

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            icon: Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: AppColors.successContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 32,
              ),
            ),
            title: const Text('Pengajuan Berhasil!'),
            content: const Text(
              'Pengajuan bantuan Anda telah berhasil disubmit. Tim kami akan memverifikasi dokumen Anda.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Back to list
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
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
    final bantuanAsync = ref.watch(bantuanListProvider(const {'status': 'AKTIF'}));

    return Scaffold(
      appBar: AppBar(title: const Text('Ajukan Bantuan')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pilih Bantuan
            Text('Pilih Program Bantuan', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),

            bantuanAsync.when(
              loading: () => const ShimmerList(count: 3),
              error: (e, _) => ErrorState(message: e.toString()),
              data: (data) {
                final bantuanList = data['items'] as List<BantuanModel>;
                
                if (bantuanList.isEmpty) {
                  return const EmptyState(
                    title: 'Tidak Ada Bantuan Tersedia',
                    subtitle: 'Belum ada program bantuan yang aktif saat ini',
                  );
                }

                return Column(
                  children: bantuanList.map((bantuan) {
                    final isSelected = _selectedBantuanId == bantuan.id;
                    return InkWell(
                      onTap: () => setState(() {
                        _selectedBantuanId = bantuan.id;
                        _selectedBantuan = bantuan;
                      }),
                      borderRadius: BorderRadius.circular(16),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primaryContainer
                              : Theme.of(context).cardTheme.color,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.outline,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.surfaceVariant,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isSelected
                                    ? Icons.check_rounded
                                    : Icons.school_outlined,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textTertiary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    bantuan.nama,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          color: isSelected
                                              ? AppColors.primary
                                              : null,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Kuota: ${bantuan.kuota}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            if (_selectedBantuan != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Persyaratan:', style: Theme.of(context).textTheme.labelMedium),
                    const SizedBox(height: 6),
                    Text(
                      _selectedBantuan!.persyaratan,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Upload Dokumen
            Text('Upload Dokumen Pendukung', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Format: PDF, JPG, PNG (maks. 10MB)',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),

            if (_selectedFiles.isEmpty)
              InkWell(
                onTap: _pickFiles,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.5),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    color: AppColors.primaryContainer.withOpacity(0.3),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.upload_file_rounded, size: 40, color: AppColors.primary),
                      SizedBox(height: 8),
                      Text(
                        'Tap untuk memilih file',
                        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: [
                  ..._selectedFiles.map((f) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      border: Border.all(color: AppColors.outline),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.file_present_rounded, color: AppColors.primary, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            f.path.split('/').last.split('\\').last,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppColors.error, size: 20),
                          onPressed: () {
                            setState(() {
                              _selectedFiles.remove(f);
                            });
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  )),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _pickFiles,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Tambah Berkas Lain'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 32),
            AppButton(
              label: 'Submit Pengajuan',
              onPressed: _isLoading ? null : _submit,
              isLoading: _isLoading,
              icon: Icons.send_rounded,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}jt';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}rb';
    return value.toStringAsFixed(0);
  }
}
