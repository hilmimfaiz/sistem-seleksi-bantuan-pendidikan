import 'package:dio/dio.dart';
import '../models/mahasiswa_model.dart';
import '../models/app_models.dart';
import '../../core/network/dio_client.dart';
import '../../core/constants/api_endpoints.dart';

class MahasiswaRepository {
  final Dio _dio = DioClient.instance;

  Future<MahasiswaModel?> getMyProfile() async {
    try {
      final response = await _dio.get(AppEndpoints.mahasiswaMe);
      final data = response.data['data'];
      if (data == null) return null;
      return MahasiswaModel.fromJson(data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<MahasiswaModel> createProfile(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(AppEndpoints.mahasiswaList, data: data);
      return MahasiswaModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<MahasiswaModel> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _dio.put(AppEndpoints.mahasiswaMe, data: data);
      return MahasiswaModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getList({
    int page = 1,
    int perPage = 20,
    String? search,
    String? programStudi,
    int? angkatan,
  }) async {
    try {
      final response = await _dio.get(
        AppEndpoints.mahasiswaList,
        queryParameters: {
          'page': page,
          'per_page': perPage,
          if (search != null && search.isNotEmpty) 'search': search,
          if (programStudi != null && programStudi != 'All Programs' && programStudi.isNotEmpty) 'program_studi': programStudi,
          if (angkatan != null && angkatan > 0) 'angkatan': angkatan,
        },
      );
      final data = response.data['data'];
      return {
        'items': (data['items'] as List)
            .map((e) => MahasiswaModel.fromJson(e))
            .toList(),
        'total': data['total'],
        'page': data['page'],
        'total_pages': data['total_pages'],
      };
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

  Future<void> registerMahasiswa(MahasiswaRegisterRequest request) async {
    try {
      await _dio.post(AppEndpoints.adminMahasiswa, data: request.toJson());
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> updateMahasiswa(String id, Map<String, dynamic> data) async {
    try {
      await _dio.put(AppEndpoints.mahasiswaDetail(id), data: data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteMahasiswa(String id) async {
    try {
      await _dio.delete(AppEndpoints.mahasiswaDetail(id));
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, List<dynamic>>> getFilters() async {
    try {
      final response = await _dio.get(AppEndpoints.mahasiswaFilters);
      final data = response.data['data'] as Map<String, dynamic>;
      return {
        'program_studi': data['program_studi'] as List<dynamic>,
        'angkatan': data['angkatan'] as List<dynamic>,
      };
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
}

class DataFinansialRepository {
  final Dio _dio = DioClient.instance;

  Future<DataFinansialModel?> getMyFinansial() async {
    try {
      final response = await _dio.get(AppEndpoints.finansialMe);
      final data = response.data['data'];
      if (data == null) return null;
      return DataFinansialModel.fromJson(data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<DataFinansialModel> createFinansial(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(AppEndpoints.finansialList, data: data);
      return DataFinansialModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<DataFinansialModel> updateFinansial(Map<String, dynamic> data) async {
    try {
      final response = await _dio.put(AppEndpoints.finansialMe, data: data);
      return DataFinansialModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getList({
    int page = 1,
    int perPage = 20,
    String? search,
    String? programStudi,
    int? angkatan,
  }) async {
    try {
      final response = await _dio.get(
        AppEndpoints.finansialList,
        queryParameters: {
          'page': page,
          'per_page': perPage,
          if (search != null && search.isNotEmpty) 'search': search,
          if (programStudi != null && programStudi != 'All Programs' && programStudi.isNotEmpty) 'program_studi': programStudi,
          if (angkatan != null && angkatan > 0) 'angkatan': angkatan,
        },
      );
      final data = response.data['data'];
      return {
        'items': (data['items'] as List)
            .map((e) => DataFinansialModel.fromJson(e))
            .toList(),
        'total': data['total'],
        'total_pages': data['total_pages'],
      };
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

class BantuanRepository {
  final Dio _dio = DioClient.instance;

  Future<Map<String, dynamic>> getList({
    int page = 1,
    int perPage = 20,
    String? status,
  }) async {
    try {
      final response = await _dio.get(
        AppEndpoints.bantuanList,
        queryParameters: {
          'page': page,
          'per_page': perPage,
          if (status != null) 'status': status,
        },
      );
      final data = response.data['data'];
      return {
        'items': (data['items'] as List)
            .map((e) => BantuanModel.fromJson(e))
            .toList(),
        'total': data['total'],
        'total_pages': data['total_pages'],
      };
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<BantuanModel> getDetail(String id) async {
    try {
      final response = await _dio.get(AppEndpoints.bantuanDetail(id));
      return BantuanModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<BantuanModel> create(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(AppEndpoints.bantuanList, data: data);
      return BantuanModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<BantuanModel> update(String id, Map<String, dynamic> data) async {
    try {
      final response =
          await _dio.put(AppEndpoints.bantuanDetail(id), data: data);
      return BantuanModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _dio.delete(AppEndpoints.bantuanDetail(id));
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
