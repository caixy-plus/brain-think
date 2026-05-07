/// 运行时端点 — 默认本机直连（macOS / Windows / iOS 模拟器）
///
/// Android 模拟器请把 `localhost` 替换为 `10.0.2.2`：
///   - kBrainThinkBaseUrl: 'http://10.0.2.2:9080/api'
///   - kPlatformWebBase:   'http://10.0.2.2:3000'
class AppConfig {
  static const String kBrainThinkBaseUrl = 'https://bt.local.caixy.xin/api';
  static const String kPlatformWebBase = 'https://app.local.caixy.xin';

  /// 在 app_plat 控制台创建 OAuth 应用拿到，redirect_uris 必须包含 `brainthink://callback`
  static const String kOAuthClientId = '806bb3b61d59412ca6dc';
  static const String kRedirectUri = 'brainthink://callback';
  static const String kScope = 'read';
}
