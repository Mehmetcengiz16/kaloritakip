import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/network/api_client.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.isPremium,
    required this.onboardingCompleted,
    this.profile,
  });

  final int id;
  final String name;
  final String email;
  final bool isPremium;
  final bool onboardingCompleted;
  final Map<String, dynamic>? profile;

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
    id: j['id'] as int,
    name: j['name'] as String,
    email: j['email'] as String,
    isPremium: j['is_premium'] as bool? ?? false,
    onboardingCompleted: j['onboarding_completed'] as bool? ?? false,
    profile: j['profile'] as Map<String, dynamic>?,
  );
}

class AuthRepository {
  AuthRepository(this._dio, this._storage);

  final Dio _dio;
  final FlutterSecureStorage _storage;

  Future<bool> hasToken() async => await _storage.read(key: 'token') != null;

  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
  }) => _authenticate('/auth/register', {
    'name': name,
    'email': email,
    'password': password,
  });

  Future<AppUser> login({required String email, required String password}) =>
      _authenticate('/auth/login', {'email': email, 'password': password});

  Future<AppUser> me() async {
    final res = await _dio.get<Map<String, dynamic>>('/me');
    return AppUser.fromJson(res.data!['data'] as Map<String, dynamic>);
  }

  Future<AppUser> submitOnboarding(Map<String, dynamic> data) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/onboarding',
      data: data,
    );
    return AppUser.fromJson(res.data!['data'] as Map<String, dynamic>);
  }

  Future<AppUser> updateProfile(Map<String, dynamic> data) async {
    final res = await _dio.put<Map<String, dynamic>>('/me', data: data);
    return AppUser.fromJson(res.data!['data'] as Map<String, dynamic>);
  }

  /// Hesabı ve tüm verileri kalıcı olarak siler (KVKK / App Store zorunluluğu).
  Future<void> deleteAccount() async {
    await _dio.delete<void>('/me');
    await _storage.delete(key: 'token');
  }

  Future<void> logout() async {
    try {
      await _dio.post<void>('/auth/logout');
    } on DioException {
      // Sunucuya ulaşılamasa da yerel oturum kapatılır.
    }
    await _storage.delete(key: 'token');
  }

  Future<AppUser> _authenticate(String path, Map<String, dynamic> body) async {
    final res = await _dio.post<Map<String, dynamic>>(
      path,
      data: {...body, 'device_name': 'mobile'},
    );
    await _storage.write(key: 'token', value: res.data!['token'] as String);
    return AppUser.fromJson(res.data!['user'] as Map<String, dynamic>);
  }
}

final authRepositoryProvider = Provider(
  (ref) =>
      AuthRepository(ref.watch(dioProvider), ref.watch(secureStorageProvider)),
);

/// Profil ekranları için sunucudaki güncel kullanıcı.
class MeNotifier extends AsyncNotifier<AppUser> {
  @override
  Future<AppUser> build() => ref.watch(authRepositoryProvider).me();

  Future<void> save(Map<String, dynamic> changes) async {
    state = AsyncData(
      await ref.read(authRepositoryProvider).updateProfile(changes),
    );
  }
}

final meProvider = AsyncNotifierProvider.autoDispose<MeNotifier, AppUser>(
  MeNotifier.new,
);

/// Oturumdaki kullanıcı. null = giriş yapılmamış.
class SessionNotifier extends Notifier<AppUser?> {
  @override
  AppUser? build() => null;

  void set(AppUser? user) => state = user;
}

final sessionProvider = NotifierProvider<SessionNotifier, AppUser?>(
  SessionNotifier.new,
);
