package com.brainthink.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;

@Data
@ConfigurationProperties(prefix = "brainthink.jwt")
public class JwtProperties {
    private String secret;
    private long expireSeconds = 86400;
}
