import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/auth_api.dart';
import '../models/user_info.dart';
import 'secure_storage.dart';

class AuthState {
  const AuthState({
    this.token,
    this.user,
    this.bootstrapping = true,
    this.error,
  });

  final String? token;
  final UserInfo? user;
  final bool bootstrapping;
  final String? error;

  bool get loggedIn => token != null && token!.isNotEmpty;

  AuthState copyWith({
    String? token,
    UserInfo? user,
    bool? bootstrapping,
    String? error,
    bool clearError = false,
    bool clearUser = false,
  }) =>
      AuthState(
        token: token ?? this.token,
        user: clearUser ? null : (user ?? this.user),
        bootstrapping: bootstrapping ?? this.bootstrapping,
        error: clearError ? null : (error ?? this.error),
      );
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._ref) : super(const AuthState()) {
    _bootstrap();
  }

  final Ref _ref;

  Future<void> _bootstrap() async {
    String? stored;
    try {
      stored = await _ref.read(secureStorageProvider).readToken();
    } catch (e) {
      debugPrint('[BT-AUTH] bootstrap readToken 失败（忽略）：$e');
    }
    state = state.copyWith(token: stored, bootstrapping: false);
    if (stored != null && stored.isNotEmpty) {
      _refreshUser();
    }
  }

  /// WebView 拦截到 brainthink://callback?code=… 后调用
  Future<void> exchange(String code) async {
    state = state.copyWith(error: null, clearError: true);
    try {
      final api = _ref.read(authApiProvider);
      final token = await api.exchange(code);
      // 先把内存态点亮（路由会立即跳到 /chat），
      // 再尽力把 token 落 Keychain；落库失败不影响登录。
      state = state.copyWith(token: token);
      try {
        await _ref.read(secureStorageProvider).writeToken(token);
      } catch (e) {
        debugPrint('[BT-AUTH] writeToken 失败（忽略，仅影响重启后持久化）：$e');
      }
      _refreshUser();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> _refreshUser() async {
    try {
      final u = await _ref.read(authApiProvider).me();
      if (u != null) state = state.copyWith(user: u);
    } catch (e) {
      debugPrint('[BT-AUTH] /me 失败（忽略）：$e');
    }
  }

  /// 由 Dio interceptor 在 401 时调用，使用独立 Dio 调 /auth/refresh
  Future<String> refreshToken() async {
    final current = state.token;
    if (current == null || current.isEmpty) throw Exception('无 token');
    try {
      final api = _ref.read(authApiProvider);
      final newToken = await api.refresh(current);
      state = state.copyWith(token: newToken, clearError: true);
      try {
        await _ref.read(secureStorageProvider).writeToken(newToken);
      } catch (e) {
        debugPrint('[BT-AUTH] writeToken 失败（忽略）：$e');
      }
      return newToken;
    } catch (e) {
      debugPrint('[BT-AUTH] refresh 失败：$e');
      rethrow;
    }
  }

  Future<void> logout() async {
    final api = _ref.read(authApiProvider);
    try {
      await api.logout();
    } catch (_) {}
    try {
      await _ref.read(secureStorageProvider).clear();
    } catch (_) {}
    state = const AuthState(bootstrapping: false);
  }
}

final authProvider = StateNotifierProvider<AuthController, AuthState>(
    (ref) => AuthController(ref));

/// GoRouter 通过 Listenable 触发刷新
final authListenableProvider = Provider<Listenable>((ref) {
  final n = _AuthListenable();
  ref.listen(authProvider, (_, __) => n.notify());
  ref.onDispose(n.dispose);
  return n;
});

class _AuthListenable extends ChangeNotifier {
  void notify() => notifyListeners();
}
