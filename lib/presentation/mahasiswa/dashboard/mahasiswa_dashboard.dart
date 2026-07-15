import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/app_providers.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../auth/login_screen.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/network/websocket_service.dart';
import '../pengajuan/pengajuan_detail_screen.dart';
import 'package:intl/intl.dart';
import '../../../data/models/app_models.dart';
class MahasiswaDashboard extends ConsumerStatefulWidget {
  const MahasiswaDashboard({super.key});

  @override
  ConsumerState<MahasiswaDashboard> createState() => _MahasiswaDashboardState();
}

class _MahasiswaDashboardState extends ConsumerState<MahasiswaDashboard> {
  int _currentIndex = 0;
  late final List<ScrollController> _scrollControllers = List.generate(6, (_) => ScrollController());


  late final List<Widget> _screens = [
    _DashboardTab(onNavigateTab: (index) => setState(() => _currentIndex = index)),
    const _DataMahasiswaTab(),
    const _DataFinansialTab(),
    const _PengajuanTab(),
    const _NotifikasiTab(),
    const _ProfileTab(),
  ];

  @override
  void initState() {
    super.initState();
    // Connect WebSocket after build is complete to get access to context
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      extendBody: true, // Allow content to flow behind the floating nav bar
      body: IndexedStack(
        index: _currentIndex,
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
              color: isDark ? AppColors.darkSurfaceVariant.withOpacity(0.9) : Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(isDark ? 0.2 : 0.1),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (i) {
                  if (_currentIndex == i) {
                    if (_scrollControllers[i].hasClients) {
                      _scrollControllers[i].animateTo(
                        0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    }
                  } else {
                    setState(() => _currentIndex = i);
                  }
                },
                type: BottomNavigationBarType.fixed,
                selectedItemColor: isDark ? AppColors.primaryLight : AppColors.primary,
                unselectedItemColor: isDark ? AppColors.darkTextSecondary : AppColors.textTertiary,
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
                    icon: const Icon(Icons.home_outlined),
                    activeIcon: const Icon(Icons.home_rounded),
                    label: ref.watch(localeProvider) == 'en' ? 'Dashboard' : 'Beranda',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.assignment_ind_outlined),
                    activeIcon: Icon(Icons.assignment_ind_rounded),
                    label: 'Mahasiswa',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.account_balance_wallet_outlined),
                    activeIcon: Icon(Icons.account_balance_wallet_rounded),
                    label: 'Finansial',
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.description_outlined),
                    activeIcon: const Icon(Icons.description_rounded),
                    label: ref.watch(localeProvider) == 'en' ? 'Submissions' : 'Pengajuan',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.notifications_outlined),
                    activeIcon: Icon(Icons.notifications_rounded),
                    label: 'Notifikasi',
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

// ===== DASHBOARD TAB =====

