package com.brainthink.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;

@Data
@ConfigurationProperties(prefix = "platform")
public class PlatformProperties {
    private String baseUrl = "http://localhost:8080/api";
    private String clientId;
    private String clientSecret;
    private String brainApiKey;
}
