import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../providers/app_providers.dart';
import '../../../shared/widgets/app_widgets.dart';

class VerifikasiScreen extends ConsumerStatefulWidget {
  const VerifikasiScreen({super.key});

  @override
  ConsumerState<VerifikasiScreen> createState() => _VerifikasiScreenState();
}

class _VerifikasiScreenState extends ConsumerState<VerifikasiScreen> {
  String _searchQuery = '';
  String _selectedDateFilter = 'Tampilkan semua';
  int _currentPage = 1;
  final int _itemsPerPage = 10;

  Future<void> _showActionDialog(
    BuildContext context,
    String pengajuanId,
    String mahasiswaNama,
    String action,
  ) async {
    final catatanCtrl = TextEditingController();
    bool isLoading = false;

    Color actionColor;
    String actionLabel;
    IconData actionIcon;

    switch (action) {
      case 'approve':
        actionColor = AppColors.success;
        actionLabel = 'Verifikasi';
        actionIcon = Icons.check_circle_rounded;
        break;
      case 'reject':
        actionColor = AppColors.error;
        actionLabel = 'Tolak';
        actionIcon = Icons.cancel_rounded;
        break;
      case 'revise':
        actionColor = AppColors.warning;
        actionLabel = 'Minta Revisi';
        actionIcon = Icons.edit_note_rounded;
        break;
      default:
        return;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: actionColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(actionIcon, color: actionColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$actionLabel Pengajuan',
                          style: Theme.of(context).textTheme.titleMedium),
                      Text(mahasiswaNama,
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              AppTextField(
                label: 'Catatan (opsional)',
                hint: action == 'approve'
                    ? 'Tambahkan catatan untuk mahasiswa...'
                    : action == 'reject'
                        ? 'Alasan penolakan...'
                        : 'Dokumen yang perlu direvisi...',
                controller: catatanCtrl,
                maxLines: 3,
                prefixIcon: Icons.note_outlined,
              ),
              const SizedBox(height: 20),
              AppButton(
                label: '$actionLabel Pengajuan',
                onPressed: isLoading
                    ? null
                    : () async {
                        setModalState(() => isLoading = true);
                        try {
                          final repo = ref.read(pengajuanRepositoryProvider);
                          switch (action) {
                            case 'approve':
                              await repo.approve(pengajuanId,
                                  catatan: catatanCtrl.text);
                              break;
                            case 'reject':
                              await repo.reject(pengajuanId,
                                  catatan: catatanCtrl.text);
                              break;
                            case 'revise':
                              await repo.revise(pengajuanId,
                                  catatan: catatanCtrl.text);
                              break;
                          }
                          ref.invalidate(verifikasiListProvider);
                          ref.invalidate(allPengajuanProvider);
                          ref.invalidate(adminStatsProvider);
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Pengajuan berhasil di-$action!'),
                                backgroundColor: actionColor,
                              ),
                            );
                          }
                        } catch (e) {
                          setModalState(() => isLoading = false);
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: Text(e.toString()),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        }
                      },
                isLoading: isLoading,
                color: actionColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetailDialog(BuildContext context, dynamic p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Detail Pengajuan', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Nama: ${p.mahasiswaNama ?? '-'}', style: const TextStyle(fontWeight: FontWeight.w600)),
              Text('NIM: ${p.mahasiswaNim ?? '-'}'),
              const SizedBox(height: 12),
              Text('Bantuan: ${p.bantuanNama ?? '-'}'),
              Text('Status: ${p.status}'),
              Text('Diajukan pada: ${p.createdAt.length >= 10 ? p.createdAt.substring(0, 10) : p.createdAt}'),
              if (p.catatan != null && p.catatan!.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Catatan:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(p.catatan!),
              ],
              const SizedBox(height: 16),
              const Text('Dokumen Pendukung:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (p.dokumenPaths.isEmpty || (p.dokumenPaths.length == 1 && p.dokumenPaths[0] == 'null'))
                const Text('Tidak ada dokumen terlampir.', style: TextStyle(fontStyle: FontStyle.italic))
              else
                ...p.dokumenPaths.map((path) {
                  final filename = path.split('/').last.split('\\').last;
                  final fullUrl = '${AppEndpoints.baseUrl}/${path.replaceAll(r'\', '/')}';
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: InkWell(
                      onTap: () async {
                        final uri = Uri.parse(fullUrl);
                        try {
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          } else {
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(content: Text('Tidak dapat membuka dokumen')),
                              );
                            }
                          }
                        } catch (e) {
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      },
                      child: Row(
                        children: [
                          const Icon(Icons.file_download_rounded, size: 20, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              filename,
                              style: const TextStyle(color: AppColors.primary, decoration: TextDecoration.underline),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final verifikasiAsync = ref.watch(verifikasiListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verifikasi Pengajuan'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(verifikasiListProvider),
        child: verifikasiAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(20),
            child: ShimmerList(count: 5),
          ),
          error: (e, _) => ErrorState(
            message: e.toString(),
            onRetry: () => ref.invalidate(verifikasiListProvider),
          ),
          data: (pengajuan) {
            final dateSet = <String>{};
            for (var p in pengajuan) {
              if (p.createdAt.length >= 10) {
                final dateStr = p.createdAt.substring(0, 10);
                final parts = dateStr.split('-');
                if (parts.length == 3) {
                  dateSet.add('${parts[2]}-${parts[1]}-${parts[0]}');
                }
              }
            }
            final availableDates = ['Tampilkan semua', ...dateSet.toList()..sort((a,b) => b.compareTo(a))];

            var filteredList = pengajuan;

            if (_selectedDateFilter != 'Tampilkan semua') {
               filteredList = filteredList.where((p) {
                 if (p.createdAt.length >= 10) {
                   final dateStr = p.createdAt.substring(0, 10);
                   final parts = dateStr.split('-');
                   if (parts.length == 3) {
                     final formatted = '${parts[2]}-${parts[1]}-${parts[0]}';
                     return formatted == _selectedDateFilter;
                   }
                 }
                 return false;
               }).toList();
            }

            if (_searchQuery.isNotEmpty) {
               final query = _searchQuery.toLowerCase();
               filteredList = filteredList.where((p) {
                  final nama = (p.mahasiswaNama ?? '').toLowerCase();
                  final nim = (p.mahasiswaNim ?? '').toLowerCase();
                  return nama.contains(query) || nim.contains(query);
               }).toList();
            }

            final totalItems = filteredList.length;
            final totalPages = (totalItems / _itemsPerPage).ceil();

            if (_currentPage > totalPages && totalPages > 0) {
              _currentPage = totalPages;
            } else if (_currentPage < 1) {
              _currentPage = 1;
            }

            final startIndex = (_currentPage - 1) * _itemsPerPage;
            final endIndex = (startIndex + _itemsPerPage > totalItems) ? totalItems : startIndex + _itemsPerPage;

            final paginatedList = startIndex < totalItems ? filteredList.sublist(startIndex, endIndex) : [];

            Widget content;
            if (filteredList.isEmpty) {
              content = const EmptyState(
                title: 'Tidak Ada Pengajuan',
                subtitle: 'Belum ada pengajuan atau tidak ada yang cocok dengan pencarian',
                icon: Icons.verified_rounded,
              );
            } else {
              content = ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: paginatedList.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final p = paginatedList[i];
                return InkWell(
                  onTap: () => _showDetailDialog(context, p),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
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
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.person_rounded,
                                color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.mahasiswaNama ?? 'Mahasiswa',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                Text(
                                  'NIM: ${p.mahasiswaNim ?? '-'}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          StatusBadge(status: p.status),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        p.bantuanNama ?? 'Bantuan Pendidikan',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      Text(
                        'Diajukan: ${p.createdAt.substring(0, 10)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (p.dokumenPaths.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          '📎 ${p.dokumenPaths.length} Dokumen',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              label: 'Tolak',
                              onPressed: () => _showActionDialog(
                                  context,
                                  p.id,
                                  p.mahasiswaNama ?? '',
                                  'reject'),
                              isOutlined: true,
                              color: AppColors.error,
                              icon: Icons.close_rounded,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: AppButton(
                              label: 'Revisi',
                              onPressed: () => _showActionDialog(
                                  context,
                                  p.id,
                                  p.mahasiswaNama ?? '',
                                  'revise'),
                              isOutlined: true,
                              color: AppColors.warning,
                              icon: Icons.edit_note_rounded,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: AppButton(
                              label: 'Verif.',
                              onPressed: () => _showActionDialog(
                                  context,
                                  p.id,
                                  p.mahasiswaNama ?? '',
                                  'approve'),
                              color: AppColors.success,
                              icon: Icons.check_rounded,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                );
              },
            );
            }

            final isDark = Theme.of(context).brightness == Brightness.dark;
            
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Cari nama atau NIM...',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: isDark ? AppColors.darkSurface : Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                            _currentPage = 1;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          const Text('Tanggal Masuk:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: availableDates.contains(_selectedDateFilter) ? _selectedDateFilter : 'Tampilkan semua',
                              items: availableDates.map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 13)))).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedDateFilter = val;
                                    _currentPage = 1;
                                  });
                                }
                              },
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: isDark ? AppColors.darkSurface : Colors.white,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: isDark ? AppColors.darkOutline : Colors.grey.shade300),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: isDark ? AppColors.darkOutline : Colors.grey.shade300),
                                ),
                              ),
                              icon: const Icon(Icons.arrow_drop_down_rounded),
                              isExpanded: true,
                            )
                          )
                        ]
                      )
                    ]
                  )
                ),
                Expanded(child: content),
                if (totalPages > 1) ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
                      ),
                      Text('Halaman $_currentPage dari $totalPages', style: Theme.of(context).textTheme.bodySmall),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: _currentPage < totalPages ? () => setState(() => _currentPage++) : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
