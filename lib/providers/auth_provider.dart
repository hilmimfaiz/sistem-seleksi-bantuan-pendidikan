import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/user_model.dart';
import '../data/repositories/auth_repository.dart';
import '../core/storage/secure_storage.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final AuthModel? auth;
  final String? error;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.auth,
    this.error,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    AuthModel? auth,
    String? error,
  }) =>
      AuthState(
        status: status ?? this.status,
        user: user ?? this.user,
        auth: auth ?? this.auth,
        error: error,
      );

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isAdmin => user?.isAdmin ?? false;
  bool get isMahasiswa => user?.isMahasiswa ?? false;
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AuthState());

  Future<void> checkAuth() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      // Cek apakah ada token tersimpan
      final accessToken = await SecureStorageService.getAccessToken();
      if (accessToken == null) {
        state = state.copyWith(status: AuthStatus.unauthenticated);
        return;
      }

      // Coba ambil data user dengan access token
      final user = await _repository.getCurrentUser();
      if (user != null) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
        );
        return;
      }

      // Jika gagal, coba refresh token
      final auth = await _repository.refreshToken();
      if (auth != null) {
        final refreshedUser = await _repository.getCurrentUser();
        if (refreshedUser != null) {
          state = state.copyWith(
            status: AuthStatus.authenticated,
            user: refreshedUser,
            auth: auth,
          );
          return;
        }
      }

      // Jika semua gagal
      await SecureStorageService.clearAll();
      state = state.copyWith(status: AuthStatus.unauthenticated);
    } catch (e) {
      await SecureStorageService.clearAll();
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final auth = await _repository.login(email, password);
      final user = await _repository.getCurrentUser();
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        auth: auth,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _repository.logout();
    } catch (_) {
      await SecureStorageService.clearAll();
    } finally {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository);
});
