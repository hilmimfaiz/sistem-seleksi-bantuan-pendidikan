import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../providers/app_providers.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../data/models/mahasiswa_model.dart';
import 'tambah_mahasiswa_dialog.dart';
import 'edit_mahasiswa_dialog.dart';
import 'package:intl/intl.dart';

class AdminMahasiswaScreen extends ConsumerStatefulWidget {
  const AdminMahasiswaScreen({super.key});

  @override
  ConsumerState<AdminMahasiswaScreen> createState() => _AdminMahasiswaScreenState();
}

class _AdminMahasiswaScreenState extends ConsumerState<AdminMahasiswaScreen> {
  String _search = '';
  String _programStudi = 'Semua Program Studi';
  String _angkatan = 'Semua Angkatan';
  Map<String, MahasiswaModel> _selectedMahasiswa = {};
  bool _isSelectionMode = false;
  int _page = 1;
  final int _perPage = 10;

  void _showDetailMahasiswa(MahasiswaModel m) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollCtrl) => SingleChildScrollView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  GestureDetector(
                    onTap: m.fotoProfil != null && m.fotoProfil!.isNotEmpty
                        ? () {
                            showDialog(
                              context: context,
                              builder: (c) => Dialog(
                                backgroundColor: Colors.transparent,
                                insetPadding: const EdgeInsets.all(16),
                                child: Stack(
                                  alignment: Alignment.topRight,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Image.network(
                                        '${AppEndpoints.baseUrl}/${m.fotoProfil}',
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, color: Colors.white, shadows: [Shadow(color: Colors.black54, blurRadius: 4)]),
                                      onPressed: () => Navigator.pop(c),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                        : null,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        shape: BoxShape.circle,
                        image: m.fotoProfil != null && m.fotoProfil!.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage('${AppEndpoints.baseUrl}/${m.fotoProfil}'),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: m.fotoProfil == null || m.fotoProfil!.isEmpty
                          ? const Icon(Icons.person_rounded, color: AppColors.primary, size: 30)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.nama, style: Theme.of(ctx).textTheme.titleLarge),
                        Text(m.nim, style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              _buildDetailItem('Program Studi', m.programStudi, Icons.school_rounded, ctx),
              _buildDetailItem('Fakultas', m.fakultas, Icons.domain_rounded, ctx),
              _buildDetailItem('Angkatan', m.angkatan.toString(), Icons.date_range_rounded, ctx),
              _buildDetailItem('Jenis Kelamin', m.jenisKelamin == 'LAKI_LAKI' ? 'Laki-laki' : 'Perempuan', Icons.wc_rounded, ctx),
              _buildDetailItem('Nomor HP', m.nomorHp, Icons.phone_rounded, ctx),
              _buildDetailItem('Alamat', m.alamat, Icons.location_on_rounded, ctx),
              _buildDetailItem(
                m.uktAkhir != null ? 'UKT Penurunan' : 'Golongan UKT', 
                m.uktAkhir != null 
                    ? NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(m.uktAkhir) 
                    : (m.uktAwal != null ? NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(m.uktAwal) : 'Belum diisi'), 
                Icons.monetization_on_rounded, 
                ctx
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (c) => AlertDialog(
                            title: const Text('Hapus Mahasiswa?'),
                            content: const Text('Tindakan ini akan menonaktifkan akun mahasiswa ini. Anda yakin?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(c, false),
                                child: const Text('Batal'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(c, true),
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                                child: const Text('Hapus', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true && mounted) {
                          try {
                            await ref.read(mahasiswaRepositoryProvider).deleteMahasiswa(m.id);
                            if (mounted) {
                              Navigator.pop(ctx);
                              ref.invalidate(adminMahasiswaListProvider);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Mahasiswa berhasil dihapus'), backgroundColor: AppColors.success),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
                              );
                            }
                          }
                        }
                      },
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text('Hapus'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        // Close bottom sheet first
                        Navigator.pop(ctx);
                        final result = await showDialog(
                          context: context,
                          builder: (_) => EditMahasiswaDialog(mahasiswa: m),
                        );
                        if (result == true && mounted) {
                          ref.invalidate(adminMahasiswaListProvider);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Data mahasiswa berhasil diperbarui!'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.edit_rounded, color: Colors.white),
                      label: const Text('Edit Profil', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon, BuildContext ctx) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.textTertiary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final paramsJson = jsonEncode({
      'page': _page,
      'per_page': _perPage,
      'search': _search.isEmpty ? null : _search,
      'programStudi': _programStudi == 'Semua Program Studi' ? null : _programStudi,
      'angkatan': _angkatan == 'Semua Angkatan' ? null : int.tryParse(_angkatan),
    });
    final mahasiswaAsync = ref.watch(adminMahasiswaListProvider(paramsJson));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _isSelectionMode = false;
                    _selectedMahasiswa.clear();
                  });
                },
              )
            : null,
        title: !_isSelectionMode
            ? const Text('Data Mahasiswa')
            : GestureDetector(
                onTap: () {
                  if (_selectedMahasiswa.isEmpty) return;
                  showModalBottomSheet(
                    context: context,
                    builder: (ctx) => StatefulBuilder(
                      builder: (BuildContext context, StateSetter setModalState) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text('Mahasiswa Terpilih', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            ),
                            Flexible(
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: _selectedMahasiswa.length,
                                itemBuilder: (context, index) {
                                  final m = _selectedMahasiswa.values.elementAt(index);
                                  return ListTile(
                                    leading: const Icon(Icons.person),
                                    title: Text(m.nama),
                                    subtitle: Text(m.nim),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                                      onPressed: () {
                                        setState(() {
                                          _selectedMahasiswa.remove(m.id);
                                        });
                                        setModalState(() {});
                                        if (_selectedMahasiswa.isEmpty) Navigator.pop(ctx);
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      }
                    ),
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${_selectedMahasiswa.length} Terpilih'),
                    if (_selectedMahasiswa.isNotEmpty) const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
        actions: [
          if (!_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Hapus Banyak',
              onPressed: () {
                setState(() {
                  _isSelectionMode = true;
                });
              },
            )
          else if (_selectedMahasiswa.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Hapus Terpilih',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Konfirmasi Hapus'),
                    content: Text('Apakah Anda yakin ingin menghapus ${_selectedMahasiswa.length} mahasiswa terpilih? Tindakan ini tidak dapat dibatalkan.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Hapus', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
                if (confirm != true) return;

                final repo = ref.read(mahasiswaRepositoryProvider);
                for (final id in _selectedMahasiswa.keys) {
                  try {
                    await repo.deleteMahasiswa(id);
                  } catch (e) {
                    // Ignore or handle partial failure
                  }
                }
                setState(() {
                  _selectedMahasiswa.clear();
                  _isSelectionMode = false;
                });
                ref.invalidate(adminMahasiswaListProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Mahasiswa terpilih berhasil dihapus'), backgroundColor: AppColors.success),
                  );
                }
              },
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('SEARCH STUDENT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Theme.of(context).dividerTheme.color ?? Colors.transparent),
                  ),
                  child: TextField(
                    style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                    decoration: InputDecoration(
                      hintText: 'Search by name or ID...',
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      fillColor: Colors.transparent,
                    ),
                    onChanged: (v) => setState(() {
                      _search = v;
                      _page = 1;
                    }),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('PROGRAM STUDI', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Theme.of(context).dividerTheme.color ?? Colors.transparent),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: ref.watch(mahasiswaFiltersProvider).when(
                                data: (filters) {
                                  final prodiList = ['Semua Program Studi', ...filters['program_studi']!.map((e) => e.toString())];
                                  // Ensure current value is in list, else reset to default.
                                  String dropdownValue = prodiList.contains(_programStudi) ? _programStudi : 'Semua Program Studi';
                                  return DropdownButton<String>(
                                    isExpanded: true,
                                    value: dropdownValue,
                                    items: prodiList.map((e) {
                                      return DropdownMenuItem(value: e, child: Text(e));
                                    }).toList(),
                                    onChanged: (v) {
                                      if (v != null) {
                                        setState(() {
                                          _programStudi = v;
                                          _page = 1;
                                        });
                                      }
                                    },
                                  );
                                },
                                loading: () => DropdownButton<String>(
                                  isExpanded: true,
                                  value: 'Semua Program Studi',
                                  items: const [DropdownMenuItem(value: 'Semua Program Studi', child: Text('Loading...'))],
                                  onChanged: null,
                                ),
                                error: (_, __) => DropdownButton<String>(
                                  isExpanded: true,
                                  value: 'Semua Program Studi',
                                  items: const [DropdownMenuItem(value: 'Semua Program Studi', child: Text('Error load'))],
                                  onChanged: null,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('TAHUN ANGKATAN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Theme.of(context).dividerTheme.color ?? Colors.transparent),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: ref.watch(mahasiswaFiltersProvider).when(
                                data: (filters) {
                                  final angkatanList = ['Semua Angkatan', ...filters['angkatan']!.map((e) => e.toString())];
                                  String dropdownValue = angkatanList.contains(_angkatan) ? _angkatan : 'Semua Angkatan';
                                  return DropdownButton<String>(
                                    isExpanded: true,
                                    value: dropdownValue,
                                    items: angkatanList.map((e) {
                                      return DropdownMenuItem(value: e, child: Text(e));
                                    }).toList(),
                                    onChanged: (v) {
                                      if (v != null) {
                                        setState(() {
                                          _angkatan = v;
                                          _page = 1;
                                        });
                                      }
                                    },
                                  );
                                },
                                loading: () => DropdownButton<String>(
                                  isExpanded: true,
                                  value: 'Semua Angkatan',
                                  items: const [DropdownMenuItem(value: 'Semua Angkatan', child: Text('Loading...'))],
                                  onChanged: null,
                                ),
                                error: (_, __) => DropdownButton<String>(
                                  isExpanded: true,
                                  value: 'Semua Angkatan',
                                  items: const [DropdownMenuItem(value: 'Semua Angkatan', child: Text('Error load'))],
                                  onChanged: null,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          Expanded(
            child: mahasiswaAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(e.toString())),
              data: (data) {
                final items = data['items'] as List;
                final total = data['total'] ?? 0;
                final totalPages = data['total_pages'] ?? 1;
                final startIdx = items.isEmpty ? 0 : (_page - 1) * _perPage + 1;
                final endIdx = startIdx + items.length - (items.isEmpty ? 0 : 1);

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (_isSelectionMode)
                            Row(
                              children: [
                                Checkbox(
                                  value: items.isNotEmpty && items.every((m) => _selectedMahasiswa.containsKey((m as MahasiswaModel).id)),
                                  onChanged: (val) {
                                    setState(() {
                                      if (val == true) {
                                        for (final m in items) {
                                          final mahasiswa = m as MahasiswaModel;
                                          _selectedMahasiswa[mahasiswa.id] = mahasiswa;
                                        }
                                      } else {
                                        for (final m in items) {
                                          _selectedMahasiswa.remove((m as MahasiswaModel).id);
                                        }
                                      }
                                    });
                                  },
                                ),
                                const Text('Pilih Semua', style: TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            )
                          else
                            Text('Results ($total)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('Showing $startIdx-$endIdx', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: items.isEmpty
                          ? const Center(child: Text('Tidak ada mahasiswa ditemukan'))
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: items.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 0),
                              itemBuilder: (_, i) {
                                final m = items[i] as MahasiswaModel;
                                final isFirst = i == 0;
                                final isLast = i == items.length - 1;

                                return Material(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.vertical(
                                    top: isFirst ? const Radius.circular(8) : Radius.zero,
                                    bottom: isLast ? const Radius.circular(8) : Radius.zero,
                                  ),
                                  child: InkWell(
                                    onTap: () => _showDetailMahasiswa(m),
                                    borderRadius: BorderRadius.vertical(
                                      top: isFirst ? const Radius.circular(8) : Radius.zero,
                                      bottom: isLast ? const Radius.circular(8) : Radius.zero,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          top: BorderSide(color: Theme.of(context).dividerTheme.color ?? Colors.transparent),
                                          left: BorderSide(color: Theme.of(context).dividerTheme.color ?? Colors.transparent),
                                          right: BorderSide(color: Theme.of(context).dividerTheme.color ?? Colors.transparent),
                                          bottom: isLast ? BorderSide(color: Theme.of(context).dividerTheme.color ?? Colors.transparent) : BorderSide.none,
                                        ),
                                        borderRadius: BorderRadius.vertical(
                                          top: isFirst ? const Radius.circular(8) : Radius.zero,
                                          bottom: isLast ? const Radius.circular(8) : Radius.zero,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          if (_isSelectionMode)
                                            Checkbox(
                                              value: _selectedMahasiswa.containsKey(m.id),
                                              onChanged: (val) {
                                                setState(() {
                                                  if (val == true) {
                                                    _selectedMahasiswa[m.id] = m;
                                                  } else {
                                                    _selectedMahasiswa.remove(m.id);
                                                  }
                                                });
                                              },
                                            ),
                                          Container(
                                            width: 48,
                                            height: 48,
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurfaceVariant : Colors.grey.shade100,
                                              shape: BoxShape.circle,
                                              border: Border.all(color: Theme.of(context).dividerTheme.color ?? Colors.transparent),
                                              image: m.fotoProfil != null && m.fotoProfil!.isNotEmpty
                                                  ? DecorationImage(
                                                      image: NetworkImage('${AppEndpoints.baseUrl}/${m.fotoProfil}'),
                                                      fit: BoxFit.cover,
                                                    )
                                                  : null,
                                            ),
                                            child: m.fotoProfil == null || m.fotoProfil!.isEmpty
                                                ? Icon(Icons.person_outline, color: Theme.of(context).iconTheme.color)
                                                : null,
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(m.nama, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).textTheme.titleLarge?.color)),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'ID: ${m.nim} • ${m.programStudi} • ${m.angkatan}',
                                                  style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 14),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Icon(Icons.chevron_right_rounded, color: Theme.of(context).iconTheme.color),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    if (totalPages > 1)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            InkWell(
                              onTap: _page > 1 ? () => setState(() => _page--) : null,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Theme.of(context).dividerTheme.color ?? Colors.transparent),
                                  borderRadius: BorderRadius.circular(8),
                                  color: _page > 1 ? Theme.of(context).colorScheme.surface : (Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurfaceVariant : Colors.grey.shade100),
                                ),
                                child: const Icon(Icons.chevron_left, size: 20),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text('Page $_page of $totalPages', style: const TextStyle(fontWeight: FontWeight.w500)),
                            const SizedBox(width: 16),
                            InkWell(
                              onTap: _page < totalPages ? () => setState(() => _page++) : null,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Theme.of(context).dividerTheme.color ?? Colors.transparent),
                                  borderRadius: BorderRadius.circular(8),
                                  color: _page < totalPages ? Theme.of(context).colorScheme.surface : (Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurfaceVariant : Colors.grey.shade100),
                                ),
                                child: const Icon(Icons.chevron_right, size: 20),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await showDialog(
            context: context,
            builder: (_) => const TambahMahasiswaDialog(),
          );
          if (result == true && mounted) {
            ref.invalidate(adminMahasiswaListProvider);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Akun mahasiswa berhasil ditambahkan!'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }
}
