import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/app_models.dart';
import '../../../providers/app_providers.dart';
import '../../../shared/widgets/app_widgets.dart';

class BantuanManagementScreen extends ConsumerStatefulWidget {
  const BantuanManagementScreen({super.key});

  @override
  ConsumerState<BantuanManagementScreen> createState() =>
      _BantuanManagementScreenState();
}

class _BantuanManagementScreenState extends ConsumerState<BantuanManagementScreen> {
  void _showFormDialog({BantuanModel? bantuan}) {
    final namaCtrl = TextEditingController(text: bantuan?.nama ?? '');
    final deskCtrl = TextEditingController(text: bantuan?.deskripsi ?? '');
    final syaratCtrl = TextEditingController(text: bantuan?.persyaratan ?? '');
    final kuotaCtrl = TextEditingController(text: bantuan?.kuota.toString() ?? '');
    final danaCtrl = TextEditingController(text: bantuan?.jumlahDana.toStringAsFixed(0) ?? '');
    String status = bantuan?.status ?? 'AKTIF';
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.9,
          maxChildSize: 0.95,
          minChildSize: 0.6,
          expand: false,
          builder: (_, scrollCtrl) => SingleChildScrollView(
            controller: scrollCtrl,
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                const SizedBox(height: 20),
                Text(
                  bantuan == null ? 'Tambah Bantuan Baru' : 'Edit Bantuan',
                  style: Theme.of(ctx).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),
                AppTextField(
                  label: 'Nama Program Bantuan',
                  controller: namaCtrl,
                  prefixIcon: Icons.school_outlined,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Deskripsi',
                  controller: deskCtrl,
                  maxLines: 3,
                  prefixIcon: Icons.description_outlined,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Persyaratan',
                  controller: syaratCtrl,
                  maxLines: 4,
                  prefixIcon: Icons.checklist_rounded,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: 'Kuota',
                        controller: kuotaCtrl,
                        keyboardType: TextInputType.number,
                        prefixIcon: Icons.people_outline,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        label: 'Dana (Rp)',
                        controller: danaCtrl,
                        keyboardType: TextInputType.number,
                        prefixIcon: Icons.attach_money_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    prefixIcon: Icon(Icons.toggle_on_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'AKTIF', child: Text('Aktif')),
                    DropdownMenuItem(value: 'TIDAK_AKTIF', child: Text('Tidak Aktif')),
                  ],
                  onChanged: (v) => setModalState(() => status = v ?? 'AKTIF'),
                ),
                const SizedBox(height: 24),
                AppButton(
                  label: bantuan == null ? 'Simpan Bantuan' : 'Simpan Perubahan',
                  isLoading: isLoading,
                  onPressed: () async {
                    setModalState(() => isLoading = true);
                    try {
                      final data = {
                        'nama': namaCtrl.text.trim(),
                        'deskripsi': deskCtrl.text.trim(),
                        'persyaratan': syaratCtrl.text.trim(),
                        'kuota': int.tryParse(kuotaCtrl.text) ?? 0,
                        'jumlah_dana': double.tryParse(danaCtrl.text) ?? 0,
                        'status': status,
                      };
                      final repo = ref.read(bantuanRepositoryProvider);
                      if (bantuan == null) {
                        await repo.create(data);
                      } else {
                        await repo.update(bantuan.id, data);
                      }
                      ref.invalidate(bantuanListProvider);
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Data bantuan berhasil disimpan ✓'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    } catch (e) {
                      setModalState(() => isLoading = false);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bantuanAsync = ref.watch(bantuanListProvider(const {}));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Bantuan'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFormDialog(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(bantuanListProvider),
        child: bantuanAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(20),
            child: ShimmerList(count: 4),
          ),
          error: (e, _) => ErrorState(
            message: e.toString(),
            onRetry: () => ref.invalidate(bantuanListProvider),
          ),
          data: (data) {
            final items = data['items'] as List<BantuanModel>;
            if (items.isEmpty) {
              return const EmptyState(
                title: 'Belum Ada Bantuan',
                subtitle: 'Tambah program bantuan dengan tombol +',
                icon: Icons.school_outlined,
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final b = items[i];
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
                          Expanded(
                            child: Text(b.nama, style: Theme.of(context).textTheme.titleSmall),
                          ),
                          StatusBadge(status: b.status),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(b.deskripsi, style: Theme.of(context).textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.people_outline, size: 14, color: AppColors.textTertiary),
                          const SizedBox(width: 4),
                          Text('Kuota: ${b.kuota}', style: Theme.of(context).textTheme.bodySmall),
                          const SizedBox(width: 16),
                          Icon(Icons.attach_money_rounded, size: 14, color: AppColors.textTertiary),
                          Text('Rp ${b.jumlahDana.toStringAsFixed(0)}', style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () => _showFormDialog(bantuan: b),
                            icon: const Icon(Icons.edit_rounded, size: 16),
                            label: const Text('Edit'),
                            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                          ),
                          TextButton.icon(
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (d) => AlertDialog(
                                  title: const Text('Hapus Bantuan?'),
                                  content: Text('Hapus "${b.nama}"?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Batal')),
                                    TextButton(onPressed: () => Navigator.pop(d, true), child: const Text('Hapus', style: TextStyle(color: AppColors.error))),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await ref.read(bantuanRepositoryProvider).delete(b.id);
                                ref.invalidate(bantuanListProvider);
                              }
                            },
                            icon: const Icon(Icons.delete_outline_rounded, size: 16),
                            label: const Text('Hapus'),
                            style: TextButton.styleFrom(foregroundColor: AppColors.error),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
