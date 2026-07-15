import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/app_providers.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_endpoints.dart';

class AdminReportTab extends ConsumerStatefulWidget {
  const AdminReportTab({super.key});

  @override
  ConsumerState<AdminReportTab> createState() => _AdminReportTabState();
}

class _AdminReportTabState extends ConsumerState<AdminReportTab> {
  String _searchQuery = '';
  String? _selectedStatus;
  Set<String> _selectedIds = {};
  bool _isDeleting = false;

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Seleksi'),
        content: Text('Apakah Anda yakin ingin menghapus ${_selectedIds.length} data seleksi? Status pengajuannya akan dikembalikan ke tahap seleksi.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isDeleting = true);
      try {
        await DioClient.instance.delete(
          AppEndpoints.seleksiBulkDelete,
          data: {'ids': _selectedIds.toList()},
        );
        setState(() {
          _selectedIds.clear();
        });
        ref.invalidate(seleksiListProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data berhasil dihapus')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menghapus data: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isDeleting = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final seleksiAsync = ref.watch(seleksiListProvider(const {'page': 1, 'per_page': 100}));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Seleksi', style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: false,
        elevation: 0,
        actions: [
          if (_selectedIds.isNotEmpty)
            _isDeleting
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Center(
                      child: SizedBox(
                          width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.error),
                    onPressed: _deleteSelected,
                    tooltip: 'Hapus ${_selectedIds.length} Data',
                  )
        ],
      ),
      body: seleksiAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (data) {
          final items = (data['items'] as List?) ?? [];
          
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.description_outlined, size: 80, color: AppColors.primary.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text('Belum ada data laporan seleksi',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyMedium?.color ?? AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          final listDiterima = items.where((k) => k['kelayakan'] == 'LAYAK').toList();
          final listDipertimbangkan = items.where((k) => k['kelayakan'] == 'DIPERTIMBANGKAN').toList();
          final listDitolak = items.where((k) => k['kelayakan'] == 'TIDAK_LAYAK').toList();

          List filteredItems = items;
          
          if (_selectedStatus != null) {
            filteredItems = filteredItems.where((k) => k['kelayakan'] == _selectedStatus).toList();
          }
          
          if (_searchQuery.isNotEmpty) {
            final query = _searchQuery.toLowerCase();
            filteredItems = filteredItems.where((k) {
              final nama = (k['mahasiswa_nama'] ?? '').toString().toLowerCase();
              final nim = (k['mahasiswa_nim'] ?? '').toString().toLowerCase();
              return nama.contains(query) || nim.contains(query);
            }).toList();
          }

          return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Rekap Status
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          context,
                          'Diterima',
                          listDiterima.length.toString(),
                          AppColors.success,
                          Icons.check_circle_rounded,
                          'LAYAK',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSummaryCard(
                          context,
                          'Dipertimbangkan',
                          listDipertimbangkan.length.toString(),
                          AppColors.warning,
                          Icons.more_horiz_rounded,
                          'DIPERTIMBANGKAN',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSummaryCard(
                          context,
                          'Ditolak',
                          listDitolak.length.toString(),
                          AppColors.error,
                          Icons.cancel_rounded,
                          'TIDAK_LAYAK',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Search Field
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
                      });
                    },
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Daftar Keputusan Seleksi',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Theme.of(context).textTheme.titleLarge?.color ?? AppColors.textPrimary),
                      ),
                      if (_selectedStatus != null || _searchQuery.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedStatus = null;
                              _searchQuery = '';
                            });
                          },
                          child: const Text('Reset Filter'),
                        )
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  if (filteredItems.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(child: Text('Tidak ada data yang cocok dengan pencarian / filter ini.')),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredItems.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        final id = item['id'] as String;
                        final kelayakan = item['kelayakan'] ?? '';
                      final catatan = item['keterangan'] ?? '';
                      
                      Color statusColor;
                      IconData statusIcon;
                      String statusText;
                      if (kelayakan == 'LAYAK') {
                        statusColor = AppColors.success;
                        statusIcon = Icons.check_circle_rounded;
                        statusText = 'DITERIMA';
                      } else if (kelayakan == 'TIDAK_LAYAK') {
                        statusColor = AppColors.error;
                        statusIcon = Icons.cancel_rounded;
                        statusText = 'DITOLAK';
                      } else {
                        statusColor = AppColors.warning;
                        statusIcon = Icons.more_horiz_rounded;
                        statusText = 'DIPERTIMBANGKAN';
                      }

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : Colors.white,
                          border: Border.all(color: isDark ? AppColors.darkOutline : Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Checkbox(
                                  value: _selectedIds.contains(id),
                                  onChanged: (bool? value) {
                                    setState(() {
                                      if (value == true) {
                                        _selectedIds.add(id);
                                      } else {
                                        _selectedIds.remove(id);
                                      }
                                    });
                                  },
                                ),
                                CircleAvatar(
                                  backgroundColor: AppColors.primary.withOpacity(0.1),
                                  child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['mahasiswa_nama'] ?? '-',
                                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Theme.of(context).textTheme.bodyLarge?.color),
                                      ),
                                      Text(
                                        item['mahasiswa_nim'] ?? '-',
                                        style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color ?? AppColors.textSecondary, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(statusIcon, size: 14, color: statusColor),
                                      const SizedBox(width: 4),
                                      Text(
                                        statusText,
                                        style: TextStyle(
                                          color: statusColor,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (catatan.isNotEmpty) ...[
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Divider(height: 1),
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.format_quote_rounded, size: 16, color: Theme.of(context).iconTheme.color?.withOpacity(0.5) ?? AppColors.textTertiary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      catatan,
                                      style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodyMedium?.color ?? AppColors.textSecondary, fontStyle: FontStyle.italic),
                                    ),
                                  ),
                                ],
                              ),
                            ]
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
        },
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, String title, String value, Color color, IconData icon, String statusKey) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _selectedStatus == statusKey;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          if (_selectedStatus == statusKey) {
            _selectedStatus = null;
          } else {
            _selectedStatus = statusKey;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(isDark ? 0.3 : 0.1) : (isDark ? AppColors.darkSurface : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? color : color.withOpacity(0.4), width: isSelected ? 2.0 : 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 16, color: color),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).textTheme.displayLarge?.color ?? AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: color,
            ),
          ),
        ],
      ),
    ),
    );
  }
}
