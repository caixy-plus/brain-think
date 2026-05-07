package com.brainthink.platform.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.Data;

@Data
@JsonIgnoreProperties(ignoreUnknown = true)
public class TokenResponse {
    private String accessToken;
    private String refreshToken;
    private String tokenType;
    /** 平台返回的是字符串(秒数) */
    private String expiresIn;
}
