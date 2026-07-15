import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class AppEndpoints {
  AppEndpoints._();

  // Catatan: Jika dijalankan di HP fisik via USB/WiFi, gunakan IP Address komputer Anda (cek via 'ipconfig').
  // 10.0.2.2 hanya berlaku untuk Android Emulator, 127.0.0.1 untuk web/Windows desktop.
  static String get baseUrl {
    const fromEnv = String.fromEnvironment('API_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    
    if (kIsWeb) return 'http://127.0.0.1:8000';
    
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:8000';
    } catch (_) {}
    
    return 'http://127.0.0.1:8000';
  }
  static const String apiPrefix = '/api/v1';

  // Auth
  static const String login = '$apiPrefix/auth/login';
  static const String logout = '$apiPrefix/auth/logout';
  static const String refresh = '$apiPrefix/auth/refresh';
  static const String me = '$apiPrefix/auth/me';

  // Mahasiswa
  static const String mahasiswaMe = '$apiPrefix/mahasiswa/me';
  static const String mahasiswaList = '$apiPrefix/mahasiswa';
  static const String mahasiswaFilters = '$apiPrefix/mahasiswa/filters';
  static String mahasiswaDetail(String id) => '$apiPrefix/mahasiswa/$id';

  // Finansial
  static const String finansialMe = '$apiPrefix/finansial/me';
  static const String finansialList = '$apiPrefix/finansial';

  // Bantuan
  static const String bantuanList = '$apiPrefix/bantuan';
  static String bantuanDetail(String id) => '$apiPrefix/bantuan/$id';

  // Pengajuan
  static const String pengajuanMe = '$apiPrefix/pengajuan/me';
  static const String pengajuanList = '$apiPrefix/pengajuan';
  static String pengajuanDetail(String id) => '$apiPrefix/pengajuan/$id';
  static String pengajuanUpload(String id) => '$apiPrefix/pengajuan/$id/upload';

  // Verifikasi
  static const String verifikasiList = '$apiPrefix/verifikasi';
  static String verifikasiApprove(String id) => '$apiPrefix/verifikasi/$id/approve';
  static String verifikasiReject(String id) => '$apiPrefix/verifikasi/$id/reject';
  static String verifikasiRevise(String id) => '$apiPrefix/verifikasi/$id/revise';

  // Clustering
  static const String clusteringRun = '$apiPrefix/clustering/run';
  static const String clusteringResults = '$apiPrefix/clustering/results';
  static const String clusteringStats = '$apiPrefix/clustering/statistics';
  static const String clusteringHistory = '$apiPrefix/clustering/history';

  // Seleksi
  static const String seleksiMe = '$apiPrefix/seleksi/me';
  static const String seleksiList = '$apiPrefix/seleksi';
  static const String seleksiBulkDelete = '$apiPrefix/seleksi/bulk';
  static String seleksiCreate(String pengajuanId) =>
      '$apiPrefix/seleksi/$pengajuanId';

  // Notifications
  static const String notifications = '$apiPrefix/notifications';
  static String notificationRead(String id) =>
      '$apiPrefix/notifications/$id/read';
  static const String notificationReadAll = '$apiPrefix/notifications/read-all';

  // Admin
  static const String adminStats = '$apiPrefix/admin/stats';
  static const String adminMahasiswa = '$apiPrefix/admin/mahasiswa';
}
