import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:brain_think/main.dart' as app;
import 'package:brain_think/config.dart';
import 'package:brain_think/pages/login_page.dart';
import 'package:brain_think/widgets/chat_input.dart';

const String kTestEmail = 'demo@bt.com';
const String kTestPassword = 'demo1234';
// 用一个独特词当回执，避免它出现在 prompt 自身导致 findContaining 误命中用户气泡
const String kAiEcho = 'BT-ITEST-OK-7421';
const String kTestPrompt = '请只回复 $kAiEcho 这一串字符（不要带引号、不要任何其他文字、不要解释）';

class _T {
  static void log(String msg) {
    final ts = DateTime.now().toIso8601String().substring(11, 23);
    // ignore: avoid_print
    print('[BT-IT $ts] $msg');
  }
}

class _TimeoutEx implements Exception {
  final String message;
  _TimeoutEx(this.message);
  @override
  String toString() => 'Timeout: $message';
}

Future<void> _waitFor(
  WidgetTester tester,
  Future<bool> Function() check, {
  Duration timeout = const Duration(seconds: 30),
  Duration step = const Duration(milliseconds: 250),
  String? hint,
}) async {
  final deadline = DateTime.now().add(timeout);
  while (true) {
    bool ok = false;
    try {
      ok = await check();
    } catch (e) {
      _T.log('check 抛异常忽略：$e');
    }
    if (ok) return;
    if (DateTime.now().isAfter(deadline)) {
      throw _TimeoutEx('${hint ?? ''}（${timeout.inSeconds}s）');
    }
    await tester.pump(step);
  }
}

