package com.brainthink.platform;

import com.brainthink.common.BusinessException;
import com.brainthink.common.PlatformResult;
import com.brainthink.config.PlatformProperties;
import com.brainthink.platform.dto.TokenResponse;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

import java.util.HashMap;
import java.util.Map;

@Slf4j
@Component
@RequiredArgsConstructor
public class PlatformOAuthClient {

    private final RestClient platformRestClient;
    private final PlatformProperties props;
    private final ObjectMapper objectMapper;

    public TokenResponse exchange(String code) {
        if (props.getClientId() == null || props.getClientId().isBlank()) {
            throw new BusinessException(50001, "PLATFORM_CLIENT_ID 未配置");
        }
        Map<String, String> body = new HashMap<>();
        body.put("clientId", props.getClientId());
        body.put("clientSecret", props.getClientSecret());
        body.put("code", code);
        body.put("grantType", "authorization_code");

        PlatformResult<TokenResponse> result = postForResult(
                "/v1/oauth/token", body,
                new TypeReference<PlatformResult<TokenResponse>>() {});
        if (!result.isOk() || result.getData() == null) {
            log.warn("OAuth token exchange failed: {}", result.getMessage());
            throw new BusinessException(40100, "授权码换 Token 失败：" + result.getMessage());
        }
        return result.getData();
    }

    public TokenResponse refresh(String refreshToken) {
        Map<String, String> body = new HashMap<>();
        body.put("clientId", props.getClientId());
        body.put("clientSecret", props.getClientSecret());
        body.put("refreshToken", refreshToken);

        PlatformResult<TokenResponse> result = postForResult(
                "/v1/oauth/refresh", body,
                new TypeReference<PlatformResult<TokenResponse>>() {});
        if (!result.isOk() || result.getData() == null) {
            throw new BusinessException(40100, "刷新 Token 失败：" + result.getMessage());
        }
        return result.getData();
    }

    public void revoke(String refreshToken) {
        Map<String, String> body = new HashMap<>();
        body.put("clientId", props.getClientId());
        body.put("clientSecret", props.getClientSecret());
        body.put("token", refreshToken);
        platformRestClient.post()
                .uri("/v1/oauth/revoke")
                .contentType(MediaType.APPLICATION_JSON)
                .body(body)
                .retrieve()
                .toBodilessEntity();
    }

    private <T> PlatformResult<T> postForResult(String uri, Object body,
                                                TypeReference<PlatformResult<T>> typeRef) {
        String raw = platformRestClient.post()
                .uri(uri)
                .contentType(MediaType.APPLICATION_JSON)
                .body(body)
                .retrieve()
                .body(String.class);
        try {
            return objectMapper.readValue(raw == null ? "{}" : raw, typeRef);
        } catch (Exception e) {
            log.error("parse platform response fail: {}", raw, e);
            throw new BusinessException(50002, "解析平台响应失败");
        }
    }
}
