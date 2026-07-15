import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/app_providers.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../auth/login_screen.dart';
import '../bantuan/bantuan_management_screen.dart';
import '../mahasiswa/admin_mahasiswa_screen.dart';
import '../verifikasi/verifikasi_screen.dart';
import 'admin_report_tab.dart';
import 'admin_profile_tab.dart';
import 'admin_pengajuan_list_screen.dart';
import '../../../data/models/app_models.dart';
import '../seleksi/admin_seleksi_screen.dart';
import '../seleksi/admin_penentuan_seleksi_screen.dart';
import '../../../core/network/websocket_service.dart';

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

final adminDashboardTabProvider = StateProvider<int>((ref) => 0);

class _AdminDashboardState extends ConsumerState<AdminDashboard> {
  late final List<ScrollController> _scrollControllers = List.generate(6, (_) => ScrollController());

  List<Widget> get _screens => const [
    _AdminDashboardTab(),
    VerifikasiScreen(),
    _AdminClusteringTab(),
    AdminSeleksiScreen(),
    AdminReportTab(),
    AdminProfileTab(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider).user;
      if (user != null) {
        ref.read(websocketServiceProvider).connect(user.id, context);
      }
    });
  }

  @override
  void dispose() {
    for (var c in _scrollControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(adminDashboardTabProvider);

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: _screens.asMap().entries.map((e) {
          return PrimaryScrollController(
            controller: _scrollControllers[e.key],
            child: e.value,
          );
        }).toList(),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurfaceVariant.withOpacity(0.9) : Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.1),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BottomNavigationBar(
                currentIndex: currentIndex,
                onTap: (i) {
                  if (currentIndex == i) {
                    if (_scrollControllers[i].hasClients) {
                      _scrollControllers[i].animateTo(
                        0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    }
                  } else {
                    ref.read(adminDashboardTabProvider.notifier).state = i;
                  }
                },
                type: BottomNavigationBarType.fixed,
                selectedItemColor: Theme.of(context).brightness == Brightness.dark ? AppColors.primaryLight : AppColors.primary,
                unselectedItemColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextSecondary : AppColors.textTertiary,
                backgroundColor: Colors.transparent,
                elevation: 0,
                showSelectedLabels: true,
                showUnselectedLabels: false,
                selectedLabelStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1.5,
                ),
                items: [
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.dashboard_outlined),
                    activeIcon: const Icon(Icons.dashboard_rounded),
                    label: ref.watch(localeProvider) == 'en' ? 'Dashboard' : 'Dashboard',
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.verified_outlined),
                    activeIcon: const Icon(Icons.verified_rounded),
                    label: ref.watch(localeProvider) == 'en' ? 'Verification' : 'Verifikasi',
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.analytics_outlined),
                    activeIcon: const Icon(Icons.analytics_rounded),
                    label: ref.watch(localeProvider) == 'en' ? 'Clustering' : 'Clustering',
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.fact_check_outlined),
                    activeIcon: const Icon(Icons.fact_check_rounded),
                    label: ref.watch(localeProvider) == 'en' ? 'Selection' : 'Seleksi',
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.pie_chart_outline_rounded),
                    activeIcon: const Icon(Icons.pie_chart_rounded),
                    label: ref.watch(localeProvider) == 'en' ? 'Reports' : 'Report',
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.person_outline_rounded),
                    activeIcon: const Icon(Icons.person_rounded),
                    label: ref.watch(localeProvider) == 'en' ? 'Profile' : 'Profil',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ===== ADMIN DASHBOARD TAB =====

