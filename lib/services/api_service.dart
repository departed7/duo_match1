import 'package:dio/dio.dart';
import '../core/constants.dart';

class ApiService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: const Duration(milliseconds: 5000),
      receiveTimeout: const Duration(milliseconds: 3000),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  Future<Response?> getProfiles() async {
    try {
      final response = await _dio.get('/users/feed');
      return response;
    } on DioException catch (e) {
      return e.response;
    }
  }

  Future<Response?> sendLike(String targetUserId, String type) async {
    try {
      final response = await _dio.post(
        '/matches/like',
        data: {'target_id': targetUserId, 'type': type},
      );
      return response;
    } on DioException catch (e) {
      return e.response;
    }
  }

  Future<Response?> uploadPhoto(String filePath) async {
    try {
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(filePath),
      });
      final response = await _dio.post('/profile/upload', data: formData);
      return response;
    } on DioException catch (e) {
      return e.response;
    }
  }
}