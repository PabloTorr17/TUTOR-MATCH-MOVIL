// lib/features/auth/data/auth_repository.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/constants/app_constants.dart';
import '../domain/models/user_model.dart';

class AuthRepository {
  final ApiClient _api = ApiClient();
  final _storage = const FlutterSecureStorage();

  Future<UserModel> register({
    required String email,
    required String password,
    required String fullName,
    required String career,
    required int semester,
  }) async {
    final response = await _api.post('/auth/register', data: {
      'email': email,
      'password': password,
      'full_name': fullName,
      'career': career,
      'semester': semester,
    });
    final data = response.data['data'];
    await _saveTokens(data['tokens']);
    return UserModel.fromJson(data['user']);
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _api.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    final data = response.data['data'];
    await _saveTokens(data['tokens']);
    return UserModel.fromJson(data['user']);
  }

  Future<UserModel?> getMe() async {
    try {
      final response = await _api.get('/auth/me');
      return UserModel.fromJson(response.data['data']);
    } catch (_) {
      return null;
    }
  }

  Future<UserModel> addRole(String role) async {
    final response = await _api.post('/auth/add-role', data: {'role': role});
    return UserModel.fromJson(response.data['data']);
  }

  Future<void> logout() async {
    await _storage.delete(key: AppConstants.accessTokenKey);
    await _storage.delete(key: AppConstants.refreshTokenKey);
  }

  Future<void> _saveTokens(Map<String, dynamic> tokens) async {
    await _storage.write(key: AppConstants.accessTokenKey, value: tokens['accessToken']);
    await _storage.write(key: AppConstants.refreshTokenKey, value: tokens['refreshToken']);
  }

  Future<bool> get isLoggedIn async {
    final token = await _storage.read(key: AppConstants.accessTokenKey);
    return token != null;
  }
}

// Provider
final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;

  AuthState({this.user, this.isLoading = false, this.error});

  bool get isAuthenticated => user != null;
  AuthState copyWith({UserModel? user, bool? isLoading, String? error}) =>
      AuthState(user: user ?? this.user, isLoading: isLoading ?? this.isLoading, error: error);
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;

  AuthNotifier(this._repo) : super(AuthState()) {
    _init();
  }

  Future<void> _init() async {
    state = AuthState(isLoading: true);
    final user = await _repo.getMe();
    state = AuthState(user: user);
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _repo.login(email: email, password: password);
      state = AuthState(user: user);
    } catch (e) {
      state = AuthState(error: _parseError(e));
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    required String career,
    required int semester,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _repo.register(
        email: email, password: password,
        fullName: fullName, career: career, semester: semester,
      );
      state = AuthState(user: user);
    } catch (e) {
      state = AuthState(error: _parseError(e));
    }
  }

  Future<void> addRole(String role) async {
    try {
      final updated = await _repo.addRole(role);
      state = AuthState(user: updated);
    } catch (e) {
      // ignore
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = AuthState();
  }

  void clearError() => state = state.copyWith(error: null);

  String _parseError(dynamic e) {
    try {
      return e.response?.data?['message'] ?? 'Error inesperado';
    } catch (_) {
      return 'Error de conexion';
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});
