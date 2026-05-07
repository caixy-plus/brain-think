package com.brainthink.auth;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

public class AuthDtos {

    @Data
    public static class ExchangeRequest {
        @NotBlank
        private String code;
    }

    @Data
    @AllArgsConstructor
    @NoArgsConstructor
    public static class ExchangeResponse {
        private String sessionToken;
        private String sessionId;
    }

    @Data
    @AllArgsConstructor
    @NoArgsConstructor
    public static class MeResponse {
        private String sessionId;
        private Long platUserId;
        private String email;
        private String displayName;
    }
}
