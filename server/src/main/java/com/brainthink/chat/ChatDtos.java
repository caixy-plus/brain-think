package com.brainthink.chat;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;

public class ChatDtos {

    @Data
    public static class SendRequest {
        @NotBlank
        private String message;
        private String model;
        /** 可选：在哪个会话里发；不传 = 自动选最新或新建 */
        private Long conversationId;
    }

    @Data
    @AllArgsConstructor
    @NoArgsConstructor
    public static class SendResponse {
        private String reply;
        private String model;
        private Long conversationId;
    }

    @Data
    @AllArgsConstructor
    @NoArgsConstructor
    public static class HistoryItem {
        private Long id;
        private String role;
        private String content;
        private String model;
        private Instant createdAt;
    }
}
