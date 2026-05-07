import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config.dart';
import '../providers/auth_provider.dart';
import '../providers/secure_storage.dart';

bool _isRefreshing = false;
final List<Function> _pendingQueue = [];

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: AppConfig.kBrainThinkBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 60),
    headers: {'Content-Type': 'application/json'},
  ));

  dio.interceptors.add(QueuedInterceptorsWrapper(
    onRequest: (options, handler) async {
      // 优先内存态 token（测试环境 Keychain 可能不可用），否则回落 secure storage
      String? token = ref.read(authProvider).token;
      if (token == null || token.isEmpty) {
        try {
          token = await ref.read(secureStorageProvider).readToken();
        } catch (e) {
          debugPrint('[BT-DIO] readToken 失败（忽略）：$e');
        }
      }
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    },
    onError: (error, handler) async {
      if (error.response?.statusCode == 401 &&
          error.requestOptions.path != '/auth/refresh') {
        if (_isRefreshing) {
          _pendingQueue.add(() async {
            final opts = error.requestOptions;
            opts.headers['Authorization'] =
                'Bearer ${ref.read(authProvider).token}';
            handler.resolve(await dio.fetch(opts));
          });
          return;
        }
        _isRefreshing = true;
        try {
          final newToken = await ref.read(authProvider.notifier).refreshToken();
          error.requestOptions.headers['Authorization'] = 'Bearer $newToken';
          final response = await dio.fetch(error.requestOptions);
          handler.resolve(response);
        } catch (e) {
          ref.read(authProvider.notifier).logout();
          handler.reject(error);
        } finally {
          _isRefreshing = false;
          for (final cb in _pendingQueue) {
            try {
              await cb();
            } catch (_) {}
          }
          _pendingQueue.clear();
        }
      } else {
        handler.next(error);
      }
    },
  ));

  return dio;
});
