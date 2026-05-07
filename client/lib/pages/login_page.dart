import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config.dart';
import '../providers/auth_provider.dart';

/// 测试钩子（公开类）：integration_test 通过它拿到 InAppWebViewController
/// 来执行 evaluateJavascript 自动填表/点击
class LoginPageTestHooks {
  static InAppWebViewController? webViewController;
  static int pageLoadCount = 0;
  static String? lastUrl;

  /// 由 integration_test 直接调用，模拟"WebView 拦到 brainthink://callback?code=..."
  /// 跳过浏览器同意页点击的死循环（macOS WKWebView 测试态点 React 按钮会触发奇怪的 dispose）
  static Future<void> Function(String code)? onCodeSimulator;

  /// exchange 完成后由 _onCode 写入。null = 没异常；非 null = 失败原因
  static String? lastExchangeError;

  /// exchange 成功后由 _onCode 写入 sessionToken
  static String? lastSessionToken;

  /// _onCode 进入次数（用来排查是否被重入/卡住）
  static int onCodeInvokeCount = 0;
}

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  late final String _state;
  String? _capturedCode;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _state = 'st_${DateTime.now().millisecondsSinceEpoch}';
    LoginPageTestHooks.onCodeSimulator = _onCode;
  }

  @override
  void dispose() {
    if (LoginPageTestHooks.onCodeSimulator == _onCode) {
      LoginPageTestHooks.onCodeSimulator = null;
    }
    super.dispose();
  }

  String get _authorizeUrl {
    final base = AppConfig.kPlatformWebBase;
    final cid = AppConfig.kOAuthClientId;
    final ru = Uri.encodeComponent(AppConfig.kRedirectUri);
    final scope = AppConfig.kScope;
    return '$base/oauth/authorize'
        '?client_id=$cid'
        '&redirect_uri=$ru'
        '&scope=$scope'
        '&state=$_state';
  }

  Future<void> _onCode(String code) async {
    LoginPageTestHooks.onCodeInvokeCount += 1;
    debugPrint('[BT-LP] _onCode 进入 #${LoginPageTestHooks.onCodeInvokeCount} code=${code.substring(0, 8)}... busy=$_busy captured=$_capturedCode');
    if (_busy || _capturedCode == code) {
      debugPrint('[BT-LP] _onCode 被忽略（busy 或 重复 code）');
      return;
    }
    setState(() {
      _busy = true;
      _capturedCode = code;
    });
    try {
      await ref.read(authProvider.notifier).exchange(code);
      final st = ref.read(authProvider);
      LoginPageTestHooks.lastExchangeError = st.error;
      LoginPageTestHooks.lastSessionToken = st.token;
      debugPrint('[BT-LP] exchange 完成 token=${st.token == null ? "null" : "${st.token!.substring(0, 12)}..."} error=${st.error}');
    } catch (e, s) {
      LoginPageTestHooks.lastExchangeError = e.toString();
      debugPrint('[BT-LP] exchange 抛异常: $e\n$s');
    }
    if (!mounted) return;
    setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    if (auth.token != null && !_busy) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.pop();
      });
    }
    return Scaffold(
      appBar: AppBar(title: const Text('登录到 头脑风暴')),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(_authorizeUrl)),
            initialSettings: InAppWebViewSettings(
              useShouldOverrideUrlLoading: true,
              javaScriptEnabled: true,
              isInspectable: kDebugMode,
            ),
            onWebViewCreated: (controller) {
              LoginPageTestHooks.webViewController = controller;
            },
            onLoadStop: (controller, url) {
              LoginPageTestHooks.pageLoadCount += 1;
              LoginPageTestHooks.lastUrl = url?.toString();
            },
            shouldOverrideUrlLoading: (controller, action) async {
              final url = action.request.url;
              if (url == null) return NavigationActionPolicy.ALLOW;
              if (url.scheme == 'brainthink' && url.host == 'callback') {
                final code = url.queryParameters['code'];
                final err = url.queryParameters['error'];
                if (code != null && code.isNotEmpty) {
                  await _onCode(code);
                } else if (err != null) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('授权失败：$err')),
                    );
                  }
                }
                return NavigationActionPolicy.CANCEL;
              }
              return NavigationActionPolicy.ALLOW;
            },
          ),
          if (_busy || auth.error != null)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                alignment: Alignment.center,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_busy) const CircularProgressIndicator(),
                        if (_busy) const SizedBox(height: 12),
                        Text(_busy ? '正在登录…' : '错误：${auth.error}'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
