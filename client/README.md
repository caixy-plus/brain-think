# brain-think client

Flutter 跨平台客户端：macOS / Windows / Android / iOS。

## 配置

打开 `lib/config.dart`，按部署环境修改：

```dart
static const String kBrainThinkBaseUrl = 'http://localhost:9080/api';
static const String kPlatformWebBase   = 'http://localhost:3000';
static const String kOAuthClientId     = '<在 app_plat 控制台创建应用后的 clientId>';
static const String kRedirectUri       = 'brainthink://callback'; // 创建应用时必须包含
static const String kScope             = 'read';
```

> Android 模拟器：把上面的 `localhost` 换成 `10.0.2.2`

## 跑

```bash
flutter pub get
flutter run -d macos          # 或 windows / iOS / Android (需先连模拟器或真机)
```

## 流程

1. 启动 → 无 token → `/login`
2. `LoginPage` 打开 InAppWebView，加载 `kPlatformWebBase/oauth/authorize?...`
3. 用户在 WebView 内：登录 → 同意授权
4. app_plat 前端执行 `window.location = brainthink://callback?code=…`
5. WebView `shouldOverrideUrlLoading` 命中 `brainthink` scheme → 提取 `code`
6. `authProvider.exchange(code)` → POST `/api/auth/exchange` → 拿 sessionToken 入安全存储
7. 路由跳 `/chat` → 输入消息 → POST `/api/chat/send` → 渲染回复气泡

## 平台差异

| 平台 | 关键配置 |
|---|---|
| iOS | `Info.plist` 已加 `NSAllowsArbitraryLoads`（开发期允许 http localhost） |
| Android | `AndroidManifest.xml` 已加 `INTERNET` 权限 + `usesCleartextTraffic` |
| macOS | `Debug/Release.entitlements` 已加 `com.apple.security.network.client` |
| Windows | 依赖 WebView2 Runtime（Win10 1803+ 内置；老版本需安装 Evergreen） |
