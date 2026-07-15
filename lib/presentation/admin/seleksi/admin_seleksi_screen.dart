import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/app_providers.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../data/models/app_models.dart';
import 'admin_penentuan_seleksi_screen.dart';

class AdminSeleksiScreen extends ConsumerStatefulWidget {
  const AdminSeleksiScreen({super.key});

  @override
  ConsumerState<AdminSeleksiScreen> createState() => _AdminSeleksiScreenState();
}

class _AdminSeleksiScreenState extends ConsumerState<AdminSeleksiScreen> {
  String _searchQuery = '';
  String _sortOrder = 'terbaru';
  int _selectedTab = 0; // 0: Belum, 1: Sudah
  int _currentPage = 1;
  final int _itemsPerPage = 10;

  Color _getCategoryColor(String kategori) {
    switch (kategori.toLowerCase()) {
      case 'bawah':
      case 'rendah':
      case 'prioritas':
        return AppColors.error;
      case 'menengah':
        return AppColors.warning;
      case 'atas':
      case 'tinggi':
      case 'tidak prioritas':
        return AppColors.success;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final clusteringAsync = ref.watch(clusteringResultsProvider);
    final seleksiAsync = ref.watch(seleksiListProvider(const {'page': 1, 'per_page': 100}));
    final seleksiList = seleksiAsync.when(
      data: (data) => (data['items'] as List?) ?? [],
      loading: () => [],
      error: (_, __) => [],
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Penentuan Hasil Seleksi')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(clusteringResultsProvider),
        child: clusteringAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(20),
            child: ShimmerList(count: 5),
          ),
          error: (e, _) => ErrorState(
            message: e.toString(),
            onRetry: () => ref.invalidate(clusteringResultsProvider),
          ),
          data: (result) {
            final members = result.members;
            if (members.isEmpty) {
              return const EmptyState(
                title: 'Belum Ada Hasil',
                subtitle: 'Data clustering belum tersedia atau belum dijalankan',
                icon: Icons.pie_chart_outline_rounded,
              );
            }

            // Filter by Tab (0 = Belum Ditentukan/Dipertimbangkan, 1 = Diterima/Ditolak)
            var tabFilteredMembers = members.where((m) {
              final sDataRaw = seleksiList.where((s) => s['pengajuan_id'] == m.pengajuanId).toList();
              final isSeleksiDone = sDataRaw.isNotEmpty;
              final kelayakan = isSeleksiDone ? sDataRaw.first['kelayakan'] as String? : null;
              
              if (_selectedTab == 0) {
                return kelayakan == null || kelayakan == 'DIPERTIMBANGKAN';
              } else {
                return kelayakan == 'LAYAK' || kelayakan == 'TIDAK_LAYAK';
              }
            }).toList();

            // Apply Search
            var filteredMembers = tabFilteredMembers.where((m) {
              if (_searchQuery.isEmpty) return true;
              return m.mahasiswaNama.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                     m.mahasiswaNim.toLowerCase().contains(_searchQuery.toLowerCase());
            }).toList();

            // Apply Sort
            filteredMembers.sort((a, b) {
              final dateA = DateTime.tryParse(a.createdAt ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
              final dateB = DateTime.tryParse(b.createdAt ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
              if (_sortOrder == 'terbaru') {
                return dateB.compareTo(dateA);
              } else {
                return dateA.compareTo(dateB);
              }
            });

            return Column(
              children: [
                // Tab Selector
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? AppColors.darkSurfaceVariant : Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() { _selectedTab = 0; _currentPage = 1; }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _selectedTab == 0 ? Theme.of(context).cardColor : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: _selectedTab == 0 ? [const BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))] : [],
                            ),
                            alignment: Alignment.center,
                            child: Text('Belum Ditentukan', style: TextStyle(fontWeight: _selectedTab == 0 ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() { _selectedTab = 1; _currentPage = 1; }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _selectedTab == 1 ? Theme.of(context).cardColor : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: _selectedTab == 1 ? [const BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))] : [],
                            ),
                            alignment: Alignment.center,
                            child: Text('Sudah Ditentukan', style: TextStyle(fontWeight: _selectedTab == 1 ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Cari nama/NIM...',
                            prefixIcon: const Icon(Icons.search),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: AppColors.outline),
                            ),
                          ),
                          onChanged: (v) => setState(() { _searchQuery = v; _currentPage = 1; }),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.outline),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _sortOrder,
                              isExpanded: true,
                              icon: const Icon(Icons.sort_rounded, size: 20),
                              items: const [
                                DropdownMenuItem(value: 'terbaru', child: Text('Terbaru', style: TextStyle(fontSize: 13))),
                                DropdownMenuItem(value: 'terlama', child: Text('Terlama', style: TextStyle(fontSize: 13))),
                              ],
                              onChanged: (v) {
                                if (v != null) setState(() { _sortOrder = v; _currentPage = 1; });
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Builder(
                    builder: (context) {
                      if (filteredMembers.isEmpty) {
                        return const Center(child: Text('Tidak ada mahasiswa yang sesuai pencarian', style: TextStyle(color: Colors.grey)));
                      }

                      int totalPages = (filteredMembers.length / _itemsPerPage).ceil();
                      var paginatedMembers = filteredMembers.skip((_currentPage - 1) * _itemsPerPage).take(_itemsPerPage).toList();

                      return Column(
                        children: [
                          Expanded(
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              itemCount: paginatedMembers.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (_, i) {
                                final m = paginatedMembers[i];
                final catColor = _getCategoryColor(m.kmeansKategori);
                
                return Material(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(14),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      if (m.pengajuanId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('ID Pengajuan tidak ditemukan untuk mahasiswa ini')),
                        );
                        return;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AdminPenentuanSeleksiScreen(
                            member: m,
                            pengajuanId: m.pengajuanId!,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.outline),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: catColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.person_rounded, color: catColor, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(m.mahasiswaNama, style: Theme.of(context).textTheme.titleSmall),
                                  Text(m.mahasiswaNim, style: Theme.of(context).textTheme.bodySmall),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: catColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    m.kmeansKategori.toUpperCase().replaceAll('_', ' '),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: catColor,
                                    ),
                                  ),
                                ),
                                if (_selectedTab == 1) ...[
                                  const SizedBox(height: 4),
                                  Builder(
                                    builder: (ctx) {
                                      final sDataRaw = seleksiList.where((s) => s['pengajuan_id'] == m.pengajuanId).toList();
                                      final kelayakan = sDataRaw.isNotEmpty ? sDataRaw.first['kelayakan'] as String? : null;
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: kelayakan == 'LAYAK' ? AppColors.success.withOpacity(0.1) : AppColors.error.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          kelayakan == 'LAYAK' ? 'DITERIMA' : 'DITOLAK',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: kelayakan == 'LAYAK' ? AppColors.success : AppColors.error,
                                          ),
                                        ),
                                      );
                                    }
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
              },
            ),
          ),
          if (totalPages > 1) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
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
            ),
          ],
        ],
      );
    },
  ),
),
        ],
      );
    },
    ),
  ),
);
  }
}
