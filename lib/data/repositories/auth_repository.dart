import 'dart:io';
import 'package:dio/dio.dart';
import '../models/user_model.dart';
import '../../core/network/dio_client.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/storage/secure_storage.dart';

class AuthRepository {
  final Dio _dio = DioClient.instance;

  Future<AuthModel> login(String email, String password) async {
    try {
      final response = await _dio.post(
        AppEndpoints.login,
        data: {'email': email, 'password': password},
      );
      final data = response.data['data'];
      final auth = AuthModel.fromJson(data);

      // Simpan ke secure storage
      await SecureStorageService.saveAuthData(
        accessToken: auth.accessToken,
        refreshToken: auth.refreshToken,
        userId: auth.userId,
        email: auth.email,
        role: auth.role,
      );

      return auth;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post(AppEndpoints.logout);
    } catch (_) {
      // Tetap clear local storage meskipun API error
    } finally {
      await SecureStorageService.clearAll();
      DioClient.reset();
    }
  }

  Future<AuthModel?> refreshToken() async {
    try {
      final refreshToken = await SecureStorageService.getRefreshToken();
      if (refreshToken == null) return null;

      final response = await Dio().post(
        '${AppEndpoints.baseUrl}${AppEndpoints.refresh}',
        data: {'refresh_token': refreshToken},
      );

      final data = response.data['data'];
      final newAccessToken = data['access_token'] as String;
      final newRefreshToken = data['refresh_token'] as String;

      await SecureStorageService.saveAccessToken(newAccessToken);
      await SecureStorageService.saveRefreshToken(newRefreshToken);

      final userId = await SecureStorageService.getUserId();
      final email = await SecureStorageService.getUserEmail();
      final role = await SecureStorageService.getUserRole();

      return AuthModel(
        accessToken: newAccessToken,
        refreshToken: newRefreshToken,
        userId: userId ?? '',
        email: email ?? '',
        role: role ?? 'MAHASISWA',
      );
    } catch (_) {
      await SecureStorageService.clearAll();
      return null;
    }
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      final response = await _dio.get(AppEndpoints.me);
      final data = response.data['data'];
      return UserModel.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) return null;
      throw _handleError(e);
    }
  }

  Future<String> uploadProfilePhoto(File file) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path),
      });
      final response = await _dio.post(
        '${AppEndpoints.baseUrl}/api/v1/auth/profile/photo',
        data: formData,
      );
      return response.data['data']['foto_profil'] as String;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    try {
      await _dio.post(
        '${AppEndpoints.baseUrl}/api/v1/auth/profile/password',
        data: {
          'old_password': oldPassword,
          'new_password': newPassword,
        },
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> changeName(String newName) async {
    try {
      await _dio.post(
        '${AppEndpoints.baseUrl}/api/v1/auth/profile/name',
        data: {
          'nama': newName,
        },
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  NetworkException _handleError(DioException e) {
    final statusCode = e.response?.statusCode;
    final data = e.response?.data;
    String message = 'Terjadi kesalahan';
    if (data != null && data is Map) {
      message = data['message']?.toString() ?? data['detail']?.toString() ?? message;
    }
    return NetworkException(
        message: message, statusCode: statusCode, data: data);
  }
}
