package com.brainthink.auth;

import com.brainthink.common.BusinessException;
import com.brainthink.config.JwtProperties;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.Date;

@Service
@RequiredArgsConstructor
public class JwtService {

    private final JwtProperties props;

    private SecretKey key() {
        byte[] bytes = props.getSecret().getBytes(StandardCharsets.UTF_8);
        if (bytes.length < 32) {
            throw new IllegalStateException("brainthink.jwt.secret 长度必须 >=32 bytes");
        }
        return Keys.hmacShaKeyFor(bytes);
    }

    public String issue(String sessionId) {
        Instant now = Instant.now();
        return Jwts.builder()
                .subject(sessionId)
                .issuedAt(Date.from(now))
                .expiration(Date.from(now.plusSeconds(props.getExpireSeconds())))
                .signWith(key())
                .compact();
    }

    public String parseSessionId(String token) {
        try {
            Claims claims = Jwts.parser()
                    .verifyWith(key())
                    .build()
                    .parseSignedClaims(token)
                    .getPayload();
            return claims.getSubject();
        } catch (Exception e) {
            throw new BusinessException(40101, "无效或已过期的会话 Token");
        }
    }

    /** 只验签不校验过期时间 —— 供 refresh 接口在 token 过期后仍能提取 sessionId */
    public String parseSessionIdWithoutExpiry(String token) {
        try {
            Claims claims = Jwts.parser()
                    .verifyWith(key())
                    .build()
                    .parseSignedClaims(token)
                    .getPayload();
            return claims.getSubject();
        } catch (Exception e) {
            throw new BusinessException(40101, "无效的会话 Token");
        }
    }
}
