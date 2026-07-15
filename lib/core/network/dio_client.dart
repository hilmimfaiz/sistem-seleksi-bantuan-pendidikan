import 'package:dio/dio.dart';
import '../constants/api_endpoints.dart';
import '../storage/secure_storage.dart';

class NetworkException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  NetworkException({
    required this.message,
    this.statusCode,
    this.data,
  });

  @override
  String toString() => message;
}

class DioClient {
  static Dio? _instance;

  static Dio get instance {
    _instance ??= _createDio();
    return _instance!;
  }

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(_AuthInterceptor(dio));
    // dio.interceptors.add(LogInterceptor(
    //   requestBody: true,
    //   responseBody: true,
    //   logPrint: (obj) => debugPrint('DIO: $obj'),
    // ));

    return dio;
  }

  static void reset() {
    _instance = null;
  }
}

void debugPrint(String message) {
  // Only in debug mode
  assert(() {
    // ignore: avoid_print
    print(message);
    return true;
  }());
}

class _AuthInterceptor extends Interceptor {
  final Dio _dio;
  bool _isRefreshing = false;
  final List<RequestOptions> _pendingRequests = [];

  _AuthInterceptor(this._dio);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip auth for login and refresh endpoints
    final skipAuth = [
      AppEndpoints.login,
      AppEndpoints.refresh,
    ];
    if (skipAuth.contains(options.path)) {
      handler.next(options);
      return;
    }

    final token = await SecureStorageService.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      // Coba refresh token
      if (!_isRefreshing) {
        _isRefreshing = true;
        try {
          final refreshToken = await SecureStorageService.getRefreshToken();
          if (refreshToken == null) {
            await SecureStorageService.clearAll();
            handler.reject(err);
            return;
          }

          final response = await Dio().post(
            '${AppEndpoints.baseUrl}${AppEndpoints.refresh}',
            data: {'refresh_token': refreshToken},
          );

          final data = response.data['data'];
          final newAccessToken = data['access_token'] as String;
          final newRefreshToken = data['refresh_token'] as String;

          await SecureStorageService.saveAccessToken(newAccessToken);
          await SecureStorageService.saveRefreshToken(newRefreshToken);

          // Retry original request
          final opts = err.requestOptions;
          opts.headers['Authorization'] = 'Bearer $newAccessToken';
          final retryResponse = await _dio.request(
            opts.path,
            options: Options(
              method: opts.method,
              headers: opts.headers,
            ),
            data: opts.data,
            queryParameters: opts.queryParameters,
          );
          handler.resolve(retryResponse);
        } catch (e) {
          await SecureStorageService.clearAll();
          handler.reject(err);
        } finally {
          _isRefreshing = false;
        }
      }
    } else {
      handler.next(err);
    }
  }
}

extension DioExtension on Dio {
  Future<T> safeRequest<T>({
    required Future<Response> Function() request,
    required T Function(dynamic data) parser,
    String defaultErrorMessage = 'Terjadi kesalahan. Coba lagi.',
  }) async {
    try {
      final response = await request();
      return parser(response.data['data']);
    } on DioException catch (e) {
      throw _handleDioError(e, defaultErrorMessage);
    } catch (e) {
      throw NetworkException(message: defaultErrorMessage);
    }
  }

  NetworkException _handleDioError(DioException e, String defaultMessage) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return NetworkException(
        message: 'Koneksi timeout. Periksa jaringan internet Anda.',
        statusCode: null,
      );
    }

    if (e.type == DioExceptionType.connectionError) {
      return NetworkException(
        message: 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
        statusCode: null,
      );
    }

    final statusCode = e.response?.statusCode;
    final data = e.response?.data;
    String message = defaultMessage;

    if (data != null && data is Map) {
      message = data['message']?.toString() ??
          data['detail']?.toString() ??
          defaultMessage;
    }

    switch (statusCode) {
      case 400:
        return NetworkException(
            message: message, statusCode: 400, data: data);
      case 401:
        return NetworkException(
            message: (data != null && data is Map && (data['message'] != null || data['detail'] != null)) 
                ? message 
                : 'Sesi habis. Silakan login kembali.',
            statusCode: 401,
            data: data);
      case 403:
        return NetworkException(
            message: 'Anda tidak memiliki akses ke fitur ini.',
            statusCode: 403,
            data: data);
      case 404:
        return NetworkException(
            message: message.isNotEmpty ? message : 'Data tidak ditemukan.',
            statusCode: 404,
            data: data);
      case 409:
        return NetworkException(
            message: message, statusCode: 409, data: data);
      case 422:
        return NetworkException(
            message: 'Data tidak valid. Periksa input Anda.',
            statusCode: 422,
            data: data);
      case 500:
        return NetworkException(
            message: 'Terjadi kesalahan pada server. Coba lagi nanti.',
            statusCode: 500,
            data: data);
      default:
        return NetworkException(
            message: message, statusCode: statusCode, data: data);
    }
  }
}
