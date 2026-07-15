import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/app_providers.dart';
import '../../../shared/widgets/app_widgets.dart';
import 'package:intl/intl.dart';

class AdminNotifikasiScreen extends ConsumerWidget {
  const AdminNotifikasiScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifAsync = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi Admin'),
        actions: [
          TextButton(
            onPressed: () async {
              await ref
                  .read(notificationRepositoryProvider)
                  .markAllAsRead();
              ref.invalidate(notificationsProvider);
            },
            child: const Text('Tandai Semua'),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Hapus Riwayat',
            onSelected: (period) async {
              final String periodText = {
                '1h': '1 jam terakhir',
                '24h': '24 jam terakhir',
                '7d': '7 hari terakhir',
                '30d': '1 bulan terakhir',
                'all': 'keseluruhan',
              }[period] ?? period;

              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Konfirmasi Hapus'),
                  content: Text('Apakah Anda yakin ingin menghapus riwayat notifikasi $periodText?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Batal'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Hapus', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );

              if (confirm != true) return;

              try {
                await ref.read(notificationRepositoryProvider).deleteHistory(period);
                ref.invalidate(notificationsProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Riwayat notifikasi berhasil dihapus')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal menghapus: $e')),
                  );
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: '1h', child: Text('1 jam terakhir')),
              const PopupMenuItem(value: '24h', child: Text('24 jam terakhir')),
              const PopupMenuItem(value: '7d', child: Text('7 hari terakhir')),
              const PopupMenuItem(value: '30d', child: Text('1 bulan terakhir')),
              const PopupMenuItem(value: 'all', child: Text('Hapus keseluruhan', style: TextStyle(color: Colors.red))),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(notificationsProvider),
        child: notifAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(20),
            child: ShimmerList(count: 5),
          ),
          error: (e, _) => ErrorState(message: e.toString()),
          data: (data) {
            final items = data['items'] as List? ?? [];
            if (items.isEmpty) {
              return const EmptyState(
                title: 'Tidak Ada Notifikasi',
                subtitle: 'Notifikasi akan muncul di sini',
                icon: Icons.notifications_none_rounded,
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final n = items[i];
                return InkWell(
                  onTap: () async {
                    if (!n.isRead) {
                      await ref
                          .read(notificationRepositoryProvider)
                          .markAsRead(n.id);
                      ref.invalidate(notificationsProvider);
                    }
                    if (context.mounted) {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          title: Text(n.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          content: Text(n.body, style: const TextStyle(fontSize: 14)),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    color: n.isRead
                        ? null
                        : AppColors.primaryContainer.withOpacity(0.5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: n.isRead
                                ? AppColors.surfaceVariant
                                : AppColors.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.notifications_rounded,
                            size: 20,
                            color: n.isRead
                                ? AppColors.textTertiary
                                : AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                n.title,
                                style: TextStyle(
                                  fontWeight: n.isRead
                                      ? FontWeight.w500
                                      : FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                n.body,
                                style: Theme.of(context).textTheme.bodySmall,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                DateFormat('EEEE, dd MMMM yyyy HH:mm').format(DateTime.parse(n.createdAt).toLocal()),
                                style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                              ),
                            ],
                          ),
                        ),
                        if (!n.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(top: 4),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
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