class _AdminDashboardTab extends ConsumerWidget {
  const _AdminDashboardTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider(const (startDate: null, endDate: null)));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Consumer(
                          builder: (context, ref, _) {
                            final user = ref.watch(authProvider).user;
                            final name = user?.nama ?? 'Admin';
                            final photoUrl = user?.fotoProfil;
                            final fullPhotoUrl = (photoUrl != null && photoUrl.isNotEmpty) 
                                ? '${AppEndpoints.baseUrl}/$photoUrl' 
                                : null;
                            
                            return Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? AppColors.darkSurfaceVariant
                                        : Colors.grey.shade100,
                                    border: Border.all(
                                      color: Theme.of(context).dividerTheme.color ?? Colors.transparent,
                                    ),
                                    image: fullPhotoUrl != null
                                        ? DecorationImage(
                                            image: NetworkImage(fullPhotoUrl),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: fullPhotoUrl == null
                                      ? Icon(
                                          Icons.person_outline_rounded,
                                          color: Theme.of(context).iconTheme.color,
                                          size: 28,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Hello, $name',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                          color: Theme.of(context).textTheme.displayLarge?.color ?? AppColors.textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.2, end: 0, curve: Curves.easeOut),
                      Consumer(
                        builder: (context, ref, child) {
                          final unreadAsync = ref.watch(unreadCountProvider);
                          final unreadCount = unreadAsync.valueOrNull ?? 0;

                          return IconButton(
                            icon: Badge(
                              isLabelVisible: unreadCount > 0,
                              label: Text(unreadCount > 99 ? '99+' : unreadCount.toString(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                              backgroundColor: AppColors.error,
                              child: Icon(Icons.notifications_rounded, color: Theme.of(context).iconTheme.color),
                            ),
                            onPressed: () {
                              Navigator.of(context).pushNamed('/admin/notifikasi').then((_) {
                                ref.invalidate(unreadCountProvider);
                              });
                            },
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Berikut ringkasan terbaru dari sistem finansial pendidikan.',
                    style: TextStyle(
                      fontSize: 15,
                      color: Theme.of(context).textTheme.bodyMedium?.color ?? AppColors.textSecondary,
                    ),
                  ).animate(delay: 100.ms).fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0, curve: Curves.easeOut),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                statsAsync.when(
                  loading: () => Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: ShimmerLoading(height: 100, borderRadius: 16)),
                          const SizedBox(width: 12),
                          Expanded(child: ShimmerLoading(height: 100, borderRadius: 16)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: ShimmerLoading(height: 100, borderRadius: 16)),
                          const SizedBox(width: 12),
                          Expanded(child: ShimmerLoading(height: 100, borderRadius: 16)),
                        ],
                      ),
                    ],
                  ),
                  error: (e, _) => ErrorState(
                    message: e.toString(),
                    onRetry: () => ref.invalidate(adminStatsProvider),
                  ),
                  data: (stats) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Statistik Utama', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      Column(
                        children: [
                          SizedBox(
                            height: 140,
                            child: Row(
                              children: [
                                Expanded(
                                  child: _SquareStatCard(
                                    title: 'Total Mahasiswa',
                                    value: stats['total_mahasiswa']?.toString() ?? '0',
                                    icon: Icons.people_outline_rounded,
                                    color: AppColors.primary,
                                    onTap: () {
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminMahasiswaScreen()));
                                    },
                                  ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _SquareStatCard(
                                    title: 'Pengajuan Masuk',
                                    value: stats['total_menunggu']?.toString() ?? '0',
                                    icon: Icons.description_outlined,
                                    color: AppColors.secondary,
                                    onTap: () {
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => const VerifikasiScreen()));
                                    },
                                  ).animate(delay: 100.ms).fadeIn(duration: 400.ms).slideY(begin: 0.2),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 140,
                            child: Row(
                              children: [
                                Expanded(
                                  child: _SquareStatCard(
                                    title: 'Terverifikasi',
                                    value: stats['total_terverifikasi']?.toString() ?? '0',
                                    icon: Icons.check_circle_outline_rounded,
                                    color: AppColors.success,
                                    onTap: () {
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPengajuanListScreen(status: 'TERVERIFIKASI', title: 'Mahasiswa Terverifikasi')));
                                    },
                                  ).animate(delay: 200.ms).fadeIn(duration: 400.ms).slideY(begin: 0.2),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _SquareStatCard(
                                    title: 'Ditolak',
                                    value: stats['total_ditolak']?.toString() ?? '0',
                                    icon: Icons.highlight_off_rounded,
                                    color: AppColors.error,
                                    onTap: () {
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPengajuanListScreen(status: 'DITOLAK', title: 'Data Ditolak')));
                                    },
                                  ).animate(delay: 300.ms).fadeIn(duration: 400.ms).slideY(begin: 0.2),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 140,
                            width: double.infinity,
                            child: _SquareStatCard(
                              title: 'Direvisi',
                              value: stats['total_direvisi']?.toString() ?? '0',
                              icon: Icons.edit_note_rounded,
                              color: AppColors.warning,
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPengajuanListScreen(status: 'REVISI', title: 'Data Direvisi')));
                              },
                            ).animate(delay: 400.ms).fadeIn(duration: 400.ms).slideY(begin: 0.2),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                      Text('Grafik Status Pengajuan', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      _PengajuanBarChart(stats: stats),

                      const SizedBox(height: 24),
                      const _SystemOperations(),
                      const SizedBox(height: 24),

                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _PengajuanBarChart extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _PengajuanBarChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    final double menunggu = double.tryParse(stats['total_menunggu']?.toString() ?? '0') ?? 0;
    final double terverifikasi = double.tryParse(stats['total_terverifikasi']?.toString() ?? '0') ?? 0;
    final double ditolak = double.tryParse(stats['total_ditolak']?.toString() ?? '0') ?? 0;
    final double direvisi = double.tryParse(stats['total_direvisi']?.toString() ?? '0') ?? 0;

    final maxY = [menunggu, terverifikasi, ditolak, direvisi].reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.only(top: 24, bottom: 12, left: 16, right: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      child: SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxY > 0 ? maxY + (maxY * 0.2) : 10,
            barTouchData: BarTouchData(enabled: true),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (value, meta) {
                    final style = TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).textTheme.bodySmall?.color ?? AppColors.textSecondary,
                    );
                    String text;
                    switch (value.toInt()) {
                      case 0:
                        text = 'Masuk';
                        break;
                      case 1:
                        text = 'Diterima';
                        break;
                      case 2:
                        text = 'Ditolak';
                        break;
                      case 3:
                        text = 'Direvisi';
                        break;
                      default:
                        text = '';
                        break;
                    }
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      space: 4,
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
              BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: menunggu, color: AppColors.secondary, width: 24, borderRadius: BorderRadius.circular(4))]),
              BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: terverifikasi, color: AppColors.success, width: 24, borderRadius: BorderRadius.circular(4))]),
              BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: ditolak, color: AppColors.error, width: 24, borderRadius: BorderRadius.circular(4))]),
              BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: direvisi, color: AppColors.warning, width: 24, borderRadius: BorderRadius.circular(4))]),
            ],
          ),
        ),
      ),
    );
  }
}



// ===== ADMIN MANAJEMEN TAB =====

class _AdminManajemenTab extends StatelessWidget {
  const _AdminManajemenTab();

