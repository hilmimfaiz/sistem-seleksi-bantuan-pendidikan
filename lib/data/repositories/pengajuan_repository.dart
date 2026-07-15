import 'dart:io';
import 'package:dio/dio.dart';
import '../models/app_models.dart';
import '../../core/network/dio_client.dart';
import '../../core/constants/api_endpoints.dart';

class PengajuanRepository {
  final Dio _dio = DioClient.instance;

  Future<List<PengajuanModel>> getMyPengajuan() async {
    try {
      final response = await _dio.get(AppEndpoints.pengajuanMe);
      final data = response.data['data'];
      if (data is List) {
        return data.map((e) => PengajuanModel.fromJson(e)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<PengajuanModel> create(String bantuanId) async {
    try {
      final response = await _dio.post(
        AppEndpoints.pengajuanList,
        data: {'bantuan_id': bantuanId},
      );
      return PengajuanModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _dio.delete('${AppEndpoints.pengajuanList}/$id');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> uploadDokumen(String pengajuanId, List<File> files) async {
    try {
      final formData = FormData();
      for (final file in files) {
        final fileName = file.path.split('/').last;
        formData.files.add(MapEntry(
          'files',
          await MultipartFile.fromFile(file.path, filename: fileName),
        ));
      }
      await _dio.post(
        AppEndpoints.pengajuanUpload(pengajuanId),
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getAllPengajuan({
    int page = 1,
    int perPage = 20,
    String? status,
  }) async {
    try {
      final response = await _dio.get(
        AppEndpoints.pengajuanList,
        queryParameters: {
          'page': page,
          'per_page': perPage,
          if (status != null) 'status': status,
        },
      );
      final data = response.data['data'];
      return {
        'items': (data['items'] as List)
            .map((e) => PengajuanModel.fromJson(e))
            .toList(),
        'total': data['total'],
        'total_pages': data['total_pages'],
      };
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> approve(String id, {String? catatan}) async {
    try {
      await _dio.post(
        AppEndpoints.verifikasiApprove(id),
        data: {'catatan': catatan},
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> reject(String id, {String? catatan}) async {
    try {
      await _dio.post(
        AppEndpoints.verifikasiReject(id),
        data: {'catatan': catatan},
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> revise(String id, {String? catatan}) async {
    try {
      await _dio.post(
        AppEndpoints.verifikasiRevise(id),
        data: {'catatan': catatan},
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<PengajuanModel>> getVerifikasiList({
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final response = await _dio.get(
        AppEndpoints.verifikasiList,
        queryParameters: {'page': page, 'per_page': perPage},
      );
      final data = response.data['data'];
      return (data['items'] as List)
          .map((e) => PengajuanModel.fromJson(e))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException e) {
    final statusCode = e.response?.statusCode;
    final data = e.response?.data;
    String message = 'Terjadi kesalahan';
    if (data != null && data is Map) {
      message = data['message']?.toString() ?? data['detail']?.toString() ?? message;
    }
    return NetworkException(message: message, statusCode: statusCode);
  }
}


class ClusteringRepository {
  final Dio _dio = DioClient.instance;

  Future<Map<String, dynamic>> runClustering({
    int nClusters = 4,
    double eps = 0.5,
    int minSamples = 3,
  }) async {
    try {
      final response = await _dio.post(
        AppEndpoints.clusteringRun,
        data: {
          'n_clusters': nClusters,
          'eps': eps,
          'min_samples': minSamples,
        },
      );
      return response.data['data'] ?? {};
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<ClusteringResultModel> getResults() async {
    try {
      final response = await _dio.get(AppEndpoints.clusteringResults);
      return ClusteringResultModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final response = await _dio.get(AppEndpoints.clusteringStats);
      return response.data['data'] ?? {};
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getClusteringHistory() async {
    try {
      final response = await _dio.get(AppEndpoints.clusteringHistory);
      final data = response.data['data'];
      if (data != null && data['items'] is List) {
        return (data['items'] as List).cast<Map<String, dynamic>>();
      }
      return [];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> setKelayakan(
    String pengajuanId,
    String kelayakan, {
    String? keterangan,
  }) async {
    try {
      await _dio.post(
        AppEndpoints.seleksiCreate(pengajuanId),
        data: {'kelayakan': kelayakan, 'keterangan': keterangan},
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getMySeleksi() async {
    try {
      final response = await _dio.get(AppEndpoints.seleksiMe);
      final data = response.data['data'];
      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException e) {
    final statusCode = e.response?.statusCode;
    final data = e.response?.data;
    String message = 'Terjadi kesalahan';
    if (data != null && data is Map) {
      message = data['message']?.toString() ?? data['detail']?.toString() ?? message;
    }
    return NetworkException(message: message, statusCode: statusCode);
  }
}


class NotificationRepository {
  final Dio _dio = DioClient.instance;

  Future<Map<String, dynamic>> getNotifications({
    int page = 1,
    int perPage = 20,
    bool unreadOnly = false,
  }) async {
    try {
      final response = await _dio.get(
        AppEndpoints.notifications,
        queryParameters: {
          'page': page,
          'per_page': perPage,
          'unread_only': unreadOnly,
        },
      );
      final data = response.data['data'];
      return {
        'items': (data['items'] as List)
            .map((e) => NotificationModel.fromJson(e))
            .toList(),
        'total': data['total'],
        'unread_count': data['unread_count'] ?? 0,
        'total_pages': data['total_pages'],
      };
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _dio.put(AppEndpoints.notificationRead(id));
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _dio.put(AppEndpoints.notificationReadAll);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteHistory(String period) async {
    try {
      await _dio.delete('${AppEndpoints.notifications}?period=$period');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException e) {
    final statusCode = e.response?.statusCode;
    final data = e.response?.data;
    String message = 'Terjadi kesalahan';
    if (data != null && data is Map) {
      message = data['message']?.toString() ?? data['detail']?.toString() ?? message;
    }
    return NetworkException(message: message, statusCode: statusCode);
  }
}
