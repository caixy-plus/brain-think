package com.brainthink;

import com.brainthink.config.ChatProperties;
import com.brainthink.config.JwtProperties;
import com.brainthink.config.PlatformProperties;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.EnableConfigurationProperties;

@SpringBootApplication
@EnableConfigurationProperties({PlatformProperties.class, JwtProperties.class, ChatProperties.class})
public class BrainThinkApplication {

    public static void main(String[] args) {
        SpringApplication.run(BrainThinkApplication.class, args);
    }
}
