package com.brainthink.chat;

import com.brainthink.common.ApiResult;
import com.brainthink.common.BusinessException;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/chat")
@RequiredArgsConstructor
public class ChatController {

    private final ChatService chatService;

    @PostMapping("/send")
    public ApiResult<ChatDtos.SendResponse> send(@Valid @RequestBody ChatDtos.SendRequest req) {
        return ApiResult.ok(chatService.send(currentSessionId(), req.getConversationId(), req.getMessage(), req.getModel()));
    }

    @GetMapping("/history")
    public ApiResult<List<ChatDtos.HistoryItem>> history(@RequestParam(required = false) Long conversationId) {
        return ApiResult.ok(chatService.history(currentSessionId(), conversationId));
    }

    private String currentSessionId() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || auth.getPrincipal() == null) {
            throw new BusinessException(40101, "未登录");
        }
        return auth.getPrincipal().toString();
    }
}