  @override
  Widget build(BuildContext context) {
    final menus = [
      {
        'title': 'Kelola Bantuan',
        'subtitle': 'Tambah, edit, hapus program bantuan',
        'icon': Icons.school_rounded,
        'color': AppColors.primary,
        'route': '/admin/bantuan',
      },
      {
        'title': 'Data Mahasiswa',
        'subtitle': 'Lihat dan kelola data mahasiswa',
        'icon': Icons.people_rounded,
        'color': AppColors.secondary,
        'route': '/admin/mahasiswa',
      },
      {
        'title': 'Data Finansial',
        'subtitle': 'Monitor data finansial mahasiswa',
        'icon': Icons.account_balance_wallet_rounded,
        'color': AppColors.warning,
        'route': '/admin/finansial',
      },
      {
        'title': 'Verifikasi Pengajuan',
        'subtitle': 'Review dan verifikasi pengajuan bantuan',
        'icon': Icons.verified_rounded,
        'color': AppColors.success,
        'route': '/admin/verifikasi',
      },
      {
        'title': 'Hasil Seleksi',
        'subtitle': 'Lihat dan tetapkan kelayakan',
        'icon': Icons.workspace_premium_rounded,
        'color': AppColors.accent,
        'route': '/admin/seleksi',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Sistem', style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: false,
        elevation: 0,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
        itemCount: menus.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (_, i) {
          final menu = menus[i];
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? AppColors.darkOutline : AppColors.outlineVariant),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.of(context).pushNamed(menu['route'] as String),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: (menu['color'] as Color).withOpacity(isDark ? 0.2 : 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          menu['icon'] as IconData,
                          color: isDark ? (menu['color'] as Color).withAlpha(200) : menu['color'] as Color,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              menu['title'] as String,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              menu['subtitle'] as String,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.arrow_forward_rounded, color: isDark ? AppColors.darkTextSecondary : AppColors.textTertiary, size: 20),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ).animate(delay: Duration(milliseconds: i * 80)).fadeIn(duration: 400.ms).slideX(begin: 0.1, duration: 400.ms, curve: Curves.easeOut);
        },
      ),
    );
  }
}

// ===== ADMIN CLUSTERING TAB =====

class _AdminClusteringTab extends ConsumerStatefulWidget {
  const _AdminClusteringTab();

  @override
  ConsumerState<_AdminClusteringTab> createState() => _AdminClusteringTabState();
}

class _AdminClusteringTabState extends ConsumerState<_AdminClusteringTab> {
  int _nClusters = 3;
  double _eps = 0.5;
  int _minSamples = 3;
  bool _isRunning = false;

  String _historySortOrder = 'terbaru';
  String _historyFilterAlgo = 'semua';

  // State untuk filtering dan pagination data anggota cluster
  String _searchQuery = '';
  String _filterKategori = 'Semua';
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  
  // State untuk Data Siap Clustering
  String _verifiedSearchQuery = '';
  int _verifiedCurrentPage = 1;
  final int _verifiedItemsPerPage = 10;

