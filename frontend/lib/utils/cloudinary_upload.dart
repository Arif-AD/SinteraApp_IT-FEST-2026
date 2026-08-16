import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:image_picker/image_picker.dart';

import '../constants/cloudinary_constants.dart';

class CloudinaryUpload {
  CloudinaryUpload._();

  static Future<String> uploadImage(XFile imageFile) async {
    if (CloudinaryConstants.cloudName == 'your_cloud_name' || CloudinaryConstants.uploadPreset == 'your_unsigned_preset') {
      throw Exception('Konfigurasi Cloudinary belum diatur. Set CLOUDINARY_CLOUD_NAME dan CLOUDINARY_UPLOAD_PRESET.');
    }

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        imageFile.path,
        filename: imageFile.name,
      ),
      'upload_preset': CloudinaryConstants.uploadPreset,
    });

    final response = await _postWithCertificateFallback(
      formData: formData,
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Gagal upload gambar ke Cloudinary.');
    }

    final data = response.data;
    if (data is Map && data['secure_url'] != null) {
      return data['secure_url'] as String;
    }

    throw Exception('Cloudinary tidak mengembalikan URL valid.');
  }

  static Future<Response<dynamic>> _postWithCertificateFallback({required FormData formData}) async {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
        headers: {
          'Accept': 'application/json',
        },
      ),
    );

    try {
      return await dio.post(
        CloudinaryConstants.uploadUrl,
        data: formData,
        options: Options(headers: {'Accept': 'application/json'}),
      );
    } on DioException catch (e) {
      if (!_shouldRetryWithInsecureCertificate(e)) {
        throw _formatDioException(e);
      }

      final insecureDio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 60),
          headers: {
            'Accept': 'application/json',
          },
        ),
      );

      insecureDio.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          final client = HttpClient();
          client.badCertificateCallback = (cert, host, port) => true;
          return client;
        },
      );

      try {
        return await insecureDio.post(
          CloudinaryConstants.uploadUrl,
          data: formData,
          options: Options(headers: {'Accept': 'application/json'}),
        );
      } on DioException catch (retryError) {
        throw _formatDioException(retryError);
      }
    }
  }

  static bool _shouldRetryWithInsecureCertificate(DioException error) {
    final errorMessage = error.toString().toLowerCase();
    return error.type == DioExceptionType.badCertificate ||
        error.type == DioExceptionType.connectionError ||
        errorMessage.contains('certificate_verify_failed') ||
        errorMessage.contains('handshake') ||
        errorMessage.contains('tls');
  }

  static Exception _formatDioException(DioException error) {
    if (error.response?.data is Map) {
      final responseData = error.response!.data as Map;
      final message = responseData['message']?.toString() ?? responseData['error']?.toString();
      if (message != null && message.isNotEmpty) {
        return Exception(message);
      }
    }

    if (error.type == DioExceptionType.badCertificate ||
        error.type == DioExceptionType.connectionError) {
      return Exception('Gagal terhubung ke Cloudinary karena masalah sertifikat atau koneksi. Coba lagi sebentar lagi.');
    }

    return Exception('Gagal mengunggah gambar ke Cloudinary. ${error.message ?? 'Periksa koneksi internet Anda.'}');
  }
}
