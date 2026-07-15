import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/mahasiswa_model.dart';
import '../data/models/app_models.dart';
import '../data/repositories/mahasiswa_repository.dart';
import '../data/repositories/pengajuan_repository.dart';
import '../core/network/dio_client.dart';
import '../core/constants/api_endpoints.dart';

// ===== MAHASISWA PROVIDER =====

final mahasiswaRepositoryProvider = Provider<MahasiswaRepository>((ref) {
  return MahasiswaRepository();
});

final myProfileProvider = FutureProvider.autoDispose<MahasiswaModel?>((ref) {
  return ref.watch(mahasiswaRepositoryProvider).getMyProfile();
});

final adminMahasiswaListProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, paramsJson) {
  final params = jsonDecode(paramsJson) as Map<String, dynamic>;
  return ref.watch(mahasiswaRepositoryProvider).getList(
        page: params['page'] ?? 1,
        perPage: params['per_page'] ?? 20,
        search: params['search'],
        programStudi: params['programStudi'],
        angkatan: params['angkatan'],
      );
});

final mahasiswaFiltersProvider = FutureProvider.autoDispose<Map<String, List<dynamic>>>((ref) {
  return ref.watch(mahasiswaRepositoryProvider).getFilters();
});

// ===== DATA FINANSIAL PROVIDER =====

final finansialRepositoryProvider = Provider<DataFinansialRepository>((ref) {
  return DataFinansialRepository();
});

final myFinansialProvider =
    FutureProvider.autoDispose<DataFinansialModel?>((ref) {
  return ref.watch(finansialRepositoryProvider).getMyFinansial();
});

final adminFinansialListProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, paramsJson) {
  final params = jsonDecode(paramsJson) as Map<String, dynamic>;
  return ref.watch(finansialRepositoryProvider).getList(
        page: params['page'] ?? 1,
        perPage: params['per_page'] ?? 20,
        search: params['search'],
        programStudi: params['programStudi'],
        angkatan: params['angkatan'],
      );
});

// ===== BANTUAN PROVIDER =====

final bantuanRepositoryProvider = Provider<BantuanRepository>((ref) {
  return BantuanRepository();
});

final bantuanListProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, Map<String, dynamic>>((ref, params) {
  return ref.watch(bantuanRepositoryProvider).getList(
        page: params['page'] ?? 1,
        perPage: params['per_page'] ?? 20,
        status: params['status'],
      );
});

final bantuanDetailProvider =
    FutureProvider.autoDispose.family<BantuanModel, String>((ref, id) {
  return ref.watch(bantuanRepositoryProvider).getDetail(id);
});

// ===== PENGAJUAN PROVIDER =====

final pengajuanRepositoryProvider = Provider<PengajuanRepository>((ref) {
  return PengajuanRepository();
});

final myPengajuanProvider =
    FutureProvider.autoDispose<List<PengajuanModel>>((ref) {
  return ref.watch(pengajuanRepositoryProvider).getMyPengajuan();
});

final allPengajuanProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, Map<String, dynamic>>((ref, params) {
  return ref.watch(pengajuanRepositoryProvider).getAllPengajuan(
        page: params['page'] ?? 1,
        perPage: params['per_page'] ?? 20,
        status: params['status'],
      );
});

final verifikasiListProvider =
    FutureProvider.autoDispose<List<PengajuanModel>>((ref) {
  return ref.watch(pengajuanRepositoryProvider).getVerifikasiList(perPage: 1000);
});

// ===== CLUSTERING PROVIDER =====

final clusteringRepositoryProvider = Provider<ClusteringRepository>((ref) {
  return ClusteringRepository();
});

final clusteringResultsProvider =
    FutureProvider.autoDispose<ClusteringResultModel>((ref) {
  return ref.watch(clusteringRepositoryProvider).getResults();
});

final clusteringStatsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) {
  return ref.watch(clusteringRepositoryProvider).getStatistics();
});

final mySeleksiProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return ref.watch(clusteringRepositoryProvider).getMySeleksi();
});

final clusteringHistoryProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return ref.watch(clusteringRepositoryProvider).getClusteringHistory();
});

// ===== NOTIFICATION PROVIDER =====

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});

final notificationsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) {
  return ref.watch(notificationRepositoryProvider).getNotifications();
});

final unreadCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final data = await ref
      .watch(notificationRepositoryProvider)
      .getNotifications(unreadOnly: true);
  return (data['unread_count'] as int?) ?? 0;
});

// ===== ADMIN STATS PROVIDER =====

typedef AdminStatsFilter = ({String? startDate, String? endDate});

final adminStatsProvider =
    FutureProvider.family.autoDispose<Map<String, dynamic>, AdminStatsFilter>((ref, filters) async {
  // No more aggressive real-time polling to fix performance issues.

  final dioInstance = DioClient.instance;
  try {
    final response = await dioInstance.get(
      AppEndpoints.adminStats,
      queryParameters: {
        if (filters.startDate != null) 'start_date': filters.startDate,
        if (filters.endDate != null) 'end_date': filters.endDate,
      },
    );
    return (response.data['data'] as Map<String, dynamic>?) ?? {};
  } on DioException catch (e) {
    throw Exception(
        e.response?.data['message'] ?? 'Gagal memuat statistik');
  }
});

final adminPengajuanByStatusProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, status) async {
  final dioInstance = DioClient.instance;
  try {
    final response = await dioInstance.get(
      AppEndpoints.pengajuanList,
      queryParameters: {'status': status, 'per_page': 1000},
    );
    return (response.data['data'] as Map<String, dynamic>?) ?? {};
  } on DioException catch (e) {
    throw Exception(
        e.response?.data['message'] ?? 'Gagal memuat data pengajuan');
  }
});

// ===== SELEKSI PROVIDER =====

final seleksiListProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, Map<String, dynamic>>((ref, params) async {
  final dioInstance = DioClient.instance;
  try {
    final response = await dioInstance.get(
      AppEndpoints.seleksiList,
      queryParameters: {
        'page': params['page'] ?? 1,
        'per_page': params['per_page'] ?? 20,
      },
    );
    return (response.data['data'] as Map<String, dynamic>?) ?? {};
  } on DioException catch (e) {
    throw Exception(e.response?.data['message'] ?? 'Gagal memuat hasil seleksi');
  }
});

final deletedPengajuanProvider = StateProvider<Set<String>>((ref) => {});

// Provider for Language/Locale (id / en)
final localeProvider = StateProvider<String>((ref) => 'id');

