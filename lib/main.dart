import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'presentation/splash/splash_screen.dart';
import 'presentation/auth/login_screen.dart';
import 'presentation/mahasiswa/dashboard/mahasiswa_dashboard.dart';
import 'presentation/mahasiswa/profile/profile_edit_screen.dart';
import 'presentation/mahasiswa/finansial/finansial_edit_screen.dart';
import 'presentation/mahasiswa/pengajuan/pengajuan_baru_screen.dart';
import 'presentation/mahasiswa/pengajuan/pengajuan_detail_screen.dart';
import 'data/models/app_models.dart';
import 'presentation/admin/dashboard/admin_dashboard.dart';
import 'presentation/admin/bantuan/bantuan_management_screen.dart';
import 'presentation/admin/mahasiswa/admin_mahasiswa_screen.dart';
import 'presentation/admin/finansial/admin_finansial_screen.dart';
import 'presentation/admin/seleksi/admin_seleksi_screen.dart';
import 'presentation/admin/verifikasi/verifikasi_screen.dart';
import 'presentation/admin/notifikasi/admin_notifikasi_screen.dart';
import 'presentation/admin/laporan/admin_laporan_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'FinanEdu - Seleksi Bantuan Pendidikan',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      initialRoute: '/',
      onGenerateRoute: _onGenerateRoute,
    );
  }

  static Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      // Mahasiswa routes
      case '/mahasiswa/dashboard':
        return MaterialPageRoute(builder: (_) => const MahasiswaDashboard());
      case '/mahasiswa/profile/edit':
        return MaterialPageRoute(builder: (_) => const MahasiswaProfileEditScreen());
      case '/mahasiswa/finansial/edit':
        return MaterialPageRoute(builder: (_) => const FinansialEditScreen());
      case '/mahasiswa/pengajuan/baru':
        return MaterialPageRoute(builder: (_) => const PengajuanBaruScreen());

      // Admin routes
      case '/admin/dashboard':
        return MaterialPageRoute(builder: (_) => const AdminDashboard());
      case '/admin/bantuan':
        return MaterialPageRoute(builder: (_) => const BantuanManagementScreen());
      case '/admin/mahasiswa':
        return MaterialPageRoute(builder: (_) => const AdminMahasiswaScreen());
      case '/admin/finansial':
        return MaterialPageRoute(builder: (_) => const AdminFinansialScreen());
      case '/admin/seleksi':
        return MaterialPageRoute(builder: (_) => const AdminSeleksiScreen());
      case '/admin/verifikasi':
        return MaterialPageRoute(builder: (_) => const VerifikasiScreen());
      case '/admin/notifikasi':
        return MaterialPageRoute(builder: (_) => const AdminNotifikasiScreen());
      case '/admin/laporan':
        return MaterialPageRoute(builder: (_) => const AdminLaporanScreen());

      default:
        if (settings.name?.startsWith('/mahasiswa/pengajuan/') ?? false) {
          if (settings.name != '/mahasiswa/pengajuan/baru') {
            final args = settings.arguments;
            if (args is PengajuanModel) {
              return MaterialPageRoute(builder: (_) => PengajuanDetailScreen(pengajuan: args));
            }
          }
        }

        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Halaman Tidak Ditemukan')),
            body: const Center(
              child: Text('404 - Halaman tidak ditemukan'),
            ),
          ),
        );
    }
  }
}
