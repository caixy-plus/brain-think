# brain-think server

Spring Boot 3.3 + Java 21。承载 OAuth 回调编排、脑池 API 转发、会话与对话存储。

## 启动

```bash
# 1) app_plat 已启动（PostgreSQL :5433、后端 :8080）
# 2) 配置环境变量（参考 .env.example）
export PLATFORM_CLIENT_ID=...        # app_plat 控制台创建的 OAuth 应用 clientId
export PLATFORM_CLIENT_SECRET=...
export PLATFORM_BRAIN_API_KEY=dev-key-2024   # 默认即可，平台默认 naochi.api-keys 包含此 key
export BT_JWT_SECRET=$(openssl rand -hex 32) # 32 字节以上随机串

# 3) 跑
mvn spring-boot:run
# 或先打包
mvn -DskipTests package
java -jar target/brain-think-server-0.1.0.jar
```

启动后健康检查：

```bash
curl http://localhost:9080/api/health
```

## 路由速览

| 方法 | 路径 | 鉴权 | 说明 |
|---|---|---|---|
| POST | `/api/auth/exchange` | 公开 | `{code}` → `{sessionToken, sessionId}` |
| GET  | `/api/auth/me` | Bearer | 返回当前会话 |
| POST | `/api/auth/logout` | Bearer | 退出登录 |
| POST | `/api/chat/send` | Bearer | `{message, model?}` → `{reply, model}` |
| GET  | `/api/chat/history` | Bearer | 完整会话历史 |

## 数据库

`brainthink` schema，由 Flyway `V1__init_brainthink.sql` 自动建。

## 故障排查

- `db connection refused`：app_plat 的 PG 暴露在 5433，不是默认 5432
- `授权码换 Token 失败`：`PLATFORM_CLIENT_ID/SECRET` 与控制台创建的应用要一致
- `脑池调用失败`：先 cURL 验证 `/v1/brain/chat/completions` 是否能用 `dev-key-2024` 直接调通
