import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../constants/api_constants.dart';
import '../../shopping/models/shopping_product_model.dart';
import '../models/user_role.dart';
import '../providers/auth_provider.dart';
import 'mock_auth_service.dart';

class LaravelAuthService {
  LaravelAuthService(this._ref) {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.apiBaseUrl,
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ));

    _ref.listen<AsyncValue<AuthUser?>>(authStorageProvider, (_, next) {
      final savedToken = next.value?.token;
      if (savedToken != null && savedToken.isNotEmpty) {
        _setToken(savedToken);
      } else {
        _clearToken();
      }
    }, fireImmediately: true);
  }

  final Ref _ref;
  late final Dio _dio;
  String? _token;

  void _setToken(String token) {
    _token = token;
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void _clearToken() {
    _token = null;
    _dio.options.headers.remove('Authorization');
  }

  Future<AuthUser> login({
    required String emailOrUsername,
    required String password,
  }) async {
    try {
      final normalizedEmailOrUsername = emailOrUsername.trim();
      final preparedLogin = normalizedEmailOrUsername.contains('@')
          ? normalizedEmailOrUsername.toLowerCase()
          : normalizedEmailOrUsername;

      final response = await _dio.post(
        '/auth/login',
        data: {
          'email': preparedLogin,
          'password': password,
        },
      );

      final responseData = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};

      if (response.statusCode != 200 || responseData['data'] == null) {
        throw AuthException.invalidCredentials;
      }

      final data = responseData['data'] as Map<String, dynamic>;
      final token = data['token'] as String;
      _setToken(token);

      final backendRoleName = data['user'] is Map<String, dynamic>
          ? (data['user'] as Map<String, dynamic>)['role'] as String?
          : null;
      final resolvedRole = backendRoleName != null
          ? UserRole.values.firstWhere(
              (candidate) => candidate.name == backendRoleName,
              orElse: () => UserRole.warga,
            )
          : UserRole.warga;

      final userData = data['user'] as Map<String, dynamic>;
      final user = AuthUser(
        id: userData['id'].toString(),
        email: userData['email'] as String,
        name: userData['name'] as String,
        role: resolvedRole,
        phone: (userData['phone'] ?? userData['no_hp'] ?? '').toString(),
        address: (userData['address'] ?? userData['alamat'] ?? '').toString(),
        detailHouse: (userData['detail_house'] ?? '').toString(),
        latitude: (userData['latitude'] != null)
            ? double.tryParse(userData['latitude'].toString())
            : (userData['lat'] != null ? double.tryParse(userData['lat'].toString()) : null),
        longitude: (userData['longitude'] != null)
            ? double.tryParse(userData['longitude'].toString())
            : (userData['lon'] != null ? double.tryParse(userData['lon'].toString()) : null),
        token: token,
      );

      await _ref.read(authStorageProvider.notifier).save(user);
      return user;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw AuthException.invalidCredentials;
      }
      if (e.response?.statusCode == 403) {
        throw AuthException.roleMismatch;
      }
      throw AuthException.networkError;
    }
  }

  Future<AuthUser> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String passwordConfirmation,
    required UserRole role,
  }) async {
    try {
      final preparedEmail = email.trim().toLowerCase();

      final response = await _dio.post(
        '/auth/register',
        data: {
          'name': name,
          'email': preparedEmail,
          'phone': phone,
          'password': password,
          'password_confirmation': passwordConfirmation,
          'role': role.name,
        },
      );

      final responseData = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};

      if (response.statusCode != 201 || responseData['data'] == null) {
        throw AuthException.networkError;
      }

      final data = responseData['data'] as Map<String, dynamic>;
      final token = data['token'] as String;
      _setToken(token);

      final userData = data['user'] as Map<String, dynamic>;
      final resolvedRole = UserRole.values.firstWhere(
        (candidate) => candidate.name == (userData['role'] as String? ?? role.name),
        orElse: () => role,
      );

      final user = AuthUser(
        id: userData['id'].toString(),
        email: userData['email'] as String,
        name: userData['name'] as String,
        role: resolvedRole,
        phone: (userData['phone'] ?? userData['no_hp'] ?? '').toString(),
        address: (userData['address'] ?? userData['alamat'] ?? '').toString(),
        detailHouse: (userData['detail_house'] ?? '').toString(),
        latitude: (userData['latitude'] != null)
            ? double.tryParse(userData['latitude'].toString())
            : (userData['lat'] != null ? double.tryParse(userData['lat'].toString()) : null),
        longitude: (userData['longitude'] != null)
            ? double.tryParse(userData['longitude'].toString())
            : (userData['lon'] != null ? double.tryParse(userData['lon'].toString()) : null),
        token: token,
      );

      await _ref.read(authStorageProvider.notifier).save(user);
      return user;
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        final responseData = e.response?.data is Map<String, dynamic>
            ? e.response!.data as Map<String, dynamic>
            : <String, dynamic>{};
        final errors = responseData['errors'];
        if (errors is Map<String, dynamic>) {
          final firstError = errors.values
              .expand((value) => value is List ? value : [value])
              .cast<String>()
              .firstWhere((_) => true, orElse: () => 'Registrasi gagal.');
          throw Exception(firstError);
        }
        throw AuthException.networkError;
      }
      throw AuthException.networkError;
    }
  }

  Future<Map<String, int>> getAboutAppStats() async {
    if (_token == null) {
      throw AuthException.invalidCredentials;
    }

    try {
      final response = await _dio.get('/about-app/stats');
      final responseData = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};

      if (response.statusCode != 200 || responseData['data'] == null) {
        throw AuthException.networkError;
      }

      final data = responseData['data'] as Map<String, dynamic>;
      return {
        'total_users': int.tryParse((data['total_users'] ?? 0).toString()) ?? 0,
        'warga': int.tryParse((data['warga'] ?? 0).toString()) ?? 0,
        'petani': int.tryParse((data['petani'] ?? 0).toString()) ?? 0,
        'pengantar': int.tryParse((data['pengantar'] ?? 0).toString()) ?? 0,
      };
    } on DioException catch (e) {
      final message = e.response?.data is String
          ? e.response!.data as String
          : (e.response?.data is Map<String, dynamic>
              ? (e.response!.data as Map<String, dynamic>)['message']?.toString() ?? 'Gagal mengambil statistik aplikasi.'
              : 'Gagal mengambil statistik aplikasi.');
      throw Exception(message);
    }
  }

  Future<AuthUser> fetchProfile() async {
    if (_token == null) {
      throw AuthException.invalidCredentials;
    }

    final response = await _dio.get('/me');
    final responseData = response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : <String, dynamic>{};

    if (response.statusCode != 200 || responseData['data'] == null) {
      throw AuthException.networkError;
    }

    final data = responseData['data'] as Map<String, dynamic>;
    final backendRoleName = data['role'] as String?;
    final resolvedRole = backendRoleName != null
        ? UserRole.values.firstWhere(
            (candidate) => candidate.name == backendRoleName,
            orElse: () => UserRole.warga,
          )
        : UserRole.warga;

    final user = AuthUser(
      id: data['id'].toString(),
      email: data['email'] as String,
      name: data['name'] as String,
      role: resolvedRole,
      phone: (data['phone'] ?? data['no_hp'] ?? '').toString(),
      address: (data['address'] ?? data['alamat'] ?? '').toString(),
      detailHouse: (data['detail_house'] ?? '').toString(),
      latitude: (data['latitude'] != null)
          ? double.tryParse(data['latitude'].toString())
          : (data['lat'] != null ? double.tryParse(data['lat'].toString()) : null),
      longitude: (data['longitude'] != null)
          ? double.tryParse(data['longitude'].toString())
          : (data['lon'] != null ? double.tryParse(data['lon'].toString()) : null),
      profile: (data['profile'] ?? data['avatar'] ?? '').toString().trim().isNotEmpty
          ? (data['profile'] ?? data['avatar']).toString()
          : null,
      token: _token,
    );

    await _ref.read(authStorageProvider.notifier).save(user);
    return user;
  }

  Future<int> getNetBalance() async {
    if (_token == null) {
      throw AuthException.invalidCredentials;
    }

    try {
      final response = await _dio.get('/wallet');
      final responseData = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};

      if (response.statusCode != 200 || responseData['data'] == null) {
        throw AuthException.networkError;
      }

      final data = responseData['data'] as Map<String, dynamic>;
      final balanceValue = data['balance'] ?? data['amount'] ?? data['total_balance'] ?? data['net_balance'];
      if (balanceValue is num) {
        return balanceValue.toInt();
      }

      return int.tryParse(balanceValue?.toString() ?? '0') ?? 0;
    } on DioException catch (e) {
      final message = e.response?.data is String
          ? e.response!.data as String
          : (e.response?.data is Map<String, dynamic>
              ? (e.response!.data as Map<String, dynamic>)['message']?.toString() ?? 'Gagal mengambil saldo.'
              : 'Gagal mengambil saldo.');
      throw Exception(message);
    }
  }

  Future<int> _calculateDeliveryIncome() async {
    final tasks = await getDeliveryTasks();
    return (tasks as List).where((t) {
      final status = (t['status'] ?? '').toString().toLowerCase();
      return status == 'completed' || status == 'selesai' || status == 'delivered';
    }).fold<int>(0, (sum, t) {
      final order = t['order'] as Map<String, dynamic>?;
      num distanceFee = 0;
      try {
        final distanceValue = order?['distance_fee'];
        distanceFee = distanceValue is num ? distanceValue : num.parse(distanceValue?.toString() ?? '0');
      } catch (_) {
        distanceFee = 0;
      }
      num baseFee = 0;
      try {
        final baseValue = order?['base_fee'];
        baseFee = baseValue is num ? baseValue : num.parse(baseValue?.toString() ?? '0');
      } catch (_) {
        baseFee = 0;
      }
      return sum + (distanceFee + (baseFee / 2)).round();
    });
  }

  Future<int> _calculateFarmerIncome() async {
    final orders = await getFarmerOrders();
    return (orders as List).where((o) {
      final s = (o['status'] ?? '').toString().toLowerCase();
      final d = (o['delivery_status'] ?? '').toString().toLowerCase();
      return s == 'completed' || s == 'selesai' || d == 'delivered' || d == 'selesai';
    }).fold<int>(0, (sum, o) {
      num total = 0;
      try {
        final totalValue = o['total_amount'];
        total = totalValue is num ? totalValue : num.parse(totalValue?.toString() ?? '0');
      } catch (_) {
        total = 0;
      }
      num baseFee = 0;
      try {
        final baseValue = o['base_fee'];
        baseFee = baseValue is num ? baseValue : num.parse(baseValue?.toString() ?? '0');
      } catch (_) {
        baseFee = 0;
      }
      num farmerSubsidy = 0;
      try {
        final subsidyValue = o['farmer_subsidy'];
        farmerSubsidy = subsidyValue is num ? subsidyValue : num.parse(subsidyValue?.toString() ?? '0');
      } catch (_) {
        farmerSubsidy = 0;
      }
      return sum + (total + (baseFee / 2) - farmerSubsidy).round();
    });
  }

  Future<int> getNetBalanceWithFallback() async {
    try {
      final balance = await getNetBalance();
      if (balance > 0) {
        return balance;
      }
    } catch (_) {
      // ignored, fallback to transaction calculation
    }

    final role = _ref.read(authStorageProvider).value?.role;
    if (role == UserRole.pengantar) {
      return _calculateDeliveryIncome();
    }
    if (role == UserRole.petani) {
      return _calculateFarmerIncome();
    }
    return 0;
  }

  Future<List<Map<String, dynamic>>> getNotifications() async {
    if (_token == null) {
      throw AuthException.invalidCredentials;
    }

    try {
      final response = await _dio.get('/notifications');
      final responseData = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};

      if (response.statusCode != 200) {
        throw AuthException.networkError;
      }

      final data = responseData['data'];
      if (data is List) {
        return data.whereType<Map<String, dynamic>>().toList();
      }

      return const <Map<String, dynamic>>[];
    } on DioException catch (e) {
      final message = e.response?.data is String
          ? e.response!.data as String
          : (e.response?.data is Map<String, dynamic>
              ? (e.response!.data as Map<String, dynamic>)['message']?.toString() ?? 'Gagal mengambil notifikasi.'
              : 'Gagal mengambil notifikasi.');
      throw Exception(message);
    }
  }

  Future<Map<String, dynamic>> markNotificationAsRead(String id) async {
    if (_token == null) {
      throw AuthException.invalidCredentials;
    }

    try {
      final response = await _dio.post('/notifications/$id/read');
      final responseData = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};

      if (response.statusCode != 200 || responseData['data'] == null) {
        throw AuthException.networkError;
      }

      return responseData['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      final message = e.response?.data is String
          ? e.response!.data as String
          : (e.response?.data is Map<String, dynamic>
              ? (e.response!.data as Map<String, dynamic>)['message']?.toString() ?? 'Gagal menandai notifikasi.'
              : 'Gagal menandai notifikasi.');
      throw Exception(message);
    }
  }

  Future<void> deleteNotification(String id) async {
    if (_token == null) {
      throw AuthException.invalidCredentials;
    }

    try {
      final response = await _dio.delete('/notifications/$id');
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw AuthException.networkError;
      }
    } on DioException catch (e) {
      final message = e.response?.data is String
          ? e.response!.data as String
          : (e.response?.data is Map<String, dynamic>
              ? (e.response!.data as Map<String, dynamic>)['message']?.toString() ?? 'Gagal menghapus notifikasi.'
              : 'Gagal menghapus notifikasi.');
      throw Exception(message);
    }
  }

  Future<Map<String, dynamic>?> getOrderDetailById(String id) async {
    if (_token == null) {
      throw AuthException.invalidCredentials;
    }

    try {
      final wargaOrders = await getWargaOrders();
      final farmerOrders = await getFarmerOrders();
      final combined = [...wargaOrders, ...farmerOrders];

      for (final order in combined) {
        if (order['id']?.toString() == id) {
          return order.cast<String, dynamic>();
        }
      }

      return null;
    } on DioException catch (e) {
      final message = e.response?.data is String
          ? e.response!.data as String
          : (e.response?.data is Map<String, dynamic>
              ? (e.response!.data as Map<String, dynamic>)['message']?.toString() ?? 'Gagal mengambil detail pesanan.'
              : 'Gagal mengambil detail pesanan.');
      throw Exception(message);
    }
  }

  Future<void> logout() async {
    if (_token == null) return;
    await _dio.post('/auth/logout');
    _token = null;
    await _ref.read(authStorageProvider.notifier).clear();
  }

  Future<Map<String, dynamic>> createFarmerProduct(Map<String, dynamic> data) async {
    if (_token == null) {
      throw AuthException.invalidCredentials;
    }

    try {
      final response = await _dio.post('/farmer/products', data: data);
      final responseData = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};

      if (response.statusCode != 201 || responseData['data'] == null) {
        throw AuthException.networkError;
      }

      return responseData['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      final message = e.response?.data is String
          ? e.response!.data as String
          : (e.response?.data is Map<String, dynamic>
              ? (e.response!.data as Map<String, dynamic>)['message']?.toString() ?? 'Gagal menambah produk.'
              : 'Gagal menambah produk.');
      throw Exception(message);
    }
  }

  Future<List<Map<String, dynamic>>> getFarmerProducts() async {
    if (_token == null) {
      throw AuthException.invalidCredentials;
    }

    try {
      final response = await _dio.get('/farmer/products');
      final responseData = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};

      if (response.statusCode != 200) {
        throw AuthException.networkError;
      }

      final data = responseData['data'];
      if (data is List) {
        return data.whereType<Map<String, dynamic>>().toList();
      }

      return const <Map<String, dynamic>>[];
    } on DioException catch (e) {
      final message = e.response?.data is String
          ? e.response!.data as String
          : (e.response?.data is Map<String, dynamic>
              ? (e.response!.data as Map<String, dynamic>)['message']?.toString() ?? 'Gagal mengambil produk.'
              : 'Gagal mengambil produk.');
      throw Exception(message);
    }
  }

  String _resolveFarmerAddress(Map<String, dynamic> item) {
    final directAddress = item['farmer_address']?.toString().trim();
    if (directAddress != null && directAddress.isNotEmpty) {
      return directAddress;
    }

    final farmer = item['farmer'];
    if (farmer is Map<String, dynamic>) {
      final user = farmer['user'];
      if (user is Map<String, dynamic>) {
        final userAddress = user['address'];
        if (userAddress is Map<String, dynamic>) {
          final nestedAddress = (userAddress['address'] ?? '').toString().trim();
          if (nestedAddress.isNotEmpty) {
            return nestedAddress;
          }
        }
      }
    }

    return '';
  }

  String _resolveFarmerDetailHouse(Map<String, dynamic> item) {
    final directDetailHouse = item['farmer_detail_house']?.toString().trim();
    if (directDetailHouse != null && directDetailHouse.isNotEmpty) {
      return directDetailHouse;
    }

    final farmer = item['farmer'];
    if (farmer is Map<String, dynamic>) {
      final user = farmer['user'];
      if (user is Map<String, dynamic>) {
        final userAddress = user['address'];
        if (userAddress is Map<String, dynamic>) {
          final nestedDetailHouse = (userAddress['detail_house'] ?? '').toString().trim();
          if (nestedDetailHouse.isNotEmpty) {
            return nestedDetailHouse;
          }
        }
      }
    }

    return '';
  }

  Future<List<ShoppingProduct>> getWargaProducts() async {
    if (_token == null) {
      throw AuthException.invalidCredentials;
    }

    try {
      final response = await _dio.get('/warga/products');
      final responseData = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};

      if (response.statusCode != 200) {
        throw AuthException.networkError;
      }

      final data = responseData['data'];
      if (data is! List) {
        return const <ShoppingProduct>[];
      }

      return data.whereType<Map<String, dynamic>>().map((item) {
        final price = (item['price'] as num?)?.toInt() ?? 0;
        final category = (item['category']?.toString() ?? 'sayur').toLowerCase();
        final displayCategory = category == 'buah' ? 'Buah' : 'Sayur';
        final farmerNameValue = item['farmer_name']?.toString().trim();
        final farmerName = (farmerNameValue != null && farmerNameValue.isNotEmpty)
            ? farmerNameValue
            : item['farmer'] is Map<String, dynamic>
                ? (() {
                    final farmer = item['farmer'] as Map<String, dynamic>;
                    final user = farmer['user'];
                    if (user is Map<String, dynamic>) {
                      final userName = user['name']?.toString().trim();
                      if (userName != null && userName.isNotEmpty) {
                        return userName;
                      }
                    }
                    final farmName = farmer['farm_name']?.toString().trim();
                    return farmName != null && farmName.isNotEmpty ? farmName : 'Petani Lokal';
                  })()
                : 'Petani Lokal';

        final shippingPreview = item['shipping_preview'];
        final shippingBaseFee = (shippingPreview is Map<String, dynamic>
                ? (shippingPreview['base_fee'] as num?)?.toInt()
                : (item['base_fee'] as num?)?.toInt()) ??
            0;
        final shippingDistanceFee = (shippingPreview is Map<String, dynamic>
                ? (shippingPreview['distance_fee'] as num?)?.toInt()
                : (item['distance_fee'] as num?)?.toInt()) ??
            0;
        final shippingFarmerSubsidy = (shippingPreview is Map<String, dynamic>
                ? (shippingPreview['farmer_subsidy'] as num?)?.toInt()
                : (item['farmer_subsidy'] as num?)?.toInt()) ??
            0;
        final shippingCustomerShipping = (shippingPreview is Map<String, dynamic>
                ? (shippingPreview['customer_shipping'] as num?)?.toInt()
                : (item['customer_shipping'] as num?)?.toInt()) ??
            0;
        final shippingDistanceKm = (shippingPreview is Map<String, dynamic>
                ? (shippingPreview['shipping_distance_km'] as num?)?.toDouble()
                : (item['shipping_distance_km'] as num?)?.toDouble()) ??
            0.0;
        final shippingNote = shippingPreview is Map<String, dynamic>
                ? shippingPreview['shipping_note']?.toString()
                : item['shipping_note']?.toString() ??
                    'Biaya pengiriman dihitung otomatis berdasarkan jarak.';

        final imageUrl = (item['image'] ?? item['image_url'])?.toString().trim();
        final farmerProfileImageUrl = (() {
          final directProfile = item['farmer_profile']?.toString().trim();
          if (directProfile != null && directProfile.isNotEmpty) {
            return directProfile;
          }

          final fallbackProfile = item['profile']?.toString().trim();
          if (fallbackProfile != null && fallbackProfile.isNotEmpty) {
            return fallbackProfile;
          }

          final farmer = item['farmer'];
          if (farmer is Map<String, dynamic>) {
            final nestedUser = farmer['user'];
            if (nestedUser is Map<String, dynamic>) {
              final nestedProfile = nestedUser['profile']?.toString().trim();
              if (nestedProfile != null && nestedProfile.isNotEmpty) {
                return nestedProfile;
              }
            }
          }

          return null;
        })();
        final productDescription = (item['description'] ?? item['product_description'])?.toString().trim();
        // resolve discount if provided by backend, otherwise null
        final discountValue = () {
          if (item['discount'] != null) {
            final raw = item['discount'];
            if (raw is int) return raw;
            if (raw is String) return int.tryParse(raw);
          }
          return null;
        }();

        final rawRating = item['rating'];
        String ratingValue = '0';
        if (rawRating != null) {
          if (rawRating is num) {
            ratingValue = rawRating % 1 == 0 ? rawRating.toStringAsFixed(0) : rawRating.toStringAsFixed(1);
          } else {
            ratingValue = rawRating.toString();
          }
        }

        return ShoppingProduct(
          id: item['id']?.toString() ?? '',
          sellerId: item['farmer_id']?.toString() ?? (item['farmer'] is Map<String, dynamic> ? (item['farmer'] as Map<String, dynamic>)['id']?.toString() : null),
          name: item['name']?.toString() ?? 'Produk',
          farmerName: farmerName,
          farmerProfileImageUrl: farmerProfileImageUrl != null && farmerProfileImageUrl.isNotEmpty ? farmerProfileImageUrl : null,
          price: 'Rp${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
          originalPrice: 'Rp${(price + 1000).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
          unit: item['unit']?.toString() ?? 'kg',
          discount: discountValue,
          rating: ratingValue,
          sold: '${item['stock'] ?? 0} Tersedia',
          category: displayCategory,
          imageAsset: 'assets/images/icon/icon_belanja.png',
          imageUrl: imageUrl != null && imageUrl.isNotEmpty ? imageUrl : null,
          description: productDescription != null && productDescription.isNotEmpty ? productDescription : null,
          availableUntil: item['available_until']?.toString(),
          updatedAt: (item['updated_at'] ?? item['created_at'])?.toString(),
          farmerAddress: _resolveFarmerAddress(item),
          farmerDetailHouse: _resolveFarmerDetailHouse(item),
          shippingBaseFee: shippingBaseFee,
          shippingDistanceFee: shippingDistanceFee,
          shippingFarmerSubsidy: shippingFarmerSubsidy,
          shippingCustomerShipping: shippingCustomerShipping,
          shippingDistanceKm: shippingDistanceKm,
          shippingNote: shippingNote ?? 'Biaya pengiriman dihitung otomatis berdasarkan jarak.',
        );
      }).toList();
    } on DioException catch (e) {
      final message = e.response?.data is String
          ? e.response!.data as String
          : (e.response?.data is Map<String, dynamic>
              ? (e.response!.data as Map<String, dynamic>)['message']?.toString() ?? 'Gagal mengambil produk warga.'
              : 'Gagal mengambil produk warga.');
      throw Exception(message);
    }
  }

  Future<List<Map<String, dynamic>>> getWargaRecipients() async {
    if (_token == null) {
      throw AuthException.invalidCredentials;
    }

    try {
      final response = await _dio.get('/warga/recipients');
      final responseData = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};

      if (response.statusCode != 200) {
        throw AuthException.networkError;
      }

      final data = responseData['data'];
      if (data is! List) {
        return const <Map<String, dynamic>>[];
      }

      return data.whereType<Map<String, dynamic>>().toList();
    } on DioException catch (e) {
      final message = e.response?.data is String
          ? e.response!.data as String
          : (e.response?.data is Map<String, dynamic>
              ? (e.response?.data as Map<String, dynamic>)['message']?.toString() ?? 'Gagal mengambil penerima warga.'
              : 'Gagal mengambil penerima warga.');
      throw Exception(message);
    }
  }

  Future<Map<String, dynamic>> updateFarmerProduct(String id, Map<String, dynamic> data) async {
    if (_token == null) {
      throw AuthException.invalidCredentials;
    }

    try {
      final response = await _dio.put('/farmer/products/$id', data: data);
      final responseData = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};

      if (response.statusCode != 200 || responseData['data'] == null) {
        throw AuthException.networkError;
      }

      return responseData['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      final message = e.response?.data is String
          ? e.response!.data as String
          : (e.response?.data is Map<String, dynamic>
              ? (e.response!.data as Map<String, dynamic>)['message']?.toString() ?? 'Gagal memperbarui produk.'
              : 'Gagal memperbarui produk.');
      throw Exception(message);
    }
  }

  Future<void> deleteFarmerProduct(String id) async {
    if (_token == null) {
      throw AuthException.invalidCredentials;
    }

    try {
      final response = await _dio.delete('/farmer/products/$id');
      final responseData = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw AuthException.networkError;
      }

      final deleted = responseData['data'] is Map<String, dynamic>
          ? (responseData['data'] as Map<String, dynamic>)['deleted'] == true
          : true;

      if (!deleted) {
        throw Exception('Produk tidak berhasil dihapus dari server.');
      }
    } on DioException catch (e) {
      final message = e.response?.data is String
          ? e.response!.data as String
          : (e.response?.data is Map<String, dynamic>
              ? (e.response!.data as Map<String, dynamic>)['message']?.toString() ?? 'Gagal menghapus produk.'
              : 'Gagal menghapus produk.');
      throw Exception(message);
    }
  }

  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> data) async {
    if (_token == null) {
      throw AuthException.invalidCredentials;
    }

    try {
      final response = await _dio.post('/warga/orders', data: data);
      final responseData = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};

      if (response.statusCode != 201 || responseData['data'] == null) {
        throw AuthException.networkError;
      }

      return responseData['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      final message = e.response?.data is String
          ? e.response!.data as String
          : (e.response?.data is Map<String, dynamic>
              ? (e.response!.data as Map<String, dynamic>)['message']?.toString() ?? 'Gagal membuat pesanan.'
              : 'Gagal membuat pesanan.');
      throw Exception(message);
    }
  }

  Future<Map<String, dynamic>> getWargaPoints() async {
    if (_token == null) {
      throw AuthException.invalidCredentials;
    }

    try {
      final response = await _dio.get('/warga/points');
      final responseData = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};

      if (response.statusCode != 200 || responseData['data'] == null) {
        throw AuthException.networkError;
      }

      return responseData['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      final message = e.response?.data is String
          ? e.response!.data as String
          : (e.response?.data is Map<String, dynamic>
              ? (e.response!.data as Map<String, dynamic>)['message']?.toString() ?? 'Gagal mengambil poin warga.'
              : 'Gagal mengambil poin warga.');
      throw Exception(message);
    }
  }

  Future<void> deductWargaPoints(int points, {String? reason}) async {
    if (_token == null) {
      throw AuthException.invalidCredentials;
    }

    try {
      final response = await _dio.post('/warga/points/deduct', data: {
        'points': points,
        if (reason != null) 'reason': reason,
      });

      if (response.statusCode != 200) {
        throw Exception('Gagal mengurangi poin.');
      }
    } on DioException catch (e) {
      final message = e.response?.data is String
          ? e.response!.data as String
          : (e.response?.data is Map<String, dynamic>
              ? (e.response!.data as Map<String, dynamic>)['message']?.toString() ?? 'Gagal mengurangi poin.'
              : 'Gagal mengurangi poin.');
      throw Exception(message);
    }
  }

  Future<List<Map<String, dynamic>>> getWargaPointTransactions() async {
    if (_token == null) {
      throw AuthException.invalidCredentials;
    }

    try {
      final response = await _dio.get('/warga/points/transactions');
      final responseData = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};

      if (response.statusCode != 200 || responseData['data'] == null) {
        throw AuthException.networkError;
      }

      final data = responseData['data'];
      if (data is List) {
        return data.whereType<Map<String, dynamic>>().toList();
      }

      return const <Map<String, dynamic>>[];
    } on DioException catch (e) {
      final message = e.response?.data is String
          ? e.response!.data as String
          : (e.response?.data is Map<String, dynamic>
              ? (e.response?.data as Map<String, dynamic>)['message']?.toString() ?? 'Gagal mengambil riwayat poin.'
              : 'Gagal mengambil riwayat poin.');
      throw Exception(message);
    }
  }

  Future<List<Map<String, dynamic>>> getWargaOrders() async {
    if (_token == null) {
      throw AuthException.invalidCredentials;
    }

    try {
      final response = await _dio.get('/warga/orders');
      final responseData = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};

      if (response.statusCode != 200) {
        throw AuthException.networkError;
      }

      final data = responseData['data'];
      if (data is List) {
        return data.whereType<Map<String, dynamic>>().toList();
      }

      return const <Map<String, dynamic>>[];
    } on DioException catch (e) {
      final message = e.response?.data is String
          ? e.response!.data as String
          : (e.response?.data is Map<String, dynamic>
              ? (e.response!.data as Map<String, dynamic>)['message']?.toString() ?? 'Gagal mengambil pesanan.'
              : 'Gagal mengambil pesanan.');
      throw Exception(message);
    }
  }

  Future<List<Map<String, dynamic>>> getFarmerOrders() async {
    if (_token == null) {
      throw AuthException.invalidCredentials;
    }

    try {
      final response = await _dio.get('/farmer/orders');
      final responseData = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};

      if (response.statusCode != 200) {
        throw AuthException.networkError;
      }

      final data = responseData['data'];
      if (data is List) {
        return data.whereType<Map<String, dynamic>>().toList();
      }

      return const <Map<String, dynamic>>[];
    } on DioException catch (e) {
      final message = e.response?.data is String
          ? e.response!.data as String
          : (e.response?.data is Map<String, dynamic>
              ? (e.response!.data as Map<String, dynamic>)['message']?.toString() ?? 'Gagal mengambil pesanan petani.'
              : 'Gagal mengambil pesanan petani.');
      throw Exception(message);
    }
  }

  Future<Map<String, dynamic>> processFarmerOrder(String id) async {
    if (_token == null) {
      throw AuthException.invalidCredentials;
    }

    try {
      final response = await _dio.post('/farmer/orders/$id/process');
      final responseData = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};

      if (response.statusCode != 200 || responseData['data'] == null) {
        throw AuthException.networkError;
      }

      return responseData['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      final statusData = e.response?.data;
      String message;
      if (statusData is String) {
        message = statusData;
      } else if (statusData is Map<String, dynamic>) {
        final base = statusData['message']?.toString() ?? 'Gagal memproses pesanan.';
        final detail = statusData['error']?.toString();
        message = detail != null && detail.isNotEmpty ? '$base: $detail' : base;
      } else {
        message = 'Gagal memproses pesanan.';
      }

      throw Exception(message);
    }
  }

  Future<Map<String, dynamic>> cancelFarmerOrder(String id) async {
    if (_token == null) {
      throw AuthException.invalidCredentials;
    }

    try {
      final response = await _dio.post('/farmer/orders/$id/cancel');
      final responseData = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};

      if (response.statusCode != 200 || responseData['data'] == null) {
        throw AuthException.networkError;
      }

      return responseData['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      final statusData = e.response?.data;
      String message;
      if (statusData is String) {
        message = statusData;
      } else if (statusData is Map<String, dynamic>) {
        final base = statusData['message']?.toString() ?? 'Gagal membatalkan pesanan.';
        final detail = statusData['error']?.toString();
        message = detail != null && detail.isNotEmpty ? '$base: $detail' : base;
      } else {
        message = 'Gagal membatalkan pesanan.';
      }

      throw Exception(message);
    }
  }

  Future<List<Map<String, dynamic>>> getOrderChatMessages(
    String id, {
    String orderType = 'order',
    String? chatChannel,
  }) async {
    if (_token == null) {
      throw AuthException.invalidCredentials;
    }

    try {
      final queryParameters = <String, dynamic>{};
      if (chatChannel != null && chatChannel.isNotEmpty) {
        queryParameters['channel'] = chatChannel;
      }
      final response = await _dio.get(
        '/orders/$orderType/$id/chat',
        queryParameters: queryParameters,
      );
      final responseData = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};

      if (response.statusCode != 200) {
        throw AuthException.networkError;
      }

      final data = responseData['data'];
      if (data is Map<String, dynamic> && data['messages'] is List) {
        return (data['messages'] as List)
            .whereType<Map<String, dynamic>>()
            .toList();
      }

      return const <Map<String, dynamic>>[];
    } on DioException catch (e) {
      final message = e.response?.data is String
          ? e.response!.data as String
          : (e.response?.data is Map<String, dynamic>
              ? (e.response?.data as Map<String, dynamic>)['message']?.toString() ?? 'Gagal memuat pesan chat.'
              : 'Gagal memuat pesan chat.');
      throw Exception(message);
    }
  }

  Future<Map<String, dynamic>> sendOrderChatMessage(
    String id,
    String message, {
    String orderType = 'order',
    String? chatChannel,
  }) async {
    if (_token == null) {
      throw AuthException.invalidCredentials;
    }

    try {
      final data = <String, dynamic>{'message': message};
      if (chatChannel != null && chatChannel.isNotEmpty) {
        data['channel'] = chatChannel;
      }
      final response = await _dio.post(
        '/orders/$orderType/$id/chat',
        data: data,
      );
      final responseData = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};

      if (response.statusCode != 201 || responseData['data'] == null) {
        throw AuthException.networkError;
      }

      return responseData['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      final statusData = e.response?.data;
      String errorMessage;
      if (statusData is String) {
        errorMessage = statusData;
      } else if (statusData is Map<String, dynamic>) {
        errorMessage = statusData['message']?.toString() ?? 'Gagal mengirim pesan chat.';
      } else {
        errorMessage = 'Gagal mengirim pesan chat.';
      }

      throw Exception(errorMessage);
    }
  }

  Future<Map<String, dynamic>> rateOrder(String id, int rating) async {
    if (_token == null) {
      throw AuthException.invalidCredentials;
    }

    try {
      final response = await _dio.post(
        '/warga/orders/$id/rating',
        data: {'rating': rating},
      );
      final responseData = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};

      if (response.statusCode != 200 || responseData['data'] == null) {
        throw AuthException.networkError;
      }

      return responseData['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      final statusData = e.response?.data;
      String message;
      if (statusData is String) {
        message = statusData;
      } else if (statusData is Map<String, dynamic>) {
        final base = statusData['message']?.toString() ?? 'Gagal mengirim rating.';
        final detail = statusData['error']?.toString();
        message = detail != null && detail.isNotEmpty ? '$base: $detail' : base;
      } else {
        message = 'Gagal mengirim rating.';
      }

      throw Exception(message);
    }
  }

  Future<List<Map<String, dynamic>>> getWargaWastePickups() async {
    if (_token == null) {
      throw AuthException.invalidCredentials;
    }

    try {
      final response = await _dio.get('/warga/waste');
      final responseData = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};

      if (response.statusCode != 200) {
        throw AuthException.networkError;
      }

      final data = responseData['data'];
      if (data is List) {
        return data.whereType<Map<String, dynamic>>().toList();
      }

      return const <Map<String, dynamic>>[];
    } on DioException catch (e) {
      final message = e.response?.data is String
          ? e.response!.data as String
          : (e.response?.data is Map<String, dynamic>
              ? (e.response!.data as Map<String, dynamic>)['message']?.toString() ?? 'Gagal mengambil limbah.'
              : 'Gagal mengambil limbah.');
      throw Exception(message);
    }
  }

  Future<Map<String, dynamic>> createWargaWastePickup(Map<String, dynamic> data) async {
    if (_token == null) {
      throw AuthException.invalidCredentials;
    }

    try {
      final response = await _dio.post('/warga/waste', data: data);
      final responseData = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};

      if (response.statusCode != 201 || responseData['data'] == null) {
        throw AuthException.networkError;
      }

      return responseData['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      final message = e.response?.data is String
          ? e.response!.data as String
          : (e.response?.data is Map<String, dynamic>
              ? (e.response!.data as Map<String, dynamic>)['message']?.toString() ?? 'Gagal menambah penjualan limbah.'
              : 'Gagal menambah penjualan limbah.');
      throw Exception(message);
    }
  }

  Future<Map<String, dynamic>> updateWargaWastePickup(String id, Map<String, dynamic> data) async {
    if (_token == null) {
      throw AuthException.invalidCredentials;
    }

    try {
      final response = await _dio.put('/warga/waste/$id', data: data);
      final responseData = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};

      if (response.statusCode != 200 || responseData['data'] == null) {
        throw AuthException.networkError;
      }

      return responseData['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      final message = e.response?.data is String
          ? e.response!.data as String
          : (e.response?.data is Map<String, dynamic>
              ? (e.response!.data as Map<String, dynamic>)['message']?.toString() ?? 'Gagal memperbarui penjualan limbah.'
              : 'Gagal memperbarui penjualan limbah.');
      throw Exception(message);
    }
  }

  Future<Map<String, dynamic>> getWargaWastePickup(String id) async {
    if (_token == null) {
      throw AuthException.invalidCredentials;
    }

    try {
      final response = await _dio.get('/warga/waste/$id');
      final responseData = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};

      if (response.statusCode != 200 || responseData['data'] == null) {
        throw AuthException.networkError;
      }

      return responseData['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      final message = e.response?.data is String
          ? e.response!.data as String
          : (e.response?.data is Map<String, dynamic>
              ? (e.response!.data as Map<String, dynamic>)['message']?.toString() ?? 'Gagal mengambil detail limbah.'
              : 'Gagal mengambil detail limbah.');
      throw Exception(message);
    }
  }

  Future<List<Map<String, dynamic>>> getFarmerWastePickups() async {
    if (_token == null) {
      throw AuthException.invalidCredentials;
    }

    try {
      final response = await _dio.get('/farmer/waste');
      final responseData = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};

      if (response.statusCode != 200) {
        throw AuthException.networkError;
      }

      final data = responseData['data'];
      if (data is List) {
        return data.whereType<Map<String, dynamic>>().toList();
      }

      return const <Map<String, dynamic>>[];
    } on DioException catch (e) {
      final message = e.response?.data is String
          ? e.response!.data as String
          : (e.response?.data is Map<String, dynamic>
              ? (e.response!.data as Map<String, dynamic>)['message']?.toString() ?? 'Gagal mengambil limbah petani.'
              : 'Gagal mengambil limbah petani.');
      throw Exception(message);
    }
  }

  Future<Map<String, dynamic>> claimFarmerWastePickup(String id) async {
    if (_token == null) {
      throw AuthException.invalidCredentials;
    }

    try {
      final response = await _dio.post('/farmer/waste/$id/claim');
      final responseData = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};

      if (response.statusCode != 200 || responseData['data'] == null) {
        throw AuthException.networkError;
      }

      return responseData['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      final message = e.response?.data is String
          ? e.response!.data as String
          : (e.response?.data is Map<String, dynamic>
              ? (e.response!.data as Map<String, dynamic>)['message']?.toString() ?? 'Gagal mengklaim limbah.'
              : 'Gagal mengklaim limbah.');
      throw Exception(message);
    }
  }

  // Delivery-person endpoints
  Future<List<Map<String, dynamic>>> getDeliveryTasks() async {
    if (_token == null) {
      throw AuthException.invalidCredentials;
    }

    try {
      final response = await _dio.get('/delivery-person/tasks');
      final responseData = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};

      if (response.statusCode != 200) {
        throw AuthException.networkError;
      }

      final data = responseData['data'];
      if (data is List) {
        return data.whereType<Map<String, dynamic>>().where((task) {
          final type = task['type']?.toString().toLowerCase() ?? '';
          return type != 'waste_delivery' && type != 'waste_pickup';
        }).toList();
      }

      return const <Map<String, dynamic>>[];
    } on DioException catch (e) {
      final message = e.response?.data is String
          ? e.response!.data as String
          : (e.response?.data is Map<String, dynamic>
              ? (e.response!.data as Map<String, dynamic>)['message']?.toString() ?? 'Gagal mengambil tasks.'
              : 'Gagal mengambil tasks.');
      throw Exception(message);
    }
  }

  Future<Map<String, dynamic>> getDeliveryTaskDetail(String id) async {
    if (_token == null) {
      throw AuthException.invalidCredentials;
    }

    try {
      final response = await _dio.get('/delivery-person/tasks/$id');
      final responseData = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};

      if (response.statusCode != 200 || responseData['data'] == null) {
        throw AuthException.networkError;
      }

      return responseData['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      final message = e.response?.data is String
          ? e.response!.data as String
          : (e.response?.data is Map<String, dynamic>
              ? (e.response!.data as Map<String, dynamic>)['message']?.toString() ?? 'Gagal mengambil detail task.'
              : 'Gagal mengambil detail task.');
      throw Exception(message);
    }
  }

  Future<Map<String, dynamic>> acceptDeliveryTask(String id) async {
    if (_token == null) {
      throw AuthException.invalidCredentials;
    }

    try {
      final response = await _dio.post('/delivery-person/tasks/$id/accept');
      final responseData = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};

      if (response.statusCode != 200 || responseData['data'] == null) {
        throw AuthException.networkError;
      }

      return responseData['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      final message = e.response?.data is String
          ? e.response!.data as String
          : (e.response?.data is Map<String, dynamic>
              ? (e.response!.data as Map<String, dynamic>)['message']?.toString() ?? 'Gagal menerima task.'
              : 'Gagal menerima task.');
      throw Exception(message);
    }
  }

  Future<Map<String, dynamic>> pickupDeliveryTask(String id) async {
    if (_token == null) {
      throw AuthException.invalidCredentials;
    }

    try {
      final response = await _dio.post('/delivery-person/tasks/$id/pickup');
      final responseData = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};

      if (response.statusCode != 200 || responseData['data'] == null) {
        throw AuthException.networkError;
      }

      return responseData['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      final message = e.response?.data is String
          ? e.response!.data as String
          : (e.response?.data is Map<String, dynamic>
              ? (e.response!.data as Map<String, dynamic>)['message']?.toString() ?? 'Gagal konfirmasi pickup.'
              : 'Gagal konfirmasi pickup.');
      throw Exception(message);
    }
  }

  Future<Map<String, dynamic>> completeDeliveryTask(String id) async {
    if (_token == null) {
      throw AuthException.invalidCredentials;
    }

    try {
      final response = await _dio.post('/delivery-person/tasks/$id/complete');
      final responseData = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};

      if (response.statusCode != 200 || responseData['data'] == null) {
        throw AuthException.networkError;
      }

      return responseData['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      final message = e.response?.data is String
          ? e.response!.data as String
          : (e.response?.data is Map<String, dynamic>
              ? (e.response!.data as Map<String, dynamic>)['message']?.toString() ?? 'Gagal menyelesaikan task.'
              : 'Gagal menyelesaikan task.');
      throw Exception(message);
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_token == null) {
      throw AuthException.invalidCredentials;
    }

    try {
      final response = await _dio.post(
        '/me/password',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
          'new_password_confirmation': newPassword,
        },
      );

      final responseData = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw AuthException.networkError;
      }

      if (responseData['message'] == null) {
        return;
      }
    } on DioException catch (e) {
      final message = e.response?.data is String
          ? e.response!.data as String
          : (e.response?.data is Map<String, dynamic>
              ? (e.response!.data as Map<String, dynamic>)['message']?.toString() ?? 'Gagal mengubah password.'
              : 'Gagal mengubah password.');
      throw Exception(message);
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    if (_token == null) {
      throw AuthException.invalidCredentials;
    }

    try {
      final response = await _dio.put('/me', data: data);

      final responseData = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw AuthException.networkError;
      }

      final userData = responseData['data'] as Map<String, dynamic>? ?? responseData;
      if (userData.isEmpty) {
        throw AuthException.networkError;
      }

      final backendRoleName = userData['role'] as String?;
      final currentUser = _ref.read(authStorageProvider).value;
      final resolvedRole = backendRoleName != null
          ? UserRole.values.firstWhere(
              (candidate) => candidate.name == backendRoleName,
              orElse: () => currentUser?.role ?? UserRole.warga,
            )
          : currentUser?.role ?? UserRole.warga;

      final user = AuthUser(
        id: userData['id'].toString(),
        email: userData['email'] as String? ?? currentUser?.email ?? '',
        name: userData['name'] as String? ?? currentUser?.name ?? '',
        role: resolvedRole,
        phone: (userData['phone'] ?? userData['no_hp'] ?? currentUser?.phone ?? '').toString(),
        address: (userData['address'] ?? userData['alamat'] ?? currentUser?.address ?? '').toString(),
        detailHouse: (userData['detail_house'] ?? currentUser?.detailHouse ?? '').toString(),
        latitude: (userData['latitude'] != null)
            ? double.tryParse(userData['latitude'].toString())
            : (userData['lat'] != null ? double.tryParse(userData['lat'].toString()) : currentUser?.latitude),
        longitude: (userData['longitude'] != null)
            ? double.tryParse(userData['longitude'].toString())
            : (userData['lon'] != null ? double.tryParse(userData['lon'].toString()) : currentUser?.longitude),
        profile: (userData['profile'] ?? userData['avatar'] ?? currentUser?.profile ?? '').toString().trim().isNotEmpty
            ? (userData['profile'] ?? userData['avatar'] ?? currentUser?.profile ?? '').toString()
            : null,
      );

      await _ref.read(authStorageProvider.notifier).save(user);
    } on DioException catch (e) {
      final message = e.response?.data is String
          ? e.response!.data as String
          : (e.response?.data is Map<String, dynamic>
              ? (e.response!.data as Map<String, dynamic>)['message']?.toString() ?? 'Gagal memperbarui profil.'
              : 'Gagal memperbarui profil.');
      throw Exception(message);
    }
  }
}

final laravelAuthServiceProvider = Provider<LaravelAuthService>((ref) {
  return LaravelAuthService(ref);
});