class _DashboardTab extends ConsumerWidget {
  final Function(int) onNavigateTab;
  const _DashboardTab({super.key, required this.onNavigateTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final profileAsync = ref.watch(myProfileProvider);
    final finansialAsync = ref.watch(myFinansialProvider);
    final pengajuanAsync = ref.watch(myPengajuanProvider);
    final seleksiAsync = ref.watch(mySeleksiProvider);
    final deletedIds = ref.watch(deletedPengajuanProvider);

    // Calculate Progress
    int stepsCompleted = 0;
    int totalSteps = 4;
    
    // Step 1: Profile completed (Basic data filled)
    if (profileAsync.value != null && profileAsync.value!.nama.isNotEmpty) {
      stepsCompleted++;
    }
    
    // Step 2: Finansial completed
    if (finansialAsync.value != null) {
      stepsCompleted++;
    }

    // Step 3: Pengajuan submitted
    bool hasActivePengajuan = false;
    if (pengajuanAsync.value != null) {
      final activePengajuan = pengajuanAsync.value!.where((p) => !deletedIds.contains(p.id)).toList();
      if (activePengajuan.isNotEmpty) {
        hasActivePengajuan = true;
        stepsCompleted++;
      }
    }

    // Step 4: Verification/Selection completed (Diterima/Ditolak/Layak)
    if (hasActivePengajuan) {
      bool sCompleted = false;
      
      // Cek dari API backend
      if (seleksiAsync.value != null && seleksiAsync.value!.isNotEmpty) {
        sCompleted = seleksiAsync.value!.any((s) => s['kelayakan'] == 'LAYAK');
      }

      if (sCompleted) {
        stepsCompleted++;
      }
    }

    double progressPercent = stepsCompleted / totalSteps;
    String statusBadge = stepsCompleted == totalSteps ? "COMPLETED" : "IN PROGRESS";
    Color badgeColor = stepsCompleted == totalSteps ? AppColors.success : (Theme.of(context).brightness == Brightness.dark ? AppColors.primary : Colors.black);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Profil
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: Theme.of(context).dividerTheme.color ?? Colors.grey.shade200),
                      image: authState.user?.fotoProfil != null && authState.user!.fotoProfil!.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage('${AppEndpoints.baseUrl}/${authState.user!.fotoProfil}'),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: authState.user?.fotoProfil == null || authState.user!.fotoProfil!.isEmpty
                        ? Icon(Icons.person_outline_rounded, color: Theme.of(context).iconTheme.color, size: 28)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Halo, ${(profileAsync.value != null && profileAsync.value!.nama.isNotEmpty) ? profileAsync.value!.nama.split(' ').first : (authState.user?.email.split('@').first ?? 'Mahasiswa')}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).textTheme.titleLarge?.color,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          profileAsync.value != null
                              ? 'NIM: ${profileAsync.value!.nim} • ${profileAsync.value!.programStudi}'
                              : 'Lengkapi profil Anda',
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),

              const SizedBox(height: 32),

              // Application Status Card
              // Application Status Card
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    final pCompleted = profileAsync.value != null && profileAsync.value!.nama.isNotEmpty;
                    final fCompleted = finansialAsync.value != null;
                    
                    bool pjCompleted = false;
                    if (pengajuanAsync.value != null) {
                      final activePengajuan = pengajuanAsync.value!.where((p) => !deletedIds.contains(p.id)).toList();
                      if (activePengajuan.isNotEmpty) {
                        pjCompleted = true;
                      }
                    }

                    bool sCompletedLocal = false;
                    if (pjCompleted) {
                      if (seleksiAsync.value != null && seleksiAsync.value!.isNotEmpty) {
                        sCompletedLocal = seleksiAsync.value!.any((s) => s['kelayakan'] == 'LAYAK');
                      }
                    }
                    
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      builder: (ctx) => _buildProgressBottomSheet(ctx, pCompleted, fCompleted, pjCompleted, sCompletedLocal, pengajuanAsync.value?.where((p) => !deletedIds.contains(p.id)).toList()),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Theme.of(context).dividerTheme.color ?? Colors.transparent),
                      boxShadow: [
                        BoxShadow(
                          color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black).withOpacity(0.03),
                          blurRadius: 10,
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
                            Text('Status Pengajuan', style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).textTheme.titleLarge?.color,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: badgeColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                statusBadge,
                                style: TextStyle(
                                  color: stepsCompleted == totalSteps ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Progress kelengkapan data dan pengajuan bantuan finansial Anda saat ini. (Ketuk untuk detail)',
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Progress Bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progressPercent,
                            minHeight: 8,
                            backgroundColor: isDark ? AppColors.darkSurfaceVariant : Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(isDark ? AppColors.primaryLight : Colors.black87),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Langkah $stepsCompleted dari $totalSteps',
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context).textTheme.bodyMedium?.color,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${(progressPercent * 100).toInt()}% Selesai',
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context).textTheme.bodyMedium?.color,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideY(begin: 0.1),

              const SizedBox(height: 32),

              // Quick Actions
              Text('Aksi Cepat',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 16),

              // Action Cards
              _QuickActionCard(
                icon: Icons.assignment_ind_outlined,
                title: 'Data Mahasiswa',
                subtitle: 'Perbarui informasi akademik dan data pribadi.',
                onTap: () => onNavigateTab(1),
                delay: 250,
              ),
              _QuickActionCard(
                icon: Icons.account_balance_wallet_outlined,
                title: 'Data Finansial',
                subtitle: 'Kelola data rekening bank dan catatan finansial.',
                onTap: () => onNavigateTab(2), // Tab finansial
                delay: 300,
              ),
              _QuickActionCard(
                icon: Icons.post_add_rounded,
                title: 'Pengajuan Bantuan',
                subtitle: 'Kirim formulir baru untuk bantuan finansial.',
                onTap: () => onNavigateTab(3),
                delay: 350,
              ),
              _QuickActionCard(
                icon: Icons.hourglass_bottom_rounded,
                title: 'Status Pengajuan',
                subtitle: 'Lacak proses pengajuan yang sedang berjalan.',
                onTap: () => onNavigateTab(3),
                delay: 400,
              ),
              _QuickActionCard(
                icon: Icons.verified_outlined,
                title: 'Hasil Seleksi',
                subtitle: 'Cek pengumuman dan hasil kelayakan bantuan.',
                onTap: () => onNavigateTab(4), // Notifikasi / Hasil
                delay: 450,
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBottomSheet(
    BuildContext context,
    bool profileCompleted,
    bool finansialCompleted,
    bool pengajuanCompleted,
    bool seleksiCompleted,
    List<PengajuanModel>? pengajuanList,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Detail Progress Aplikasi',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 24),
          _buildProgressStep(
            context,
            title: '1. Profil Mahasiswa',
            subtitle: 'Melengkapi data diri dasar',
            isCompleted: profileCompleted,
            onTap: () {
              Navigator.pop(context);
              if (!profileCompleted) onNavigateTab(1); // Data Mahasiswa tab
            },
          ),
          _buildProgressStep(
            context,
            title: '2. Data Finansial',
            subtitle: 'Melengkapi informasi keuangan & rekening',
            isCompleted: finansialCompleted,
            onTap: () {
              Navigator.pop(context);
              if (!finansialCompleted) onNavigateTab(2); // Finansial tab
            },
          ),
          _buildProgressStep(
            context,
            title: '3. Pengajuan Bantuan',
            subtitle: 'Mengirimkan formulir pengajuan',
            isCompleted: pengajuanCompleted,
            onTap: () {
              Navigator.pop(context);
              if (!pengajuanCompleted) onNavigateTab(3); // Pengajuan tab
            },
          ),
          _buildProgressStep(
            context,
            title: '4. Hasil Seleksi',
            subtitle: 'Menunggu keputusan kelayakan',
            isCompleted: seleksiCompleted,
            isLast: true,
            onTap: () {
              Navigator.pop(context);
              if (seleksiCompleted && pengajuanList != null && pengajuanList.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (ctx) => PengajuanDetailScreen(
                      pengajuan: pengajuanList.first,
                    ),
                  ),
                );
              } else {
                if (!seleksiCompleted) onNavigateTab(4); // Notifikasi/Hasil tab
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStep(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool isCompleted,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isCompleted ? AppColors.success : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isCompleted ? AppColors.success : Colors.grey.shade400,
                      width: 2,
                    ),
                  ),
                  child: isCompleted
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                      : null,
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 40,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: isCompleted ? AppColors.success : Colors.grey.shade200,
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isCompleted ? Theme.of(context).textTheme.titleLarge?.color : Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
            if (!isCompleted)
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final int delay;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerTheme.color ?? Colors.transparent),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Theme.of(context).iconTheme.color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.titleMedium?.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: delay.ms, duration: 400.ms).slideY(begin: 0.1);
  }
}


