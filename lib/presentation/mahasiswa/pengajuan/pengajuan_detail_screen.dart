import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/app_models.dart';
import '../../../providers/app_providers.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../core/constants/api_endpoints.dart';

class PengajuanDetailScreen extends ConsumerStatefulWidget {
  final PengajuanModel pengajuan;
  const PengajuanDetailScreen({super.key, required this.pengajuan});

  @override
  ConsumerState<PengajuanDetailScreen> createState() => _PengajuanDetailScreenState();
}

class _PengajuanDetailScreenState extends ConsumerState<PengajuanDetailScreen> {
  bool _isUploading = false;

  Future<void> _uploadFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() => _isUploading = true);
      try {
        final files = result.files.map((f) => File(f.path!)).toList();
        await ref.read(pengajuanRepositoryProvider).uploadDokumen(widget.pengajuan.id, files);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Dokumen berhasil diunggah'), backgroundColor: AppColors.success),
          );
          ref.invalidate(myPengajuanProvider);
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal mengunggah dokumen: $e'), backgroundColor: AppColors.error),
          );
        }
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pengajuanList = ref.watch(myPengajuanProvider).value ?? [];
    final p = pengajuanList.firstWhere(
      (element) => element.id == widget.pengajuan.id,
      orElse: () => widget.pengajuan,
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Pengajuan')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Header
            Center(
              child: Column(
                children: [
                  StatusBadge(status: p.status),
                  const SizedBox(height: 12),
                  Text(
                    p.bantuanNama ?? 'Bantuan Pendidikan',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Diajukan pada ${p.createdAt.substring(0, 10)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            if (p.catatan != null && p.catatan!.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.warningContainer.withOpacity(isDark ? 0.2 : 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.warning.withOpacity(0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 20),
                        SizedBox(width: 8),
                        Text('Catatan Admin', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.warning)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(p.catatan!, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Hasil Seleksi Section
            if (p.status == 'SELEKSI' || p.status == 'DITERIMA' || p.status == 'TIDAK_DITERIMA') ...[
              Text('Hasil Seleksi', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Consumer(
                builder: (context, ref, child) {
                  final seleksiAsync = ref.watch(mySeleksiProvider);
                  return seleksiAsync.when(
                    loading: () => const ShimmerCard(),
                    error: (e, _) => Text('Gagal memuat hasil: $e'),
                    data: (seleksi) {
                      final hasil = seleksi.where((s) => s['pengajuan_id'] == p.id).toList();
                      
                      if (hasil.isEmpty && p.status == 'SELEKSI') {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.analytics_rounded, color: AppColors.textTertiary),
                              SizedBox(width: 12),
                              Expanded(child: Text('Sedang dalam tahap seleksi (clustering). Harap tunggu proses selesai.')),
                            ],
                          ),
                        );
                      }

                      if (hasil.isEmpty) return const SizedBox();

                      final myHasil = hasil.first;
                      final isLayak = myHasil['kelayakan'] == 'LAYAK';
                      
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: isLayak ? AppColors.successGradient : null,
                          color: isLayak ? null : AppColors.errorContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Icon(isLayak ? Icons.celebration_rounded : Icons.cancel_rounded, 
                                 color: isLayak ? Colors.white : AppColors.error, size: 32),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isLayak ? '🎉 Selamat! Anda Diterima' : 'Maaf, Anda Belum Memenuhi Kriteria',
                                    style: TextStyle(
                                      color: isLayak ? Colors.white : AppColors.error,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                    Text(
                                      (myHasil['keterangan'] == null || myHasil['keterangan'].toString().trim().isEmpty)
                                          ? (isLayak ? 'Anda dinyatakan layak menerima bantuan.' : 'Coba lagi di periode berikutnya.')
                                          : myHasil['keterangan'].toString(),
                                      style: TextStyle(
                                        color: isLayak ? Colors.white.withOpacity(0.9) : AppColors.error.withOpacity(0.8),
                                        fontSize: 13,
                                      ),
                                    ),
                                    if (isLayak && p.uktAkhir != null && p.uktAkhir! > 0) ...[
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'UKT Awal: ${NumberFormat.currency(locale: 'id', symbol: 'Rp', decimalDigits: 0).format(p.uktAwal ?? 0)}',
                                              style: const TextStyle(color: Colors.white, fontSize: 12),
                                            ),
                                            Text(
                                              'UKT Setelah Penurunan: ${NumberFormat.currency(locale: 'id', symbol: 'Rp', decimalDigits: 0).format(p.uktAkhir)}',
                                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 24),
            ],

            Text('Dokumen Terlampir', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            
            if (p.dokumenPaths.isEmpty)
              const Text('Belum ada dokumen yang diunggah', style: TextStyle(color: AppColors.textTertiary, fontStyle: FontStyle.italic))
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: p.dokumenPaths.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, i) {
                  final path = p.dokumenPaths[i];
                  final fileName = path.split('/').last;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceVariant : Colors.white,
                      border: Border.all(color: AppColors.outline),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.picture_as_pdf_rounded, color: AppColors.error),
                        const SizedBox(width: 12),
                        Expanded(child: Text(fileName, maxLines: 1, overflow: TextOverflow.ellipsis)),
                        IconButton(
                          icon: const Icon(Icons.download_rounded, color: AppColors.primary),
                          onPressed: () {
                            // In real app, download file
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),

            if (p.canUpload) ...[
              const SizedBox(height: 32),
              AppButton(
                label: 'Upload Ulang Dokumen',
                onPressed: _uploadFiles,
                isLoading: _isUploading,
                icon: Icons.upload_file_rounded,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
