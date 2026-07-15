import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../providers/app_providers.dart';
import '../../../../core/network/dio_client.dart';

class AdminLaporanScreen extends ConsumerStatefulWidget {
  const AdminLaporanScreen({super.key});

  @override
  ConsumerState<AdminLaporanScreen> createState() => _AdminLaporanScreenState();
}

class _AdminLaporanScreenState extends ConsumerState<AdminLaporanScreen> {
  DateTime? _startDate;
  DateTime? _endDate;

  Future<void> _pickDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  void _clearDateFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
  }

  Future<void> _downloadCsv() async {
    String url = '${AppEndpoints.baseUrl}${AppEndpoints.apiPrefix}/admin/stats/download';
    
    final queryParams = <String>[];
    if (_startDate != null) {
      queryParams.add('start_date=${DateFormat('yyyy-MM-dd').format(_startDate!)}');
    }
    if (_endDate != null) {
      queryParams.add('end_date=${DateFormat('yyyy-MM-dd').format(_endDate!)}');
    }
    if (queryParams.isNotEmpty) {
      url += '?${queryParams.join('&')}';
    }

    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal membuka URL download')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showStatusStudentsDialog(String status, List<dynamic> students) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.black12)),
                  ),
                  child: Row(
                    children: [
                      Text('Mahasiswa - $status', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('${students.length}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: students.isEmpty
                      ? const Center(child: Text('Tidak ada mahasiswa'))
                      : ListView.separated(
                          controller: scrollController,
                          itemCount: students.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final m = students[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.primaryContainer,
                                child: Text(m['nama'].toString().substring(0, 1).toUpperCase(), style: const TextStyle(color: AppColors.primary)),
                              ),
                              title: Text(m['nama'], style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(m['nim']),
                              onTap: () {
                                // optional navigasi ke detail mahasiswa
                              },
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filters = (
      startDate: _startDate != null ? DateFormat('yyyy-MM-dd').format(_startDate!) : null,
      endDate: _endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : null,
    );

    final statsAsync = ref.watch(adminStatsProvider(filters));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Statistik'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: AppColors.primary),
            tooltip: 'Download Laporan (CSV)',
            onPressed: _downloadCsv,
          ),
        ],
      ),
      body: statsAsync.when(
        data: (data) {
          final totalMahasiswa = data['total_mahasiswa'] ?? 0;
          final totalPengajuan = data['total_pengajuan'] ?? 0;
          
          final statusCount = (data['status_breakdown'] as Map<String, dynamic>?) ?? {};
          final statusStudents = (data['status_students'] as Map<String, dynamic>?) ?? {};
          
          final totalDiterima = (statusCount['DITERIMA'] ?? 0) + (statusCount['TERVERIFIKASI'] ?? 0);
          final totalDitolak = (statusCount['DITOLAK'] ?? 0) + (statusCount['TIDAK_DITERIMA'] ?? 0);
          final totalMenunggu = statusCount['MENUNGGU'] ?? 0;
          final totalRevisi = statusCount['REVISI'] ?? 0;
          
          final clusterStats = (data['cluster_stats'] as Map<String, dynamic>?) ?? {};
          final sangatMembutuhkan = clusterStats['Sangat Membutuhkan'] ?? 0;
          final membutuhkan = clusterStats['Membutuhkan'] ?? 0;
          final cukupMampu = clusterStats['Cukup Mampu'] ?? 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Date Filter UI
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Filter Rentang Tanggal Pengajuan', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 2),
                            Text(
                              _startDate != null && _endDate != null
                                  ? '${DateFormat('dd MMM yyyy').format(_startDate!)} - ${DateFormat('dd MMM yyyy').format(_endDate!)}'
                                  : 'Semua Waktu',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      if (_startDate != null)
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: _clearDateFilter,
                          tooltip: 'Hapus Filter',
                        ),
                      TextButton(
                        onPressed: _pickDateRange,
                        child: const Text('Ubah'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Summary Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        context,
                        title: 'Total Mahasiswa',
                        value: '$totalMahasiswa',
                        icon: Icons.people_outline,
                        color: AppColors.primary,
                        onTap: () {
                          Navigator.pushNamed(context, '/admin/mahasiswa');
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        context,
                        title: 'Total Pengajuan',
                        value: '$totalPengajuan',
                        icon: Icons.description_outlined,
                        color: AppColors.secondary,
                        onTap: () {
                          final allStudents = <dynamic>[];
                          statusStudents.values.forEach((list) {
                            allStudents.addAll(list as List<dynamic>);
                          });
                          _showStatusStudentsDialog('Semua Pengajuan', allStudents);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Status Pengajuan Pie Chart
                _buildChartContainer(
                  context,
                  title: 'Status Pengajuan Bantuan',
                  child: totalPengajuan == 0 
                      ? const Center(child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text('Belum ada data pengajuan', style: TextStyle(color: Colors.grey)),
                      ))
                      : Column(
                          children: [
                            SizedBox(
                              height: 180,
                              child: PieChart(
                                PieChartData(
                                  sectionsSpace: 2,
                                  centerSpaceRadius: 40,
                                  sections: [
                                    if (totalDiterima > 0)
                                      PieChartSectionData(
                                        color: AppColors.success,
                                        value: (totalDiterima as num).toDouble(),
                                        title: '$totalDiterima\nDiterima',
                                        radius: 50,
                                        titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                    if (totalDitolak > 0)
                                      PieChartSectionData(
                                        color: AppColors.error,
                                        value: (totalDitolak as num).toDouble(),
                                        title: '$totalDitolak\nDitolak',
                                        radius: 50,
                                        titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                    if (totalMenunggu > 0)
                                      PieChartSectionData(
                                        color: AppColors.warning,
                                        value: (totalMenunggu as num).toDouble(),
                                        title: '$totalMenunggu\nMenunggu',
                                        radius: 50,
                                        titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                    if (totalRevisi > 0)
                                      PieChartSectionData(
                                        color: Colors.blueAccent,
                                        value: (totalRevisi as num).toDouble(),
                                        title: '$totalRevisi\nRevisi',
                                        radius: 50,
                                        titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Interactive Legend
                            const Text('Klik status di bawah ini untuk melihat daftar mahasiswa:', style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children: [
                                _buildLegendItem('Diterima', AppColors.success, () {
                                  final students = [
                                    ...(statusStudents['DITERIMA'] as List<dynamic>? ?? []),
                                    ...(statusStudents['TERVERIFIKASI'] as List<dynamic>? ?? [])
                                  ];
                                  _showStatusStudentsDialog('Diterima', students);
                                }),
                                _buildLegendItem('Menunggu', AppColors.warning, () {
                                  _showStatusStudentsDialog('Menunggu', statusStudents['MENUNGGU'] as List<dynamic>? ?? []);
                                }),
                                _buildLegendItem('Ditolak', AppColors.error, () {
                                  final students = [
                                    ...(statusStudents['DITOLAK'] as List<dynamic>? ?? []),
                                    ...(statusStudents['TIDAK_DITERIMA'] as List<dynamic>? ?? [])
                                  ];
                                  _showStatusStudentsDialog('Ditolak', students);
                                }),
                                _buildLegendItem('Revisi', Colors.blueAccent, () {
                                  _showStatusStudentsDialog('Revisi', statusStudents['REVISI'] as List<dynamic>? ?? []);
                                }),
                              ],
                            ),
                          ],
                        ),
                ),
                
                const SizedBox(height: 24),
                
                // Distribusi Clustering Bar Chart
                _buildChartContainer(
                  context,
                  title: 'Distribusi Kategori Kemampuan',
                  child: (sangatMembutuhkan == 0 && membutuhkan == 0 && cukupMampu == 0)
                      ? const Center(child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text('Belum ada data clustering', style: TextStyle(color: Colors.grey)),
                      ))
                      : SizedBox(
                          height: 220,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: [sangatMembutuhkan, membutuhkan, cukupMampu].reduce((a, b) => a > b ? a : b).toDouble() * 1.2,
                              barTouchData: BarTouchData(enabled: false),
                              titlesData: FlTitlesData(
                                show: true,
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (double value, TitleMeta meta) {
                                      const style = TextStyle(fontWeight: FontWeight.bold, fontSize: 10);
                                      String text;
                                      switch (value.toInt()) {
                                        case 0: text = 'Sangat Butuh'; break;
                                        case 1: text = 'Butuh'; break;
                                        case 2: text = 'Cukup Mampu'; break;
                                        default: text = ''; break;
                                      }
                                      return SideTitleWidget(
                                        axisSide: meta.axisSide,
                                        child: Text(text, style: style),
                                      );
                                    },
                                  ),
                                ),
                                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              gridData: const FlGridData(show: false),
                              borderData: FlBorderData(show: false),
                              barGroups: [
                                BarChartGroupData(
                                  x: 0,
                                  barRods: [
                                    BarChartRodData(
                                      toY: (sangatMembutuhkan as num).toDouble(),
                                      color: AppColors.error,
                                      width: 30,
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                    ),
                                  ],
                                  showingTooltipIndicators: [0],
                                ),
                                BarChartGroupData(
                                  x: 1,
                                  barRods: [
                                    BarChartRodData(
                                      toY: (membutuhkan as num).toDouble(),
                                      color: AppColors.warning,
                                      width: 30,
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                    ),
                                  ],
                                  showingTooltipIndicators: [0],
                                ),
                                BarChartGroupData(
                                  x: 2,
                                  barRods: [
                                    BarChartRodData(
                                      toY: (cukupMampu as num).toDouble(),
                                      color: AppColors.success,
                                      width: 30,
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                    ),
                                  ],
                                  showingTooltipIndicators: [0],
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Gagal memuat laporan: $error', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(adminStatsProvider),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(String title, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 12),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChartContainer(BuildContext context, {required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}
