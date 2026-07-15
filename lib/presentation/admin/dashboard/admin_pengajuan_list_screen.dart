import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/app_providers.dart';
import '../../../shared/widgets/app_widgets.dart';

class AdminPengajuanListScreen extends ConsumerStatefulWidget {
  final String status;
  final String title;

  const AdminPengajuanListScreen({
    super.key,
    required this.status,
    required this.title,
  });

  @override
  ConsumerState<AdminPengajuanListScreen> createState() => _AdminPengajuanListScreenState();
}

class _AdminPengajuanListScreenState extends ConsumerState<AdminPengajuanListScreen> {
  String _searchQuery = '';
  int _currentPage = 1;
  final int _itemsPerPage = 10;

  @override
  Widget build(BuildContext context) {
    final pengajuanAsync = ref.watch(adminPengajuanByStatusProvider(widget.status));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(adminPengajuanByStatusProvider(widget.status)),
        child: pengajuanAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(20),
            child: ShimmerList(count: 5),
          ),
          error: (e, _) => ErrorState(
            message: e.toString(),
            onRetry: () => ref.invalidate(adminPengajuanByStatusProvider(widget.status)),
          ),
          data: (data) {
            var items = (data['items'] as List?) ?? [];
            
            if (_searchQuery.isNotEmpty) {
               final query = _searchQuery.toLowerCase();
               items = items.where((p) {
                  final nama = (p['mahasiswa_nama'] ?? '').toString().toLowerCase();
                  final nim = (p['mahasiswa_nim'] ?? '').toString().toLowerCase();
                  return nama.contains(query) || nim.contains(query);
               }).toList();
            }

            final totalItems = items.length;
            final totalPages = (totalItems / _itemsPerPage).ceil();

            if (_currentPage > totalPages && totalPages > 0) {
              _currentPage = totalPages;
            } else if (_currentPage < 1) {
              _currentPage = 1;
            }

            final startIndex = (_currentPage - 1) * _itemsPerPage;
            final endIndex = (startIndex + _itemsPerPage > totalItems) ? totalItems : startIndex + _itemsPerPage;

            final paginatedList = startIndex < totalItems ? items.sublist(startIndex, endIndex) : [];

            Widget content;
            if (items.isEmpty) {
              content = const EmptyState(
                title: 'Tidak Ada Data',
                subtitle: 'Belum ada data pengajuan dengan status ini atau cocok dengan pencarian.',
                icon: Icons.folder_open_rounded,
              );
            } else {
              content = ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: paginatedList.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final p = paginatedList[i];
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
                                  p['mahasiswa_nama'] ?? 'Mahasiswa',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                Text(
                                  'NIM: ${p['mahasiswa_nim'] ?? '-'}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          StatusBadge(status: p['status'] ?? widget.status),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        p['bantuan_nama'] ?? 'Bantuan Pendidikan',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      Text(
                        'Diajukan: ${p['created_at'].toString().substring(0, 10)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (p['catatan'] != null && p['catatan'].toString().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.info_outline_rounded,
                                  size: 16, color: AppColors.error),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Catatan: ${p['catatan']}',
                                  style: const TextStyle(
                                      fontSize: 12, color: AppColors.error),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
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
                  child: TextField(
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