/// 直接打 app_plat HTTP，拿一个真实可用的 OAuth code
Future<String> _fetchOAuthCode() async {
  final client = HttpClient();
  try {
    // 1. user 登录拿 user JWT
    final loginReq = await client.postUrl(Uri.parse('https://api.local.caixy.xin/api/v1/user/auth/login'));
    loginReq.headers.contentType = ContentType.json;
    loginReq.add(utf8.encode(jsonEncode({'email': kTestEmail, 'password': kTestPassword})));
    final loginResp = await loginReq.close();
    final loginBody = await loginResp.transform(utf8.decoder).join();
    final loginJson = jsonDecode(loginBody) as Map<String, dynamic>;
    if (loginJson['code'] != 0) {
      throw StateError('登录失败: $loginBody');
    }
    final userJwt = (loginJson['data'] as Map)['accessToken'] as String;
    _T.log('user 登录成功，JWT 前 20 字符: ${userJwt.substring(0, 20)}...');

    // 2. authorize 拿 code
    final authUri = Uri.parse(
      'https://api.local.caixy.xin/api/v1/oauth/authorize'
      '?client_id=${AppConfig.kOAuthClientId}'
      '&redirect_uri=${Uri.encodeComponent(AppConfig.kRedirectUri)}'
      '&scope=${AppConfig.kScope}'
      '&state=integration-test',
    );
    final authReq = await client.getUrl(authUri);
    authReq.headers.add('Authorization', 'Bearer $userJwt');
    final authResp = await authReq.close();
    final authBody = await authResp.transform(utf8.decoder).join();
    final authJson = jsonDecode(authBody) as Map<String, dynamic>;
    if (authJson['code'] != 0) {
      throw StateError('authorize 失败: $authBody');
    }
    final code = (authJson['data'] as Map)['code'] as String;
    _T.log('拿到 OAuth code: ${code.substring(0, 8)}...');
    return code;
  } finally {
    client.close(force: true);
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('OAuth 全自动登录 + 聊天端到端', (WidgetTester tester) async {
    _T.log('--- 测试开始 ---');

    // 1. 启动 app（现在默认进 ChatPage）
    app.main();
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    // 1.5 未登录态会显示「去登录」按钮，点击后进入 LoginPage
    final loginBtn = find.byKey(const Key('chatLoginButton'));
    if (loginBtn.evaluate().isNotEmpty) {
      _T.log('检测到未登录态，点击去登录按钮');
      await tester.tap(loginBtn);
      await tester.pumpAndSettle(const Duration(seconds: 2));
    }

    // 2. 等 LoginPage 的测试钩子 ready
    await _waitFor(
      tester,
      () async => LoginPageTestHooks.onCodeSimulator != null,
      hint: 'LoginPage onCodeSimulator 未就绪',
      timeout: const Duration(seconds: 20),
    );
    _T.log('LoginPage onCodeSimulator ready');

    // 3. 等 WebView controller（顺便验证 WebView 也启动了）
    await _waitFor(
      tester,
      () async => LoginPageTestHooks.webViewController != null,
      hint: 'WebView controller 未就绪',
      timeout: const Duration(seconds: 30),
    );
    await _waitFor(
      tester,
      () async => LoginPageTestHooks.pageLoadCount >= 1,
      hint: 'WebView 首次未加载',
      timeout: const Duration(seconds: 20),
    );
    _T.log('WebView 已加载，lastUrl=${LoginPageTestHooks.lastUrl}');

    // 4. 直接走 HTTP API 拿 OAuth code（绕开 WKWebView 在测试态点 React 按钮会触发 dispose 的 bug）
    final code = await _fetchOAuthCode();

    // 5. 调用 LoginPage 的测试钩子，模拟"WebView 拦到 brainthink://callback?code=..."
    await LoginPageTestHooks.onCodeSimulator!(code);
    _T.log('已调用 onCodeSimulator invokeCount=${LoginPageTestHooks.onCodeInvokeCount} '
        'token=${LoginPageTestHooks.lastSessionToken == null ? "null" : "${LoginPageTestHooks.lastSessionToken!.substring(0, 12)}..."} '
        'error=${LoginPageTestHooks.lastExchangeError}');

    // 6. 等 ChatInput 出现（exchange → token → 路由跳到 /chat）
    try {
      await _waitFor(
        tester,
        () async {
          await tester.pump(const Duration(milliseconds: 200));
          return find.byType(ChatInput).evaluate().isNotEmpty;
        },
        timeout: const Duration(seconds: 30),
        step: const Duration(milliseconds: 500),
        hint: '没进入 ChatPage（ChatInput 未出现）',
      );
    } on _TimeoutEx catch (e) {
      _T.log('ChatInput 等待超时. exchange 状态：'
          'invokeCount=${LoginPageTestHooks.onCodeInvokeCount} '
          'token=${LoginPageTestHooks.lastSessionToken} '
          'error=${LoginPageTestHooks.lastExchangeError}');
      throw e;
    }
    _T.log('已进入 ChatPage');
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    expect(find.text('头脑风暴'), findsOneWidget);

    // 7. 输入 + 发送
    final input = find.descendant(
      of: find.byType(ChatInput),
      matching: find.byType(TextField),
    );
    expect(input, findsOneWidget);
    await tester.enterText(input, kTestPrompt);
    await tester.pump(const Duration(milliseconds: 300));

    final sendBtn = find.byKey(const Key('chatInputSend'));
    expect(sendBtn, findsOneWidget);
    await tester.tap(sendBtn);
    _T.log('已点发送');

    // 8. 等 AI 回复出现 —— 用户气泡 + AI 气泡都会包含 kAiEcho（用户的 prompt 里有它），
    // 所以判定 ≥2 处出现，确保拿到的是真正的 AI 回复而非仅用户自己的输入回显
    await _waitFor(
      tester,
      () async {
        await tester.pump(const Duration(milliseconds: 500));
        if (find.text(kTestPrompt).evaluate().isEmpty) return false;
        return find.textContaining(kAiEcho).evaluate().length >= 2;
      },
      timeout: const Duration(seconds: 90),
      step: const Duration(seconds: 1),
      hint: 'AI 没回复 $kAiEcho',
    );
    _T.log('AI 回复已收到，端到端测试通过');

    expect(find.textContaining(kAiEcho).evaluate().length >= 2, isTrue);
  }, timeout: const Timeout(Duration(minutes: 6)));
}
