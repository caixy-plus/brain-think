package com.brainthink.auth;

import com.brainthink.common.BusinessException;
import com.brainthink.domain.UserSession;
import com.brainthink.domain.UserSessionRepository;
import com.brainthink.platform.PlatformOAuthClient;
import com.brainthink.platform.dto.TokenResponse;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.Base64;
import java.util.Map;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class SessionService {

    private final PlatformOAuthClient oauthClient;
    private final UserSessionRepository sessionRepo;
    private final JwtService jwtService;
    private final ObjectMapper objectMapper;

    @Transactional
    public AuthDtos.ExchangeResponse exchange(String code) {
        TokenResponse t = oauthClient.exchange(code);

        long expiresIn;
        try {
            expiresIn = Long.parseLong(t.getExpiresIn());
        } catch (Exception e) {
            expiresIn = 3600L;
        }

        // 解析平台 access_token JWT 的 payload，拿 userId / email
        long platUid = 0L;
        String email = null;
        String displayName = null;
        try {
            Map<String, Object> claims = decodeJwtPayload(t.getAccessToken());
            Object uid = claims.get("userId");
            if (uid instanceof Number n) {
                platUid = n.longValue();
            } else if (uid != null) {
                platUid = Long.parseLong(uid.toString());
            }
            Object em = claims.get("email");
            if (em != null) email = em.toString();
            Object nm = claims.get("displayName");
            if (nm == null) nm = claims.get("name");
            if (nm == null) nm = claims.get("username");
            if (nm != null) displayName = nm.toString();
        } catch (Exception e) {
            log.warn("解析 platform access_token 失败：{}", e.toString());
        }

        String sessionId = UUID.randomUUID().toString().replace("-", "");
        UserSession s = new UserSession();
        s.setSessionId(sessionId);
        s.setPlatUserId(platUid);
        s.setPlatAccessToken(t.getAccessToken());
        s.setPlatRefreshToken(t.getRefreshToken());
        s.setPlatExpiresAt(Instant.now().plusSeconds(expiresIn));
        s.setEmail(email);
        s.setDisplayName(displayName);
        sessionRepo.save(s);

        String btJwt = jwtService.issue(sessionId);
        return new AuthDtos.ExchangeResponse(btJwt, sessionId);
    }

    public UserSession require(String sessionId) {
        return sessionRepo.findById(sessionId)
                .orElseThrow(() -> new com.brainthink.common.BusinessException(40101, "会话不存在"));
    }

    @Transactional
    public AuthDtos.ExchangeResponse refresh(String sessionId) {
        UserSession s = sessionRepo.findById(sessionId)
                .orElseThrow(() -> new BusinessException(40101, "会话不存在"));
        if (s.getPlatRefreshToken() == null || s.getPlatRefreshToken().isBlank()) {
            throw new BusinessException(40101, "刷新令牌不存在，请重新登录");
        }
        TokenResponse t = oauthClient.refresh(s.getPlatRefreshToken());
        long expiresIn;
        try {
            expiresIn = Long.parseLong(t.getExpiresIn());
        } catch (Exception e) {
            expiresIn = 3600L;
        }
        s.setPlatAccessToken(t.getAccessToken());
        s.setPlatRefreshToken(t.getRefreshToken());
        s.setPlatExpiresAt(Instant.now().plusSeconds(expiresIn));
        sessionRepo.save(s);
        String btJwt = jwtService.issue(sessionId);
        return new AuthDtos.ExchangeResponse(btJwt, sessionId);
    }

    @Transactional
    public void logout(String sessionId) {
        UserSession s = sessionRepo.findById(sessionId).orElse(null);
        if (s != null && s.getPlatRefreshToken() != null) {
            try {
                oauthClient.revoke(s.getPlatRefreshToken());
            } catch (Exception e) {
                log.warn("revoke platform refresh token failed: {}", e.getMessage());
            }
        }
        sessionRepo.deleteById(sessionId);
    }

    /** 不验签直接 base64 解 JWT payload —— 平台返回的 token 我们已经信任 */
    @SuppressWarnings("unchecked")
    private Map<String, Object> decodeJwtPayload(String jwt) throws Exception {
        if (jwt == null) return Map.of();
        String[] parts = jwt.split("\\.");
        if (parts.length < 2) return Map.of();
        byte[] payload = Base64.getUrlDecoder().decode(parts[1]);
        return objectMapper.readValue(new String(payload, StandardCharsets.UTF_8), Map.class);
    }
}
