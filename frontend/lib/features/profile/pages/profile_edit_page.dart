import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../theme/theme.dart';
import '../../../utils/app_navigation.dart';
import '../../../utils/responsive.dart';
import '../../auth/models/user_role.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileEditPage extends ConsumerStatefulWidget {
  const ProfileEditPage({
    super.key,
    required this.fieldName,
    required this.initialValue,
  });

  final String fieldName;
  final String initialValue;

  @override
  ConsumerState<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends ConsumerState<ProfileEditPage> {
  static const LatLng _fallbackCenter = LatLng(-6.200000, 106.816666);

  late final TextEditingController _editingController;
  late String _originalValue;
  late final Dio _dio;
  final MapController _mapController = MapController();
  late final TextEditingController _detailController;
  LatLng? _selectedLocation;
  LatLng _mapCenter = _fallbackCenter;
  bool _isSaving = false;
  bool _isLocating = false;
  String? _locationStatus;

  bool get _isAddressField => widget.fieldName == 'Alamat Pengiriman';

  @override
  void initState() {
    super.initState();
    _originalValue = widget.initialValue == 'Belum diatur' ? '' : widget.initialValue;
    _editingController = TextEditingController(text: _originalValue);
    _detailController = TextEditingController();
    _editingController.addListener(() => setState(() {}));
    _detailController.addListener(() => setState(() {}));
    _dio = Dio(BaseOptions(headers: {
      'User-Agent': 'SinteraApp/1.0 (contact: dev@local)'
    }));
    if (_isAddressField) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _maybeInitAddressData();
      });
    }
  }

  Future<void> _maybeInitAddressData() async {
    try {
      await ref.read(laravelAuthServiceProvider).fetchProfile();
    } catch (_) {}

    final currentUser = ref.read(authStorageProvider).value;
    if (currentUser != null) {
      if (mounted) {
        _detailController.text = currentUser.detailHouse;
      }
    }

    if (currentUser != null && currentUser.latitude != null && currentUser.longitude != null) {
      if (!mounted) return;
      setState(() {
        _selectedLocation = LatLng(currentUser.latitude!, currentUser.longitude!);
        _mapCenter = _selectedLocation!;
      });
      Future.delayed(const Duration(milliseconds: 120), () {
        try {
          final currentZoom = _mapController.camera.zoom;
          _mapController.move(_selectedLocation!, currentZoom);
        } catch (_) {
          try {
            _mapController.move(_selectedLocation!, 15);
          } catch (_) {}
        }
      });

      if (_editingController.text.trim().isEmpty) {
        await _reverseGeocodeAndFill(_selectedLocation!);
      }
    } else {
      await _initLocation();
    }
  }

  @override
  void dispose() {
    _editingController.dispose();
    _detailController.dispose();
    super.dispose();
  }

  bool get _hasChanges {
    if (widget.fieldName != 'Alamat Pengiriman') {
      return _editingController.text.trim() != _originalValue;
    }

    final currentUser = ref.read(authStorageProvider).value;
    final addressChanged = _editingController.text.trim() != (currentUser?.address ?? '').trim();
    final detailChanged = _detailController.text.trim() != (currentUser?.detailHouse ?? '').trim();
    final locationChanged = _selectedLocation != null &&
        currentUser != null &&
        currentUser.latitude != null &&
        currentUser.longitude != null &&
        (_selectedLocation!.latitude != currentUser.latitude! || _selectedLocation!.longitude != currentUser.longitude!);

    return addressChanged || detailChanged || locationChanged;
  }

  IconData get _fieldIcon {
    return switch (widget.fieldName) {
      'Nama Lengkap' => Icons.badge_outlined,
      'Alamat Email' => Icons.email_outlined,
      'Nomor Telepon' => Icons.phone_android_outlined,
      'Alamat Pengiriman' => Icons.location_on_outlined,
      _ => Icons.edit_outlined,
    };
  }

  TextInputType get _keyboardType {
    return switch (widget.fieldName) {
      'Alamat Email' => TextInputType.emailAddress,
      'Nomor Telepon' => TextInputType.phone,
      _ => TextInputType.text,
    };
  }

  Future<void> _saveEditing() async {
    final newValue = _editingController.text.trim();
    if (newValue == _originalValue && !_hasChanges) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      return;
    }

    setState(() => _isSaving = true);

    try {
      final currentUser = ref.read(authStorageProvider).value;
      if (currentUser == null) {
        if (context.canPop()) {
          context.pop();
        }
        return;
      }

      final backendField = switch (widget.fieldName) {
        'Nama Lengkap' => 'name',
        'Alamat Email' => 'email',
        'Nomor Telepon' => 'phone',
        'Alamat Pengiriman' => 'address',
        _ => 'name',
      };

      final payload = <String, dynamic>{};
      if (backendField == 'address') {
        payload[backendField] = newValue;
        payload['detail_house'] = _detailController.text.trim();
        if (_selectedLocation != null) {
          payload['latitude'] = _selectedLocation!.latitude;
          payload['longitude'] = _selectedLocation!.longitude;
        }
      } else {
        payload[backendField] = newValue;
      }

      await ref.read(laravelAuthServiceProvider).updateProfile(payload);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perubahan berhasil disimpan.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        if (context.canPop()) {
          context.pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        final message = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _initLocation() async {
    final permission = await _checkLocationPermission();
    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      setState(() {
        _locationStatus = 'Akses lokasi ditolak permanen.';
      });
      return;
    }

    final position = await _getCurrentPosition();
    if (position != null) {
      if (!mounted) return;
      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
        _mapCenter = _selectedLocation!;
        _locationStatus = 'Lokasi saat ini berhasil ditentukan.';
      });
      try {
        _mapController.move(_selectedLocation!, 15);
      } catch (_) {}
      await _reverseGeocodeAndFill(_selectedLocation!);
    }
  }

  Future<LocationPermission> _checkLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      if (!mounted) return LocationPermission.denied;
      setState(() {
        _locationStatus = 'Layanan lokasi nonaktif.';
      });
      return LocationPermission.denied;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission;
  }

  Future<Position?> _getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      if (!mounted) return null;
      setState(() {
        _locationStatus = 'Gagal mengambil lokasi: ${e.toString()}';
      });
      return null;
    }
  }

  Future<void> _captureCurrentLocation() async {
    if (!mounted) return;
    setState(() {
      _isLocating = true;
      _locationStatus = 'Mengambil lokasi saat ini...';
    });

    final permission = await _checkLocationPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      setState(() => _isLocating = false);
      return;
    }

    final position = await _getCurrentPosition();
    if (position != null) {
      if (!mounted) return;
      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
        _mapCenter = _selectedLocation!;
        _locationStatus = 'Lokasi saat ini dipilih.';
      });
      try {
        final currentZoom = _mapController.camera.zoom;
        _mapController.move(_selectedLocation!, currentZoom);
      } catch (_) {}
      await _reverseGeocodeAndFill(_selectedLocation!);
    }

    if (!mounted) return;
    setState(() => _isLocating = false);
  }

  Future<void> _onMapTap(LatLng point) async {
    if (!mounted) return;
    setState(() {
      _selectedLocation = point;
      _locationStatus = 'Titik dipilih pada peta.';
    });
    try {
      final currentZoom = _mapController.camera.zoom;
      _mapController.move(point, currentZoom);
    } catch (_) {}
    await _reverseGeocodeAndFill(point);
  }

  Future<void> _reverseGeocodeAndFill(LatLng latlng) async {
    try {
      final url = 'https://nominatim.openstreetmap.org/reverse';
      final resp = await _dio.get(url, queryParameters: {
        'lat': latlng.latitude,
        'lon': latlng.longitude,
        'format': 'jsonv2',
        'accept-language': 'id'
      });
      if (resp.statusCode == 200) {
        final data = resp.data;
        final displayName = (data is Map && data.containsKey('display_name')) ? (data['display_name'] as String) : '';
        if (!mounted) return;
        setState(() {
          _editingController.text = displayName;
          _locationStatus = 'Alamat diperbarui dari peta.';
        });
      } else {
        if (!mounted) return;
        setState(() => _locationStatus = 'Gagal mengambil alamat.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _locationStatus = 'Gagal reverse geocode.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final role = ref.watch(authStorageProvider).value?.role;
    
    // Warna tema dinamis: Pengantar = Merah, Petani = Biru, Warga = Hijau
    final Color themeColor = role == UserRole.pengantar
        ? const Color(0xFFB22222)
        : role == UserRole.petani
            ? const Color(0xFF1B3B6F)
            : AppColors.primary;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Edit ${widget.fieldName}',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 18),
          onPressed: () => safePopOrGoHome(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Colors.black.withValues(alpha: 0.05),
            height: 1.0,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: Responsive.contentMaxWidth(context)),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
              children: [
                Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isAddressField) ...[
                        SizedBox(
                          height: 260,
                          width: double.infinity,
                          child: Stack(
                            children: [
                              FlutterMap(
                                mapController: _mapController,
                                options: MapOptions(
                                  initialCenter: _selectedLocation ?? _mapCenter,
                                  initialZoom: 15,
                                  interactionOptions: const InteractionOptions(
                                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                                  ),
                                  onTap: (tapPosition, point) async {
                                    await _onMapTap(point);
                                  },
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                                    subdomains: const ['a', 'b', 'c'],
                                    userAgentPackageName: 'com.sintera.frontend',
                                  ),
                                  if (_selectedLocation != null)
                                    MarkerLayer(
                                      markers: [
                                        Marker(
                                          point: _selectedLocation!,
                                          width: 40,
                                          height: 40,
                                          rotate: false,
                                          child: Icon(
                                            Icons.location_on,
                                            color: themeColor,
                                            size: 38,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                              // Tombol Ambil Lokasi (Kotak dengan sudut agak membulat)
                              Positioned(
                                bottom: 12,
                                right: 12,
                                child: Material(
                                  color: Colors.white,
                                  elevation: 3,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(8),
                                    onTap: _isLocating ? null : _captureCurrentLocation,
                                    child: Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: _isLocating
                                          ? SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: themeColor,
                                              ),
                                            )
                                          : Icon(
                                              Icons.my_location_rounded,
                                              color: themeColor,
                                              size: 20,
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.location_on_outlined, size: 14, color: themeColor),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'Alamat Terpilih dari Peta',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textTertiary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _editingController.text.trim().isEmpty
                                    ? 'Ketuk pada peta untuk menentukan lokasi alamat'
                                    : _editingController.text.trim(),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w500,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.lg),

                              // Textbox Detail Rumah (Background putih, hanya garis tepi)
                              TextField(
                                controller: _detailController,
                                keyboardType: TextInputType.text,
                                maxLines: 1,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Detail Rumah (Blok/Nomor/Patokan)',
                                  labelStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
                                  filled: true,
                                  fillColor: Colors.white, // Background putih
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.15)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.15)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: themeColor, width: 1.5),
                                  ),
                                ),
                              ),

                              if (_locationStatus != null) ...[
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  _locationStatus!,
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                              ],
                              const SizedBox(height: AppSpacing.lg),

                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: (_hasChanges && !_isSaving) ? _saveEditing : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: themeColor,
                                    disabledBackgroundColor: themeColor.withValues(alpha: 0.2),
                                    foregroundColor: Colors.white,
                                    disabledForegroundColor: Colors.white70,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    elevation: 0,
                                  ),
                                  child: _isSaving
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                        )
                                      : const Text(
                                          'Simpan Perubahan',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ... [
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      color: themeColor.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Icon(_fieldIcon, color: themeColor, size: 18),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.fieldName,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textTertiary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Perbarui ${widget.fieldName.toLowerCase()} Anda',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.textPrimary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              TextField(
                                controller: _editingController,
                                autofocus: true,
                                keyboardType: _keyboardType,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: InputDecoration(
                                  labelText: widget.fieldName,
                                  labelStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.15)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.15)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: themeColor, width: 1.5),
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: (_hasChanges && !_isSaving) ? _saveEditing : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: themeColor,
                                    disabledBackgroundColor: themeColor.withValues(alpha: 0.2),
                                    foregroundColor: Colors.white,
                                    disabledForegroundColor: Colors.white70,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    elevation: 0,
                                  ),
                                  child: _isSaving
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                        )
                                      : const Text(
                                          'Simpan Perubahan',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}