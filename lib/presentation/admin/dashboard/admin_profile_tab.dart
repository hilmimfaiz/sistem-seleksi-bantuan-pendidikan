import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../auth/login_screen.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../providers/app_providers.dart';

class AdminProfileTab extends ConsumerStatefulWidget {
  const AdminProfileTab({super.key});

  @override
  ConsumerState<AdminProfileTab> createState() => _AdminProfileTabState();
}

class _AdminProfileTabState extends ConsumerState<AdminProfileTab> {
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
      builder: (d) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Keluar dari dashboard admin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(d, true),
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
    final authState = ref.watch(authProvider);
    final user = authState.user;

    String avatarUrl = '';
    if (user?.fotoProfil != null && user!.fotoProfil!.isNotEmpty) {
      avatarUrl = '${AppEndpoints.baseUrl}/${user.fotoProfil}';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Anda', style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: false,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Avatar Section
            Center(
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (avatarUrl.isNotEmpty) {
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
                                        image: NetworkImage(avatarUrl),
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
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.outlineVariant, width: 4),
                        image: avatarUrl.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(avatarUrl),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: avatarUrl.isEmpty
                          ? const Icon(Icons.person_rounded, size: 60, color: AppColors.primary)
                          : null,
                    ),
                  ),
                  if (_isLoadingPhoto)
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                        child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                      ),
                    ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _isLoadingPhoto ? null : _uploadPhoto,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  user?.nama ?? 'Administrator',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    final nameCtrl = TextEditingController(text: user?.nama ?? 'Administrator');
                    bool isSavingName = false;
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
                              Text('Ubah Nama Profil', style: Theme.of(ctx).textTheme.titleLarge),
                              const SizedBox(height: 16),
                              AppTextField(
                                label: 'Nama Baru',
                                controller: nameCtrl,
                                prefixIcon: Icons.person_rounded,
                              ),
                              const SizedBox(height: 24),
                              AppButton(
                                label: 'Simpan Nama Baru',
                                isLoading: isSavingName,
                                onPressed: () async {
                                  if (nameCtrl.text.isEmpty) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      const SnackBar(content: Text('Nama tidak boleh kosong'), backgroundColor: AppColors.warning),
                                    );
                                    return;
                                  }
                                  setModalState(() => isSavingName = true);
                                  try {
                                    await ref.read(authRepositoryProvider).changeName(nameCtrl.text);
                                    await ref.read(authProvider.notifier).checkAuth();
                                    if (ctx.mounted) Navigator.pop(ctx);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Nama berhasil diubah ✓'), backgroundColor: AppColors.success),
                                      );
                                    }
                                  } catch (e) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
                                    );
                                  } finally {
                                    setModalState(() => isSavingName = false);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit_rounded, size: 16, color: AppColors.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              user?.email ?? 'admin@finanedu.com',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            
            const SizedBox(height: 40),
            
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
    );
  }
}
