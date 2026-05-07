package com.brainthink.chat;

import com.brainthink.common.BusinessException;
import com.brainthink.domain.ChatMessageRepository;
import com.brainthink.domain.Conversation;
import com.brainthink.domain.ConversationRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;

@Service
@RequiredArgsConstructor
public class ConversationService {

    private final ConversationRepository convRepo;
    private final ChatMessageRepository msgRepo;

    public List<Conversation> list(String sessionId) {
        return convRepo.findBySessionIdOrderByUpdatedAtDesc(sessionId);
    }

    @Transactional
    public Conversation create(String sessionId) {
        Conversation c = new Conversation();
        c.setSessionId(sessionId);
        c.setTitle("新会话");
        return convRepo.save(c);
    }

    public Conversation require(String sessionId, Long id) {
        return convRepo.findByIdAndSessionId(id, sessionId)
                .orElseThrow(() -> new BusinessException(40404, "会话不存在"));
    }

    /** 拿最新会话；没有就新建一条，方便老客户端 / 单会话场景 */
    @Transactional
    public Conversation latestOrCreate(String sessionId) {
        List<Conversation> list = convRepo.findBySessionIdOrderByUpdatedAtDesc(sessionId);
        if (!list.isEmpty()) return list.get(0);
        return create(sessionId);
    }

    @Transactional
    public void delete(String sessionId, Long id) {
        Conversation c = require(sessionId, id);
        msgRepo.deleteByConversationId(c.getId());
        convRepo.delete(c);
    }

    @Transactional
    public void touch(Long conversationId) {
        convRepo.findById(conversationId).ifPresent(c -> {
            c.setUpdatedAt(Instant.now());
            convRepo.save(c);
        });
    }

    @Transactional
    public void renameIfDefault(Long conversationId, String firstUserMessage) {
        convRepo.findById(conversationId).ifPresent(c -> {
            if ("新会话".equals(c.getTitle()) && firstUserMessage != null && !firstUserMessage.isBlank()) {
                String t = firstUserMessage.strip();
                if (t.length() > 30) t = t.substring(0, 30) + "…";
                c.setTitle(t);
                convRepo.save(c);
            }
        });
    }
}
