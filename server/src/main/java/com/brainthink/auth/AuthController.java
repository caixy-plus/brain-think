package com.brainthink.auth;

import com.brainthink.common.ApiResult;
import com.brainthink.common.BusinessException;
import com.brainthink.domain.UserSession;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final SessionService sessionService;

    @PostMapping("/exchange")
    public ApiResult<AuthDtos.ExchangeResponse> exchange(@Valid @RequestBody AuthDtos.ExchangeRequest req) {
        return ApiResult.ok(sessionService.exchange(req.getCode()));
    }

    @GetMapping("/me")
    public ApiResult<AuthDtos.MeResponse> me() {
        String sessionId = currentSessionId();
        UserSession s = sessionService.require(sessionId);
        return ApiResult.ok(new AuthDtos.MeResponse(
                s.getSessionId(), s.getPlatUserId(), s.getEmail(), s.getDisplayName()));
    }

    @PostMapping("/refresh")
    public ApiResult<AuthDtos.ExchangeResponse> refresh() {
        return ApiResult.ok(sessionService.refresh(currentSessionId()));
    }

    @PostMapping("/logout")
    public ApiResult<Void> logout() {
        sessionService.logout(currentSessionId());
        return ApiResult.ok();
    }

    private String currentSessionId() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || auth.getPrincipal() == null) {
            throw new BusinessException(40101, "未登录");
        }
        return auth.getPrincipal().toString();
    }
}
