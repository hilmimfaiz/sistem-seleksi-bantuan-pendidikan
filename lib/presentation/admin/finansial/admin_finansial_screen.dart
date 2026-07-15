import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/app_providers.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../data/models/app_models.dart';

class AdminFinansialScreen extends ConsumerStatefulWidget {
  const AdminFinansialScreen({super.key});

  @override
  ConsumerState<AdminFinansialScreen> createState() => _AdminFinansialScreenState();
}

class _AdminFinansialScreenState extends ConsumerState<AdminFinansialScreen> {
  String _search = '';
  String _programStudi = 'Semua Program Studi';
  String _angkatan = 'Semua Angkatan';
  int _page = 1;
  final int _perPage = 10;

  String _formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }

  void _showDetailFinansial(DataFinansialModel f) {
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
                  Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(f.mahasiswaNama ?? 'Mahasiswa', style: Theme.of(ctx).textTheme.titleLarge),
                        Text(f.mahasiswaNim ?? 'NIM Tidak Diketahui', style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              _buildDetailItem('Pendapatan Orang Tua', _formatCurrency(f.pendapatanOrangTua), Icons.monetization_on_rounded, ctx),
              _buildDetailItem('Jumlah Tanggungan', '${f.jumlahTanggungan} Orang', Icons.people_alt_rounded, ctx),
              _buildDetailItem('Pengeluaran Bulanan', _formatCurrency(f.pengeluaranBulanan), Icons.money_off_rounded, ctx),
              _buildDetailItem('Uang Saku', _formatCurrency(f.uangSaku), Icons.account_balance_wallet_rounded, ctx),
              _buildDetailItem('Literasi Keuangan', '${f.literasiKeuangan}/10', Icons.menu_book_rounded, ctx),
              _buildDetailItem('Gaya Hidup', '${f.gayaHidup}/10', Icons.style_rounded, ctx),
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
    final finansialAsync = ref.watch(adminFinansialListProvider(paramsJson));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Data Finansial Mahasiswa')),
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
            child: finansialAsync.when(
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
                          Text('Results ($total)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('Showing $startIdx-$endIdx', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: items.isEmpty
                          ? const Center(child: Text('Belum Ada Data Finansial'))
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: items.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 0),
                              itemBuilder: (_, i) {
                                final f = items[i] as DataFinansialModel;
                                final isFirst = i == 0;
                                final isLast = i == items.length - 1;

                                return Material(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.vertical(
                                    top: isFirst ? const Radius.circular(8) : Radius.zero,
                                    bottom: isLast ? const Radius.circular(8) : Radius.zero,
                                  ),
                                  child: InkWell(
                                    onTap: () => _showDetailFinansial(f),
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
                                          Container(
                                            width: 48,
                                            height: 48,
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurfaceVariant : Colors.grey.shade100,
                                              shape: BoxShape.circle,
                                              border: Border.all(color: Theme.of(context).dividerTheme.color ?? Colors.transparent),
                                            ),
                                            child: Icon(Icons.account_balance_wallet_outlined, color: Theme.of(context).iconTheme.color),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(f.mahasiswaNama ?? 'Mahasiswa', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).textTheme.titleLarge?.color)),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'ID: ${f.mahasiswaNim ?? '-'} • ${_formatCurrency(f.pendapatanOrangTua)}',
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
    );
  }
}
