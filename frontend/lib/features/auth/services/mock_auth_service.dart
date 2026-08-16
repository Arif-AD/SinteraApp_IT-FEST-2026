import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_role.dart';

const _authUserKey = 'auth_user';

/// Isolated mock authentication service.
///
/// Replace this class with a real [LaravelAuthService] later without changing
/// the Login UI or the rest of the application.
class MockAuthService {
  MockAuthService(this._ref);

  final Ref _ref;

  static Map<String, String> get _users => const {
        'w': '1',
        'p': '1',
        'k': '1',
      };

  static Map<String, UserRole> get _rolesByEmail => const {
        'w': UserRole.warga,
        'p': UserRole.petani,
        'k': UserRole.pengantar,
      };

  Future<AuthUser> login({
    required String emailOrUsername,
    required String password,
  }) async {
    final email = emailOrUsername.trim().toLowerCase();
    final expectedPassword = _users[email];

    if (expectedPassword == null || expectedPassword != password) {
      throw AuthException.invalidCredentials;
    }

    final matchedRole = _rolesByEmail[email];
    if (matchedRole == null) {
      throw AuthException.roleMismatch;
    }

    final user = AuthUser(
      id: email,
      email: email,
      name: email.split('@').first,
      role: matchedRole,
      token: 'mock-token-$email',
    );

    await _ref.read(authStorageProvider.notifier).save(user);
    return user;
  }

  Future<void> logout() async {
    await _ref.read(authStorageProvider.notifier).clear();
  }
}

class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.phone = '',
    this.address = '',
    this.detailHouse = '',
    this.latitude,
    this.longitude,
    this.profile,
    this.token,
  });

  final String id;
  final String email;
  final String name;
  final UserRole role;
  final String phone;
  final String address;
  final String detailHouse;
  final double? latitude;
  final double? longitude;
  final String? profile;
  final String? token;

  AuthUser copyWith({
    String? id,
    String? email,
    String? name,
    UserRole? role,
    String? phone,
    String? address,
    String? detailHouse,
    double? latitude,
    double? longitude,
    String? profile,
    String? token,
  }) {
    return AuthUser(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      detailHouse: detailHouse ?? this.detailHouse,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      profile: profile ?? this.profile,
      token: token ?? this.token,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role.name,
      'phone': phone,
      'address': address,
      'detail_house': detailHouse,
      'latitude': latitude,
      'longitude': longitude,
      'profile': profile,
      'token': token,
    };
  }

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      role: UserRole.values.firstWhere(
        (candidate) => candidate.name == json['role']?.toString(),
        orElse: () => UserRole.warga,
      ),
      phone: json['phone']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      detailHouse: json['detail_house']?.toString() ?? '',
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
      profile: json['profile']?.toString(),
      token: json['token']?.toString(),
    );
  }
}

enum AuthException {
  invalidCredentials,
  roleMismatch,
  networkError,
  custom;

  String get message {
    switch (this) {
      case AuthException.invalidCredentials:
        return 'Email/username atau password salah.';
      case AuthException.roleMismatch:
        return 'Role tidak sesuai dengan akun ini.';
      case AuthException.networkError:
        return 'Tidak dapat terhubung ke server. Pastikan backend berjalan di http://127.0.0.1:8000.';
      case AuthException.custom:
        return 'Terjadi kesalahan saat memproses permintaan.';
    }
  }
}

class AuthStorageNotifier extends StateNotifier<AsyncValue<AuthUser?>> {
  AuthStorageNotifier() : super(const AsyncValue.loading()) {
    _loadPersistedUser();
  }

  Future<void> _loadPersistedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_authUserKey);
    if (jsonString == null || jsonString.isEmpty) {
      state = const AsyncValue.data(null);
      return;
    }

    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final user = AuthUser.fromJson(data);
      state = AsyncValue.data(user);
    } catch (_) {
      await prefs.remove(_authUserKey);
      state = const AsyncValue.data(null);
    }
  }

  Future<void> save(AuthUser user) async {
    final prefs = await SharedPreferences.getInstance();
    final persistedUser = user.token == null && state.value?.token != null
        ? user.copyWith(token: state.value?.token)
        : user;
    await prefs.setString(_authUserKey, jsonEncode(persistedUser.toJson()));
    state = AsyncValue.data(persistedUser);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_authUserKey);
    state = const AsyncValue.data(null);
  }
}

final authStorageProvider =
    StateNotifierProvider<AuthStorageNotifier, AsyncValue<AuthUser?>>(
  (_) => AuthStorageNotifier(),
);

final mockAuthServiceProvider = Provider<MockAuthService>((ref) {
  return MockAuthService(ref);
});
