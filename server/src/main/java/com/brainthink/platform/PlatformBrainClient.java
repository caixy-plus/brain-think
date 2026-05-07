package com.brainthink.platform;

import com.brainthink.common.BusinessException;
import com.brainthink.common.PlatformResult;
import com.brainthink.config.PlatformProperties;
import com.brainthink.platform.dto.ChatCompletionDto;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

import java.util.List;

@Slf4j
@Component
@RequiredArgsConstructor
public class PlatformBrainClient {

    private final RestClient platformRestClient;
    private final PlatformProperties props;
    private final ObjectMapper objectMapper;

    public ChatCompletionDto.Response complete(String model, List<ChatCompletionDto.Message> messages) {
        ChatCompletionDto.Request req = new ChatCompletionDto.Request();
        req.setModel(model);
        req.setMessages(messages);
        req.setTemperature(0.7);

        String raw = platformRestClient.post()
                .uri("/v1/brain/chat/completions")
                .header("X-API-Key", props.getBrainApiKey())
                .contentType(MediaType.APPLICATION_JSON)
                .body(req)
                .retrieve()
                .body(String.class);

        try {
            PlatformResult<ChatCompletionDto.Response> result = objectMapper.readValue(
                    raw == null ? "{}" : raw,
                    new TypeReference<PlatformResult<ChatCompletionDto.Response>>() {});
            if (!result.isOk() || result.getData() == null) {
                throw new BusinessException(50300, "脑池调用失败：" + result.getMessage());
            }
            return result.getData();
        } catch (BusinessException e) {
            throw e;
        } catch (Exception e) {
            log.error("parse brain response fail: {}", raw, e);
            throw new BusinessException(50301, "解析脑池响应失败");
        }
    }
}
