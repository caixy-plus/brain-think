package com.brainthink.chat;

import com.brainthink.common.ApiResult;
import com.brainthink.common.BusinessException;
import com.brainthink.domain.ChatMessageRepository;
import com.brainthink.domain.Conversation;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.time.Instant;
import java.util.List;

@RestController
@RequestMapping("/api/conversations")
@RequiredArgsConstructor
public class ConversationController {

    private final ConversationService convService;
    private final ChatMessageRepository msgRepo;

    @GetMapping
    public ApiResult<List<ConvSummary>> list() {
        return ApiResult.ok(convService.list(currentSessionId()).stream()
                .map(c -> new ConvSummary(c.getId(), c.getTitle(), c.getCreatedAt(), c.getUpdatedAt()))
                .toList());
    }

    @PostMapping
    public ApiResult<ConvSummary> create() {
        Conversation c = convService.create(currentSessionId());
        return ApiResult.ok(new ConvSummary(c.getId(), c.getTitle(), c.getCreatedAt(), c.getUpdatedAt()));
    }

    @DeleteMapping("/{id}")
    public ApiResult<Void> delete(@PathVariable("id") Long id) {
        convService.delete(currentSessionId(), id);
        return ApiResult.ok();
    }

    @GetMapping("/{id}/messages")
    public ApiResult<List<ChatDtos.HistoryItem>> messages(@PathVariable("id") Long id) {
        Conversation c = convService.require(currentSessionId(), id);
        return ApiResult.ok(msgRepo.findByConversationIdOrderByCreatedAtAsc(c.getId()).stream()
                .map(m -> new ChatDtos.HistoryItem(
                        m.getId(), m.getRole(), m.getContent(), m.getModel(), m.getCreatedAt()))
                .toList());
    }

    private String currentSessionId() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || auth.getPrincipal() == null) {
            throw new BusinessException(40101, "未登录");
        }
        return auth.getPrincipal().toString();
    }

    @Data
    @AllArgsConstructor
    @NoArgsConstructor
    public static class ConvSummary {
        private Long id;
        private String title;
        private Instant createdAt;
        private Instant updatedAt;
    }
}
