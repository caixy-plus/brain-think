package com.brainthink.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;

@Data
@ConfigurationProperties(prefix = "brainthink.chat")
public class ChatProperties {
    private String defaultModel = "mimo-v2-pro";
    private int maxHistory = 20;
    private String systemPrompt;
}