// ===== PROFILE TAB =====

class _ProfileTab extends ConsumerStatefulWidget {
  const _ProfileTab();

  @override
  ConsumerState<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends ConsumerState<_ProfileTab> {
  bool _isLoadingPhoto = false;

  Future<void> _uploadPhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (pickedFile == null) return;

    // Crop Image
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: pickedFile.path,
      uiSettings: [
        AndroidUiSettings(
            toolbarTitle: 'Sesuaikan Profil',
            toolbarColor: AppColors.primary,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true),
        IOSUiSettings(
          title: 'Sesuaikan Profil',
          aspectRatioLockEnabled: true,
        ),
      ],
    );

    if (croppedFile == null) return;

    setState(() => _isLoadingPhoto = true);
    try {
      await ref.read(authRepositoryProvider).uploadProfilePhoto(File(croppedFile.path));
      await ref.read(authProvider.notifier).checkAuth();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto profil berhasil diubah ✓'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingPhoto = false);
    }
  }

  void _showChangePasswordDialog() {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 24,
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
              const SizedBox(height: 24),
              Text('Ubah Password', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Password Lama',
                controller: oldCtrl,
                obscureText: true,
                prefixIcon: Icons.lock_outline_rounded,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Password Baru',
                controller: newCtrl,
                obscureText: true,
                prefixIcon: Icons.lock_reset_rounded,
              ),
              const SizedBox(height: 24),
              AppButton(
                label: 'Simpan Password Baru',
                isLoading: isSaving,
                onPressed: () async {
                  if (oldCtrl.text.isEmpty || newCtrl.text.isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Isi semua field'), backgroundColor: AppColors.warning),
                    );
                    return;
                  }
                  setModalState(() => isSaving = true);
                  try {
                    await ref.read(authRepositoryProvider).changePassword(oldCtrl.text, newCtrl.text);
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Password berhasil diubah ✓'), backgroundColor: AppColors.success),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
                    );
                  } finally {
                    setModalState(() => isSaving = false);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Keluar', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(ctx).cardTheme.color ?? Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: AppColors.primary),
                  const SizedBox(height: 16),
                  Text('Sedang keluar...', style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 800));
      await ref.read(authProvider.notifier).logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(myProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () {
              Navigator.of(context).pushNamed('/mahasiswa/profile/edit');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(myProfileProvider);
          ref.invalidate(myFinansialProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Card
              profileAsync.when(
                loading: () => const ShimmerCard(),
                error: (e, _) => ErrorState(
                  message: e.toString(),
                  onRetry: () => ref.invalidate(myProfileProvider),
                ),
                data: (mahasiswa) {
                  if (mahasiswa == null) {
                    return Column(
                      children: [
                        EmptyState(
                          title: 'Profil Belum Lengkap',
                          subtitle: 'Lengkapi data mahasiswa Anda',
                          icon: Icons.person_outline,
                          action: AppButton(
                            label: 'Lengkapi Profil',
                            onPressed: () =>
                                Navigator.of(context).pushNamed('/mahasiswa/profile/edit'),
                            width: 180,
                          ),
                        ),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      _buildProfileHeader(context, mahasiswa),
                      
                    ],
                  );
                },
              ),

              const SizedBox(height: 28),

            // Settings Menu
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                child: Column(
                  children: [
                    ListTile(
                      onTap: _showChangePasswordDialog,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.lock_rounded, color: AppColors.primary),
                      ),
                      title: const Text('Pengaturan', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('Ubah password akun', style: TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right_rounded),
                    ),
                    const Divider(height: 1),
                    Consumer(
                      builder: (context, ref, child) {
                        final themeMode = ref.watch(themeProvider);
                        final isDark = themeMode == ThemeMode.dark || (themeMode == ThemeMode.system && Theme.of(context).brightness == Brightness.dark);
                        return ListTile(
                          onTap: () {
                            ref.read(themeProvider.notifier).toggleTheme();
                          },
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSurfaceVariant : AppColors.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded, color: AppColors.primary),
                          ),
                          title: const Text('Tema', style: TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(isDark ? 'Mode Gelap' : 'Mode Terang', style: const TextStyle(fontSize: 12)),
                          trailing: Switch(
                            value: isDark,
                            activeColor: AppColors.primary,
                            onChanged: (val) {
                              ref.read(themeProvider.notifier).toggleTheme();
                            },
                          ),
                        );
                      },
                    ),
                    Consumer(
                      builder: (context, ref, child) {
                        final currentLocale = ref.watch(localeProvider);
                        return ListTile(
                          onTap: () {
                            ref.read(localeProvider.notifier).state = currentLocale == 'id' ? 'en' : 'id';
                          },
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.language_rounded, color: AppColors.secondary),
                          ),
                          title: const Text('Bahasa (Language)', style: TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(currentLocale == 'id' ? 'Bahasa Indonesia' : 'English', style: const TextStyle(fontSize: 12)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(currentLocale.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                              const SizedBox(width: 8),
                              const Icon(Icons.swap_horiz_rounded),
                            ],
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      onTap: _logout,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.errorContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.logout_rounded, color: AppColors.error),
                      ),
                      title: const Text('Keluar', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.error)),
                      subtitle: const Text('Akhiri sesi Anda', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, dynamic mahasiswa) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              GestureDetector(
                onTap: () {
                  final photoUrl = ref.read(authProvider).user?.fotoProfil;
                  if (photoUrl != null && photoUrl.isNotEmpty) {
                    showDialog(
                      context: context,
                      builder: (ctx) => Dialog(
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            InteractiveViewer(
                              child: Container(
                                width: MediaQuery.of(context).size.width * 0.8,
                                height: MediaQuery.of(context).size.width * 0.8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  image: DecorationImage(
                                    image: NetworkImage('${AppEndpoints.baseUrl}/$photoUrl'),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: IconButton(
                                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                                onPressed: () => Navigator.pop(ctx),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                },
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, spreadRadius: 2),
                    ],
                    image: ref.watch(authProvider).user?.fotoProfil != null && ref.watch(authProvider).user!.fotoProfil!.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage('${AppEndpoints.baseUrl}/${ref.watch(authProvider).user!.fotoProfil}'),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: ref.watch(authProvider).user?.fotoProfil == null || ref.watch(authProvider).user!.fotoProfil!.isEmpty
                      ? const Icon(Icons.person_rounded, color: AppColors.primary, size: 36)
                      : null,
                ),
              ),
              if (_isLoadingPhoto)
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                    child: const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      ),
                    ),
                  ),
                ),
              Positioned(
                bottom: -2,
                right: -2,
                child: GestureDetector(
                  onTap: _isLoadingPhoto ? null : _uploadPhoto,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mahasiswa.nama,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    mahasiswa.nim,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  mahasiswa.programStudi,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
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


// ===== DATA MAHASISWA TAB =====

class _DataMahasiswaTab extends ConsumerWidget {
  const _DataMahasiswaTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(myProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Data Mahasiswa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () {
              Navigator.of(context).pushNamed('/mahasiswa/profile/edit');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(myProfileProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              profileAsync.when(
                loading: () => const ShimmerCard(),
                error: (e, _) => ErrorState(
                  message: e.toString(),
                  onRetry: () => ref.invalidate(myProfileProvider),
                ),
                data: (mahasiswa) {
                  if (mahasiswa == null) {
                    return EmptyState(
                      title: 'Data Belum Lengkap',
                      subtitle: 'Lengkapi data akademik Anda',
                      icon: Icons.assignment_ind_outlined,
                      action: AppButton(
                        label: 'Lengkapi Sekarang',
                        onPressed: () =>
                            Navigator.of(context).pushNamed('/mahasiswa/profile/edit'),
                        width: 180,
                      ),
                    );
                  }

                  return _buildProfileData(context, mahasiswa);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileData(BuildContext context, dynamic mahasiswa) {
    final items = [
      {'label': 'Nama Lengkap', 'value': mahasiswa.nama, 'icon': Icons.badge_outlined},
      {'label': 'NIM', 'value': mahasiswa.nim, 'icon': Icons.numbers_rounded},
      {'label': 'Program Studi', 'value': mahasiswa.programStudi, 'icon': Icons.school_outlined},
      {'label': 'Fakultas', 'value': mahasiswa.fakultas, 'icon': Icons.business_rounded},
      {'label': 'Angkatan', 'value': mahasiswa.angkatan.toString(), 'icon': Icons.calendar_today_rounded},
      {'label': 'Jenis Kelamin', 'value': mahasiswa.jenisKelamin == 'LAKI_LAKI' ? 'Laki-laki' : 'Perempuan', 'icon': Icons.person_outline_rounded},
      {'label': 'Nomor HP', 'value': mahasiswa.nomorHp, 'icon': Icons.phone_outlined},
      {'label': 'Alamat', 'value': mahasiswa.alamat, 'icon': Icons.location_on_outlined},
      {
        'label': 'Golongan UKT', 
        'value': mahasiswa.uktAkhir != null 
            ? '${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(mahasiswa.uktAkhir)} (Setelah Penurunan)' 
            : (mahasiswa.uktAwal != null ? NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(mahasiswa.uktAwal) : 'Belum diisi'), 
        'icon': Icons.monetization_on_outlined
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final item = entry.value;
          final isLast = entry.key == items.length - 1;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Icon(item['icon'] as IconData, size: 18, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['label'] as String,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            item['value'] as String,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast) const Divider(height: 1),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ===== FINANSIAL TAB =====

class _DataFinansialTab extends ConsumerWidget {
  const _DataFinansialTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final finansialAsync = ref.watch(myFinansialProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Data Finansial'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () {
              Navigator.of(context).pushNamed('/mahasiswa/finansial/edit');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(myFinansialProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              finansialAsync.when(
                loading: () => const ShimmerCard(),
                error: (e, _) => const SizedBox.shrink(),
                data: (finansial) {
                  if (finansial == null) {
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.warningContainer.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppColors.warning.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              color: AppColors.warning, size: 32),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Data Finansial Belum Ada',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: AppColors.warning,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                AppButton(
                                  label: 'Isi Sekarang',
                                  onPressed: () => Navigator.of(context).pushNamed('/mahasiswa/finansial/edit'),
                                  isOutlined: true,
                                  color: AppColors.warning,
                                  width: 140,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return _buildFinansialCard(context, finansial, ref);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFinansialCard(BuildContext context, dynamic finansial, WidgetRef ref) {
    final items = [
      {
        'label': 'Pendapatan Orang Tua',
        'value': 'Rp ${_formatCurrency(finansial.pendapatanOrangTua)}/bln'
      },
      {'label': 'Jumlah Tanggungan', 'value': '${finansial.jumlahTanggungan} orang'},
      {
        'label': 'Pengeluaran Bulanan',
        'value': 'Rp ${_formatCurrency(finansial.pengeluaranBulanan)}/bln'
      },
      {'label': 'Uang Saku', 'value': 'Rp ${_formatCurrency(finansial.uangSaku)}/bln'},
      {'label': 'Literasi Keuangan', 'value': '${finansial.literasiKeuangan}/10'},
      {'label': 'Gaya Hidup', 'value': '${finansial.gayaHidup}/10'},
    ];

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.outline),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final item = entry.value;
              final isLast = entry.key == items.length - 1;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item['label']!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          item['value']!,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast) const Divider(height: 1),
                ],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        AppButton(
          label: 'Edit Data Finansial',
          onPressed: () =>
              Navigator.of(context).pushNamed('/mahasiswa/finansial/edit'),
          isOutlined: true,
          icon: Icons.edit_rounded,
        ),
      ],
    );
  }

  String _formatCurrency(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}jt';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}rb';
    }
    return value.toStringAsFixed(0);
  }
}


// ===== PENGAJUAN TAB =====

class _PengajuanTab extends ConsumerStatefulWidget {
  const _PengajuanTab();

  @override
  ConsumerState<_PengajuanTab> createState() => _PengajuanTabState();
}

class _PengajuanTabState extends ConsumerState<_PengajuanTab> {
  Set<String> _selectedIds = {};

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _deleteSelected() async {
    final repo = ref.read(pengajuanRepositoryProvider);
    for (final id in _selectedIds) {
      try {
        await repo.delete(id);
      } catch (e) {
        // Abaikan error jika ada yang gagal dihapus
      }
    }

    final deletedSet = ref.read(deletedPengajuanProvider);
    ref.read(deletedPengajuanProvider.notifier).state = {
      ...deletedSet,
      ..._selectedIds,
    };
    setState(() {
      _selectedIds.clear();
    });
    
    // Invalidate the provider so it fetches the updated list
    ref.invalidate(myPengajuanProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengajuan berhasil dihapus'), backgroundColor: AppColors.success),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pengajuanAsync = ref.watch(myPengajuanProvider);
    final deletedIds = ref.watch(deletedPengajuanProvider);

    return Scaffold(
      appBar: AppBar(
        title: _selectedIds.isEmpty 
            ? const Text('Pengajuan Bantuan')
            : Text(' Terpilih'),
        actions: [
          if (_selectedIds.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: _deleteSelected,
            ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90.0), // Menghindari taskbar
        child: FloatingActionButton.extended(
          onPressed: () =>
              Navigator.of(context).pushNamed('/mahasiswa/pengajuan/baru'),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Ajukan Baru'),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(myPengajuanProvider),
        child: pengajuanAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(20),
            child: ShimmerList(count: 4),
          ),
          error: (e, _) => ErrorState(
            message: e.toString(),
            onRetry: () => ref.invalidate(myPengajuanProvider),
          ),
          data: (allPengajuan) {
            final pengajuan = allPengajuan.where((p) => !deletedIds.contains(p.id)).toList();

            if (pengajuan.isEmpty) {
              return EmptyState(
                title: 'Belum Ada Pengajuan',
                subtitle: 'Tekan tombol + untuk mengajukan bantuan baru',
                icon: Icons.description_outlined,
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: pengajuan.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final p = pengajuan[i];
                final isSeleksi = p.status.toUpperCase() == 'SELEKSI' || p.status.toUpperCase() == 'SELESAI' || p.status.toUpperCase() == 'DITOLAK';
                final isSelected = _selectedIds.contains(p.id);

                return InkWell(
                  onTap: () {
                    if (_selectedIds.isNotEmpty && isSeleksi) {
                      _toggleSelection(p.id);
                    } else {
                      Navigator.of(context).pushNamed(
                        '/mahasiswa/pengajuan/',
                        arguments: p,
                      );
                    }
                  },
                  onLongPress: () {
                    if (isSeleksi) {
                      _toggleSelection(p.id);
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primaryContainer.withOpacity(0.5) : Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isSelected ? AppColors.primary : AppColors.outline),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isSeleksi)
                          Padding(
                            padding: const EdgeInsets.only(right: 12.0, top: 2),
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: isSelected,
                                onChanged: (val) => _toggleSelection(p.id),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              ),
                            ),
                          ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      p.bantuanNama ?? 'Bantuan Pendidikan',
                                      style: Theme.of(context).textTheme.titleSmall,
                                    ),
                                  ),
                                  StatusBadge(status: p.status),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('Diajukan: ',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              if (p.catatan != null && p.catatan!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.warningContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text('Catatan: ',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                              if (p.canUpload) ...[
                                const SizedBox(height: 12),
                                AppButton(
                                  label: 'Upload Dokumen',
                                  onPressed: () => Navigator.of(context).pushNamed(
                                    '/mahasiswa/pengajuan/',
                                    arguments: p,
                                  ),
                                  isOutlined: true,
                                  icon: Icons.upload_file_rounded,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ).animate(delay: Duration(milliseconds: i * 50)).fadeIn().slideX(begin: 0.1),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// ===== NOTIFIKASI TAB =====

class _NotifikasiTab extends ConsumerWidget {
  const _NotifikasiTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifAsync = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
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
                subtitle: 'Notifikasi akan muncul ketika ada update pengajuan',
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
