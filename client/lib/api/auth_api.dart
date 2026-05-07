import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config.dart';
import '../models/user_info.dart';
import 'dio_client.dart';

final authApiProvider = Provider<AuthApi>((ref) => AuthApi(ref.watch(dioProvider)));

class AuthApi {
  AuthApi(this._dio);
  final Dio _dio;

  /// POST /api/auth/exchange
  Future<String> exchange(String code) async {
    final res = await _dio.post('/auth/exchange', data: {'code': code});
    final body = res.data as Map<String, dynamic>;
    if (body['code'] != 0) {
      throw Exception(body['message'] ?? '兑换失败');
    }
    final data = body['data'] as Map<String, dynamic>;
    return data['sessionToken'] as String;
  }

  /// POST /api/auth/refresh — 使用独立 Dio 实例，避免 interceptor 循环依赖
  Future<String> refresh(String token) async {
    final plain = Dio(BaseOptions(
      baseUrl: AppConfig.kBrainThinkBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
    ));
    final res = await plain.post('/auth/refresh',
      options: Options(headers: {'Authorization': 'Bearer $token'}));
    final body = res.data as Map<String, dynamic>;
    if (body['code'] != 0) {
      throw Exception(body['message'] ?? '刷新失败');
    }
    final data = body['data'] as Map<String, dynamic>;
    return data['sessionToken'] as String;
  }

  /// GET /api/auth/me
  Future<UserInfo?> me() async {
    try {
      final res = await _dio.get('/auth/me');
      final body = res.data as Map<String, dynamic>;
      if (body['code'] != 0) return null;
      final data = body['data'];
      if (data is! Map<String, dynamic>) return null;
      return UserInfo.fromJson(data);
    } on DioException {
      return null;
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (_) {/* ignore */}
  }
}
