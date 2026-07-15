class RouteNames {
  RouteNames._();

  static const String splash = '/';
  static const String login = '/login';

  // Mahasiswa Routes
  static const String mahasiswaDashboard = '/mahasiswa/dashboard';
  static const String mahasiswaProfile = '/mahasiswa/profile';
  static const String mahasiswaProfileEdit = '/mahasiswa/profile/edit';
  static const String mahasiswaFinansial = '/mahasiswa/finansial';
  static const String mahasiswaFinansialEdit = '/mahasiswa/finansial/edit';
  static const String mahasiswaPengajuan = '/mahasiswa/pengajuan';
  static const String mahasiswaPengajuanBaru = '/mahasiswa/pengajuan/baru';
  static const String mahasiswaPengajuanDetail = '/mahasiswa/pengajuan/:id';
  static const String mahasiswaHasilSeleksi = '/mahasiswa/hasil-seleksi';
  static const String mahasiswaNotifikasi = '/mahasiswa/notifikasi';

  // Admin Routes
  static const String adminDashboard = '/admin/dashboard';
  static const String adminBantuan = '/admin/bantuan';
  static const String adminBantuanBaru = '/admin/bantuan/baru';
  static const String adminBantuanEdit = '/admin/bantuan/:id/edit';
  static const String adminMahasiswa = '/admin/mahasiswa';
  static const String adminMahasiswaDetail = '/admin/mahasiswa/:id';
  static const String adminFinansial = '/admin/finansial';
  static const String adminVerifikasi = '/admin/verifikasi';
  static const String adminVerifikasiDetail = '/admin/verifikasi/:id';
  static const String adminClustering = '/admin/clustering';
  static const String adminHasilClustering = '/admin/clustering/results';
  static const String adminSeleksi = '/admin/seleksi';
  static const String adminNotifikasi = '/admin/notifikasi';
  static const String adminLaporan = '/admin/laporan';
}