  Future<void> _runClustering() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Jalankan Clustering?'),
        content: const Text(
          'Proses clustering akan menganalisis data finansial mahasiswa yang telah terverifikasi.\n\nHasil clustering sebelumnya akan diganti.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Jalankan'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isRunning = true);
    try {
      await ref.read(clusteringRepositoryProvider).runClustering(
            nClusters: _nClusters,
            eps: _eps,
            minSamples: _minSamples,
          );

      ref.invalidate(clusteringResultsProvider);
      ref.invalidate(adminStatsProvider);
      ref.invalidate(clusteringHistoryProvider);
      ref.invalidate(allPengajuanProvider(const {'status': 'TERVERIFIKASI', 'per_page': 5000}));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Clustering selesai! Data berhasil dikelompokkan.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRunning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final resultsAsync = ref.watch(clusteringResultsProvider);
    final verifiedAsync = ref.watch(allPengajuanProvider(const {'status': 'TERVERIFIKASI', 'per_page': 5000}));
    final seleksiAsync = ref.watch(seleksiListProvider(const {'page': 1, 'per_page': 100}));
    final seleksiList = seleksiAsync.when(
      data: (data) => (data['items'] as List?) ?? [],
      loading: () => [],
      error: (_, __) => [],
    );
    final historyAsync = ref.watch(clusteringHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Clustering ML')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(clusteringResultsProvider);
          ref.invalidate(allPengajuanProvider(const {'status': 'TERVERIFIKASI', 'per_page': 5000}));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Configuration Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '⚙️ Konfigurasi Clustering',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // K-Means clusters
                    _buildConfigRow(
                      context: context,
                      label: 'K-Means Clusters',
                      value: _nClusters.toString(),
                      onDecrease: () => setState(() {
                        if (_nClusters > 2) _nClusters--;
                      }),
                      onIncrease: () => setState(() {
                        if (_nClusters < 3) _nClusters++;
                      }),
                    ),
                    const SizedBox(height: 12),

                    // DBSCAN eps
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'DBSCAN Epsilon',
                          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
                        ),
                        Text(
                          _eps.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: const SliderThemeData(
                        activeTrackColor: Colors.white,
                        thumbColor: Colors.white,
                        inactiveTrackColor: Colors.white24,
                        overlayColor: Colors.white24,
                      ),
                      child: Slider(
                        value: _eps,
                        min: 0.1,
                        max: 3.0,
                        divisions: 29,
                        onChanged: (v) => setState(() => _eps = v),
                      ),
                    ),

                    const SizedBox(height: 16),
                    Builder(
                      builder: (ctx) {
                        final isVerifiedLoaded = verifiedAsync.hasValue;
                        final verifiedCount = verifiedAsync.value?['total'] ?? 0;
                        final isDataSufficient = verifiedCount >= 30;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isVerifiedLoaded && !isDataSufficient)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.red.withOpacity(0.5)),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.info_outline, color: Colors.white, size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Jumlah data belum mencukupi. Minimal 30 data mahasiswa terverifikasi untuk menjalankan proses clustering (Saat ini: $verifiedCount).',
                                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            AppButton(
                              label: _isRunning ? 'Memproses...' : 'Jalankan Clustering',
                              onPressed: (_isRunning || !isVerifiedLoaded || !isDataSufficient) ? null : _runClustering,
                              isLoading: _isRunning,
                              color: Colors.white,
                            ),
                          ],
                        );
                      }
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 500.ms),

              const SizedBox(height: 24),

              // Daftar Mahasiswa Terverifikasi
              Text('Data Siap Clustering (Terverifikasi)', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Cari nama atau NIM...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurface : Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                onChanged: (val) {
                  setState(() {
                    _verifiedSearchQuery = val;
                    _verifiedCurrentPage = 1;
                  });
                },
              ),
              const SizedBox(height: 12),
              verifiedAsync.when(
                loading: () => const ShimmerList(count: 3),
                error: (e, _) => ErrorState(
                  message: 'Gagal memuat data: $e',
                  onRetry: () => ref.invalidate(allPengajuanProvider(const {'status': 'TERVERIFIKASI', 'per_page': 5000})),
                ),
                data: (data) {
                  var list = (data['items'] as List?)?.cast<PengajuanModel>() ?? [];
                  
                  if (_verifiedSearchQuery.isNotEmpty) {
                    final query = _verifiedSearchQuery.toLowerCase();
                    list = list.where((p) {
                      final nama = (p.mahasiswaNama ?? '').toLowerCase();
                      final nim = (p.mahasiswaNim ?? '').toLowerCase();
                      return nama.contains(query) || nim.contains(query);
                    }).toList();
                  }

                  if (list.isEmpty) {
                    return const EmptyState(
                      title: 'Belum Ada Data',
                      subtitle: 'Belum ada mahasiswa atau tidak ada hasil pencarian.',
                      icon: Icons.group_off_outlined,
                    );
                  }
                  
                  final totalItems = list.length;
                  final totalPages = (totalItems / _verifiedItemsPerPage).ceil();

                  if (_verifiedCurrentPage > totalPages && totalPages > 0) {
                    _verifiedCurrentPage = totalPages;
                  } else if (_verifiedCurrentPage < 1) {
                    _verifiedCurrentPage = 1;
                  }

                  final startIndex = (_verifiedCurrentPage - 1) * _verifiedItemsPerPage;
                  final endIndex = (startIndex + _verifiedItemsPerPage > totalItems) ? totalItems : startIndex + _verifiedItemsPerPage;
                  final paginatedList = startIndex < totalItems ? list.sublist(startIndex, endIndex) : <PengajuanModel>[];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          'Total Mahasiswa Siap: $totalItems data',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardTheme.color,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.outline),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: paginatedList.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final p = paginatedList[i];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.success.withOpacity(0.1),
                                child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                              ),
                              title: Text(p.mahasiswaNama ?? 'Mahasiswa', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('NIM: ${p.mahasiswaNim ?? '-'}', style: const TextStyle(fontSize: 12)),
                                  Text(p.bantuanNama ?? '', style: const TextStyle(fontSize: 11, color: AppColors.primary)),
                                ],
                              ),
                              trailing: const Text('TERVERIFIKASI', style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.bold)),
                            );
                          },
                        ),
                      ),
                      if (totalPages > 1) ...[
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left),
                              onPressed: _verifiedCurrentPage > 1 ? () => setState(() => _verifiedCurrentPage--) : null,
                            ),
                            Text('Halaman $_verifiedCurrentPage dari $totalPages', style: Theme.of(context).textTheme.bodySmall),
                            IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed: _verifiedCurrentPage < totalPages ? () => setState(() => _verifiedCurrentPage++) : null,
                            ),
                          ],
                        ),
                      ],
                    ],
                  );
                },
              ),

              const SizedBox(height: 24),

              // Results
              Text('Hasil Clustering', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),

              resultsAsync.when(
                loading: () => const ShimmerList(count: 4),
                error: (e, _) => ErrorState(
                  message: 'Belum ada hasil clustering. Jalankan clustering terlebih dahulu.',
                  onRetry: () => ref.invalidate(clusteringResultsProvider),
                ),
                data: (result) {
                  if (result.kmeansEvaluasi == null && result.dbscanEvaluasi == null) {
                    return const EmptyState(
                      title: 'Belum Ada Hasil',
                      subtitle: 'Jalankan clustering untuk melihat hasilnya',
                      icon: Icons.analytics_outlined,
                    );
                  }

                  return Column(
                    children: [
                      // K-Means Results
                      if (result.kmeansEvaluasi != null)
                        _buildEvaluasiCard(
                          context: context,
                          title: 'K-Means Clustering',
                          evaluasi: result.kmeansEvaluasi!,
                          stats: result.kmeansStats,
                          icon: Icons.bubble_chart_rounded,
                          color: AppColors.primary,
                          onTap: () {
                            _showDetailKMeansDialog(context, result.kmeansEvaluasi!, result.kmeansStats);
                          },
                        ),

                      const SizedBox(height: 16),

                      // DBSCAN Results
                      if (result.dbscanEvaluasi != null)
                        _buildEvaluasiCard(
                          context: context,
                          title: 'DBSCAN Clustering',
                          evaluasi: result.dbscanEvaluasi!,
                          stats: result.dbscanStats,
                          icon: Icons.scatter_plot_rounded,
                          color: AppColors.secondary,
                          outliers: result.outliers,
                          showMetrics: false,
                          onTap: () {
                            _showDbscanMembersDialog(context, result.members, result.outliers);
                          },
                        ),

                      const SizedBox(height: 24),
                      
                      // Plots section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Visualisasi Hasil (PCA 2D)', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildImageCard(
                                  context, 
                                  'K-Means', 
                                  '${AppEndpoints.baseUrl}/uploads/kmeans_plot.png?t=${DateTime.now().millisecondsSinceEpoch}'
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildImageCard(
                                  context, 
                                  'DBSCAN', 
                                  '${AppEndpoints.baseUrl}/uploads/dbscan_outliers.png?t=${DateTime.now().millisecondsSinceEpoch}'
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Members
                      if (result.members.isNotEmpty) ...[
                        Text(
                          'Anggota Cluster (${result.members.length})',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        // Filter & Search UI
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: 'Cari Nama atau NIM...',
                                  prefixIcon: const Icon(Icons.search, size: 20),
                                  isDense: true,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                                onChanged: (val) {
                                  setState(() {
                                    _searchQuery = val;
                                    _currentPage = 1;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 1,
                              child: DropdownButtonFormField<String>(
                                value: _filterKategori,
                                isDense: true,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                style: Theme.of(context).textTheme.bodyMedium,
                                items: const [
                                  DropdownMenuItem(value: 'Semua', child: Text('Semua', style: TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                                  DropdownMenuItem(value: 'Cukup Mampu', child: Text('Cukup Mampu', style: TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                                  DropdownMenuItem(value: 'Membutuhkan', child: Text('Membutuhkan', style: TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                                  DropdownMenuItem(value: 'Sangat Membutuhkan', child: Text('Sangat Membutuhkan', style: TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _filterKategori = val;
                                      _currentPage = 1;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Builder(
                          builder: (context) {
                            var filteredMembers = result.members.where((m) {
                              final matchSearch = m.mahasiswaNama.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                                                  m.mahasiswaNim.toLowerCase().contains(_searchQuery.toLowerCase());
                              final normalizedKategori = m.kmeansKategori.toLowerCase().replaceAll('_', ' ');
                              final normalizedFilter = _filterKategori.toLowerCase().replaceAll('_', ' ');
                              final matchKategori = _filterKategori == 'Semua' || 
                                                    normalizedKategori.contains(normalizedFilter);
                              return matchSearch && matchKategori;
                            }).toList();
                            
                            if (filteredMembers.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(child: Text('Tidak ada anggota yang sesuai filter.', style: TextStyle(color: Colors.grey))),
                              );
                            }

                            int totalPages = (filteredMembers.length / _itemsPerPage).ceil();
                            var paginatedMembers = filteredMembers.skip((_currentPage - 1) * _itemsPerPage).take(_itemsPerPage).toList();

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                ...paginatedMembers.map((m) {
                                  final seleksiDataRaw = seleksiList.where((s) => s['pengajuan_id'] == m.pengajuanId).toList();
                                  final isSeleksiDone = seleksiDataRaw.isNotEmpty;
                                  final seleksiData = isSeleksiDone ? seleksiDataRaw.first : null;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Material(
                                    color: Theme.of(context).cardTheme.color,
                                    borderRadius: BorderRadius.circular(12),
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
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: AppColors.outline),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 36,
                                              height: 36,
                                              decoration: BoxDecoration(
                                                color: AppColors.primaryContainer,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(Icons.person_rounded,
                                                  size: 18, color: AppColors.primary),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(m.mahasiswaNama,
                                                      style: Theme.of(context).textTheme.titleSmall),
                                                  Text(m.mahasiswaNim,
                                                      style: Theme.of(context).textTheme.bodySmall),
                                                ],
                                              ),
                                            ),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                KategoriBadge(kategori: m.kmeansKategori),
                                                if (isSeleksiDone) ...[
                                                  const SizedBox(height: 4),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: seleksiData['kelayakan'] == 'LAYAK' ? AppColors.success.withOpacity(0.1) : 
                                                             seleksiData['kelayakan'] == 'TIDAK_LAYAK' ? AppColors.error.withOpacity(0.1) : 
                                                             AppColors.warning.withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      seleksiData['kelayakan'] == 'LAYAK' ? 'DITERIMA' :
                                                      seleksiData['kelayakan'] == 'TIDAK_LAYAK' ? 'DITOLAK' : 'DIPERTIMBANGKAN',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold,
                                                        color: seleksiData['kelayakan'] == 'LAYAK' ? AppColors.success : 
                                                               seleksiData['kelayakan'] == 'TIDAK_LAYAK' ? AppColors.error : AppColors.warning,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                                }).toList(),
                                
                                // Pagination Controls
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
                                ],
                              ],
                            );
                          },
                        ),
                      ],
                    ],
                  );
                },
              ),

              const SizedBox(height: 32),

              // Riwayat Clustering Header & Filter
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Riwayat Clustering', style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        border: Border.all(color: AppColors.outline),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _historySortOrder,
                          isExpanded: true,
                          icon: const Icon(Icons.sort_rounded, size: 20),
                          items: const [
                            DropdownMenuItem(value: 'terbaru', child: Text('Terbaru', style: TextStyle(fontSize: 13))),
                            DropdownMenuItem(value: 'terlama', child: Text('Terlama', style: TextStyle(fontSize: 13))),
                          ],
                          onChanged: (v) {
                            if (v != null) setState(() => _historySortOrder = v);
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        border: Border.all(color: AppColors.outline),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _historyFilterAlgo,
                          isExpanded: true,
                          icon: const Icon(Icons.filter_alt_outlined, size: 20),
                          items: const [
                            DropdownMenuItem(value: 'semua', child: Text('Semua Algoritma', style: TextStyle(fontSize: 13))),
                            DropdownMenuItem(value: 'kmeans', child: Text('K-Means', style: TextStyle(fontSize: 13))),
                            DropdownMenuItem(value: 'dbscan', child: Text('DBSCAN', style: TextStyle(fontSize: 13))),
                          ],
                          onChanged: (v) {
                            if (v != null) setState(() => _historyFilterAlgo = v);
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              historyAsync.when(
                loading: () => const ShimmerList(count: 3),
                error: (e, _) => Text('Gagal memuat riwayat: $e', style: const TextStyle(color: AppColors.error)),
                data: (history) {
                  if (history.isEmpty) {
                    return const EmptyState(
                      title: 'Belum Ada Riwayat',
                      subtitle: 'Riwayat proses clustering akan muncul di sini',
                      icon: Icons.history_rounded,
                    );
                  }

                  // Apply Filter
                  List filteredHistory = history.where((item) {
                    if (_historyFilterAlgo == 'semua') return true;
                    final algo = (item['algoritma'] as String?)?.toLowerCase() ?? '';
                    return algo == _historyFilterAlgo;
                  }).toList();

                  // Apply Sort
                  filteredHistory.sort((a, b) {
                    final dateA = DateTime.tryParse(a['created_at'].toString()) ?? DateTime.fromMillisecondsSinceEpoch(0);
                    final dateB = DateTime.tryParse(b['created_at'].toString()) ?? DateTime.fromMillisecondsSinceEpoch(0);
                    if (_historySortOrder == 'terbaru') {
                      return dateB.compareTo(dateA);
                    } else {
                      return dateA.compareTo(dateB);
                    }
                  });

                  if (filteredHistory.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Center(
                        child: Text('Tidak ada riwayat yang sesuai dengan filter', style: TextStyle(color: Colors.grey)),
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredHistory.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final item = filteredHistory[i];
                      final date = DateTime.tryParse(item['created_at'].toString())?.toLocal() ?? DateTime.now();
                      final isKMeans = (item['algoritma'] as String?)?.toLowerCase() == 'kmeans';
                      
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _showHistoryDetailDialog(context, item),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardTheme.color,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.outline),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: (isKMeans ? AppColors.primary : AppColors.secondary).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    isKMeans ? Icons.bubble_chart_rounded : Icons.scatter_plot_rounded,
                                    color: isKMeans ? AppColors.primary : AppColors.secondary,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['algoritma']?.toString().toUpperCase() ?? 'KMEANS',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.access_time_rounded, size: 12, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
                                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Score: ${(double.tryParse(item['silhouette_score'].toString()) ?? 0.0).toStringAsFixed(3)}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.success),
                                    ),
                                    Text(
                                      '${item['n_clusters']} Clusters',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }


  void _showHistoryDetailDialog(BuildContext context, Map<String, dynamic> item) {
    final date = DateTime.tryParse(item['created_at'].toString())?.toLocal() ?? DateTime.now();
    final isKMeans = (item['algoritma'] as String?)?.toLowerCase() == 'kmeans';
    final color = isKMeans ? AppColors.primary : AppColors.secondary;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(isKMeans ? Icons.bubble_chart_rounded : Icons.scatter_plot_rounded, color: color),
            const SizedBox(width: 8),
            Text('Detail ${item['algoritma']?.toString().toUpperCase()}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Waktu Eksekusi: ${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 16),
              const Text('Metrik Evaluasi', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Silhouette Score: ${(double.tryParse(item['silhouette_score'].toString()) ?? 0.0).toStringAsFixed(4)}'),
              Text('Davies-Bouldin Index: ${(double.tryParse(item['davies_bouldin_index'].toString()) ?? 0.0).toStringAsFixed(4)}'),
              Text('Jumlah Cluster: ${item['n_clusters']}'),
              Text('Total Data Diproses: ${item['total_data']}'),
              if (!isKMeans) Text('Total Outlier (Noise): ${item['total_outlier'] ?? 0}'),
              if (item['params'] != null) ...[
                const SizedBox(height: 16),
                const Text('Parameter Digunakan', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(item['params'].toString()),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showImageDialog(BuildContext context, String title, String url) {
    showDialog(
      context: context,
      builder: (ctx) => _ImageDialog(title: title, url: url),
    );
  }

  Widget _buildImageCard(BuildContext context, String title, String url) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showImageDialog(context, title, url),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.outline),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(width: 4),
                    const Icon(Icons.zoom_in, size: 14, color: AppColors.textSecondary),
                  ],
                ),
              ),
              ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                child: Image.network(
                  url,
                  fit: BoxFit.cover,
                  height: 150,
                  width: double.infinity,
                  errorBuilder: (ctx, err, stack) => Container(
                    height: 150,
                    color: Colors.grey.withOpacity(0.1),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image_not_supported_outlined, color: Colors.grey),
                          SizedBox(height: 4),
                          Text('Gambar belum ada', style: TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Old _showOutliersDialog removed to prevent confusion

  void _showDbscanMembersDialog(BuildContext context, List<ClusterMember> allMembers, List<ClusterOutlier> outliers) {
    // Cari normal members dan outlier members dari allMembers (agar kita punya pengajuanId)
    final outlierIds = outliers.map((o) => o.mahasiswaId).toSet();
    final allNormalMembers = allMembers.where((m) => !outlierIds.contains(m.mahasiswaId)).toList();
    final allOutlierMembers = allMembers.where((m) => outlierIds.contains(m.mahasiswaId)).toList();

    showDialog(
      context: context,
      builder: (ctx) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setState) {
            final normalMembers = allNormalMembers.where((m) => 
                m.mahasiswaNama.toLowerCase().contains(searchQuery.toLowerCase()) || 
                m.mahasiswaNim.toLowerCase().contains(searchQuery.toLowerCase())
            ).toList();
            
            final outlierMembers = allOutlierMembers.where((m) => 
                m.mahasiswaNama.toLowerCase().contains(searchQuery.toLowerCase()) || 
                m.mahasiswaNim.toLowerCase().contains(searchQuery.toLowerCase())
            ).toList();

            return DefaultTabController(
              length: 2,
              child: AlertDialog(
                title: Row(
                  children: [
                    const Icon(Icons.scatter_plot_rounded, color: AppColors.secondary),
                    const SizedBox(width: 8),
                    const Text('Data Mahasiswa DBSCAN', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                content: Container(
                  width: double.maxFinite,
                  constraints: const BoxConstraints(maxHeight: 600),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Cari Nama atau NIM...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        onChanged: (val) {
                          setState(() {
                            searchQuery = val;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      const TabBar(
                        labelColor: AppColors.primary,
                        unselectedLabelColor: Colors.grey,
                        tabs: [
                          Tab(text: 'Normal Data'),
                          Tab(text: 'Outlier'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: TabBarView(
                          children: [
                            // Tab Normal Data
                            normalMembers.isEmpty
                                ? const Center(child: Text('Tidak ada Normal Data', style: TextStyle(color: Colors.grey)))
                                : ListView.separated(
                                    shrinkWrap: true,
                                    itemCount: normalMembers.length,
                                    separatorBuilder: (_, __) => const Divider(height: 1),
                                    itemBuilder: (ctx, i) {
                                      final m = normalMembers[i];
                                      return ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        title: Text(m.mahasiswaNama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                        subtitle: Text('NIM: ${m.mahasiswaNim}', style: const TextStyle(fontSize: 12)),
                                        trailing: const Icon(Icons.chevron_right, size: 20),
                                        onTap: () {
                                          if (m.pengajuanId == null) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('ID Pengajuan tidak ditemukan')),
                                            );
                                            return;
                                          }
                                          Navigator.pop(ctx);
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
                                      );
                                    },
                                  ),
                            // Tab Outlier
                            outlierMembers.isEmpty
                                ? const Center(child: Text('Tidak ada Outlier', style: TextStyle(color: Colors.grey)))
                                : ListView.separated(
                                    shrinkWrap: true,
                                    itemCount: outlierMembers.length,
                                    separatorBuilder: (_, __) => const Divider(height: 1),
                                    itemBuilder: (ctx, i) {
                                      final m = outlierMembers[i];
                                      return ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        title: Text(m.mahasiswaNama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                        subtitle: Text('NIM: ${m.mahasiswaNim}', style: const TextStyle(fontSize: 12)),
                                        trailing: const Icon(Icons.chevron_right, size: 20),
                                        onTap: () {
                                          if (m.pengajuanId == null) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('ID Pengajuan tidak ditemukan')),
                                            );
                                            return;
                                          }
                                          Navigator.pop(ctx);
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
                                      );
                                    },
                                  ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showDetailKMeansDialog(BuildContext context, EvaluasiModel evaluasi, List<ClusterStats> stats) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.bubble_chart_rounded, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text('Detail K-Means', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Waktu Eksekusi: ${evaluasi.createdAt}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 16),
            const Text('Metrik Evaluasi', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Silhouette Score: ${evaluasi.silhouetteScore.toStringAsFixed(4)}'),
            Text('Davies-Bouldin Index: ${evaluasi.daviesBouldinIndex.toStringAsFixed(4)}'),
            Text('Total Data Diproses: ${evaluasi.totalData}'),
            const SizedBox(height: 16),
            const Text('Distribusi Cluster', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...stats.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Cluster ${s.clusterId}:', style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('${s.kategori.toUpperCase()} - ${s.total} (${s.percentage}%)'),
                      ),
                    ],
                  ),
                )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }


  Widget _buildConfigRow({
    required BuildContext context,
    required String label,
    required String value,
    required VoidCallback onDecrease,
    required VoidCallback onIncrease,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
        ),
        Row(
          children: [
            IconButton(
              onPressed: onDecrease,
              icon: const Icon(Icons.remove_circle_outline, color: Colors.white),
              iconSize: 22,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: onIncrease,
              icon: const Icon(Icons.add_circle_outline, color: Colors.white),
              iconSize: 22,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEvaluasiCard({
    required BuildContext context,
    required String title,
    required dynamic evaluasi,
    required List stats,
    required IconData icon,
    required Color color,
    List<ClusterOutlier>? outliers,
    VoidCallback? onTap,
    bool showMetrics = true,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title, style: Theme.of(context).textTheme.titleSmall),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (showMetrics) ...[
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    label: 'Silhouette',
                    value: evaluasi.silhouetteScore.toStringAsFixed(4),
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MetricCard(
                    label: 'Davies-Bouldin',
                    value: evaluasi.daviesBouldinIndex.toStringAsFixed(4),
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MetricCard(
                    label: 'Clusters',
                    value: evaluasi.nClusters.toString(),
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          if (stats.isNotEmpty) ...[
            if (showMetrics) const Divider(),
            const SizedBox(height: 8),
            ...stats.map((s) {
              final kategori = s.kategori as String;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    KategoriBadge(kategori: kategori),
                    const Spacer(),
                    Text(
                      '${s.total} mahasiswa',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${s.percentage}%',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: color,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          if (outliers != null && outliers.isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.scatter_plot_rounded, size: 18),
                label: Text('Lihat Detail Mahasiswa'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error.withOpacity(0.1),
                  foregroundColor: AppColors.error,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: AppColors.error),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Theme.of(context).textTheme.bodySmall?.color ?? AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}


class _SquareStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _SquareStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.4), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: color,
                        height: 1.2,
                      ),
                    ),
                  ),
                  Icon(icon, size: 22, color: color),
                ],
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).textTheme.displayLarge?.color ?? AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}





class _SystemOperations extends ConsumerWidget {
  const _SystemOperations();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final operations = [
      {
        'title': 'Data Mahasiswa',
        'subtitle': 'Kelola profil mahasiswa dan catatan dasar',
        'icon': Icons.person_outline,
        'route': '/admin/mahasiswa',
      },
      {
        'title': 'Data Finansial',
        'subtitle': 'Tinjau pendapatan dan latar belakang ekonomi',
        'icon': Icons.account_balance_wallet_outlined,
        'route': '/admin/finansial',
      },
      {
        'title': 'Data Bantuan Pendidikan',
        'subtitle': 'Alokasi beasiswa dan bantuan saat ini',
        'icon': Icons.school_outlined,
        'route': '/admin/bantuan',
      },
      {
        'title': 'Verifikasi Pengajuan',
        'subtitle': 'Proses pengajuan bantuan yang tertunda',
        'icon': Icons.verified_outlined,
        'route': '/admin/verifikasi',
      },
      {
        'title': 'Proses Clustering',
        'subtitle': 'Jalankan model pengelompokan algoritmik',
        'icon': Icons.bubble_chart_outlined,
        'route': '/admin/clustering',
      },
      {
        'title': 'Hasil Seleksi',
        'subtitle': 'Lihat hasil akhir kategorisasi kelayakan',
        'icon': Icons.bar_chart_outlined,
        'route': '/admin/seleksi',
      },
      {
        'title': 'Laporan',
        'subtitle': 'Buat laporan statistik komprehensif',
        'icon': Icons.pie_chart_outline,
        'route': '/admin/laporan',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Operasi Sistem',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).textTheme.titleLarge?.color ?? AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        ...operations.map((op) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () {
                if (op['route'] == '/admin/clustering') {
                  ref.read(adminDashboardTabProvider.notifier).state = 2; // Index 2 is Clustering
                } else if (op['route'] == '/admin/verifikasi') {
                  ref.read(adminDashboardTabProvider.notifier).state = 1; // Index 1 is Verifikasi
                } else if (op['route'] == '/admin/seleksi') {
                  ref.read(adminDashboardTabProvider.notifier).state = 3; // Index 3 is Seleksi
                } else if (op['route'] != null) {
                  Navigator.pushNamed(context, op['route'] as String);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Fitur dalam pengembangan atau buka tab terkait: ${op['title']}')),
                  );
                }
              },
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  border: Border.all(color: isDark ? AppColors.darkOutline : Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceVariant : Colors.grey.shade50,
                        border: Border.all(color: isDark ? AppColors.darkOutline : Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(op['icon'] as IconData, size: 24, color: Theme.of(context).iconTheme.color ?? AppColors.textPrimary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            op['title'] as String,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).textTheme.titleMedium?.color ?? AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            op['subtitle'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).textTheme.bodySmall?.color ?? AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.textTertiary),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}

class _ImageDialog extends StatefulWidget {
  final String title;
  final String url;

  const _ImageDialog({required this.title, required this.url});

  @override
  State<_ImageDialog> createState() => _ImageDialogState();
}

class _ImageDialogState extends State<_ImageDialog> {
  final TransformationController _controller = TransformationController();

  void _zoomIn() {
    setState(() {
      _controller.value = _controller.value.clone()..scale(1.5);
    });
  }

  void _zoomOut() {
    setState(() {
      _controller.value = _controller.value.clone()..scale(0.67);
    });
  }

  void _resetZoom() {
    setState(() {
      _controller.value = Matrix4.identity();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: Theme.of(context).cardTheme.color,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.download_rounded),
                            tooltip: 'Unduh / Buka Gambar',
                            onPressed: () async {
                              final uri = Uri.parse(widget.url);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              } else {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Gagal membuka tautan unduhan')),
                                  );
                                }
                              }
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 16),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: InteractiveViewer(
                    transformationController: _controller,
                    panEnabled: true,
                    minScale: 0.2,
                    maxScale: 5.0,
                    child: Image.network(
                      widget.url,
                      fit: BoxFit.contain,
                      errorBuilder: (c, e, s) => const Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text('Gambar gagal dimuat', style: TextStyle(color: Colors.grey)),
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Theme.of(context).cardTheme.color,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: AppColors.primary, size: 28),
                        onPressed: _zoomOut,
                        tooltip: 'Zoom Out',
                      ),
                      const SizedBox(width: 24),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: AppColors.textSecondary, size: 28),
                        onPressed: _resetZoom,
                        tooltip: 'Reset Zoom',
                      ),
                      const SizedBox(width: 24),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, color: AppColors.primary, size: 28),
                        onPressed: _zoomIn,
                        tooltip: 'Zoom In',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
