package com.brainthink.chat;

import com.brainthink.config.ChatProperties;
import com.brainthink.domain.ChatMessageEntity;
import com.brainthink.domain.ChatMessageRepository;
import com.brainthink.domain.Conversation;
import com.brainthink.platform.PlatformBrainClient;
import com.brainthink.platform.dto.ChatCompletionDto;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class ChatService {

    private final ChatMessageRepository msgRepo;
    private final ConversationService convService;
    private final PlatformBrainClient brainClient;
    private final ChatProperties chatProps;

    @Transactional
    public ChatDtos.SendResponse send(String sessionId, Long conversationId, String userText, String overrideModel) {
        Conversation conv = (conversationId == null)
                ? convService.latestOrCreate(sessionId)
                : convService.require(sessionId, conversationId);

        String model = (overrideModel == null || overrideModel.isBlank())
                ? chatProps.getDefaultModel()
                : overrideModel;

        List<ChatMessageEntity> history = msgRepo.findByConversationIdOrderByCreatedAtDesc(
                conv.getId(), PageRequest.of(0, chatProps.getMaxHistory()));
        Collections.reverse(history);

        boolean firstMessage = history.isEmpty();

        List<ChatCompletionDto.Message> messages = new ArrayList<>();
        if (chatProps.getSystemPrompt() != null && !chatProps.getSystemPrompt().isBlank()) {
            messages.add(new ChatCompletionDto.Message("system", chatProps.getSystemPrompt()));
        }
        for (ChatMessageEntity m : history) {
            messages.add(new ChatCompletionDto.Message(m.getRole(), m.getContent()));
        }
        messages.add(new ChatCompletionDto.Message("user", userText));

        ChatCompletionDto.Response resp = brainClient.complete(model, messages);
        String reply = "";
        String responseModel = resp.getModel() != null ? resp.getModel() : model;
        if (resp.getChoices() != null && !resp.getChoices().isEmpty()
                && resp.getChoices().get(0).getMessage() != null) {
            reply = resp.getChoices().get(0).getMessage().getContent();
        }

        ChatMessageEntity userMsg = new ChatMessageEntity();
        userMsg.setSessionId(sessionId);
        userMsg.setConversationId(conv.getId());
        userMsg.setRole("user");
        userMsg.setContent(userText);
        msgRepo.save(userMsg);

        ChatMessageEntity asstMsg = new ChatMessageEntity();
        asstMsg.setSessionId(sessionId);
        asstMsg.setConversationId(conv.getId());
        asstMsg.setRole("assistant");
        asstMsg.setContent(reply);
        asstMsg.setModel(responseModel);
        msgRepo.save(asstMsg);

        if (firstMessage) {
            convService.renameIfDefault(conv.getId(), userText);
        }
        convService.touch(conv.getId());

        return new ChatDtos.SendResponse(reply, responseModel, conv.getId());
    }

    public List<ChatDtos.HistoryItem> history(String sessionId, Long conversationId) {
        Conversation conv = (conversationId == null)
                ? convService.latestOrCreate(sessionId)
                : convService.require(sessionId, conversationId);
        return msgRepo.findByConversationIdOrderByCreatedAtAsc(conv.getId()).stream()
                .map(m -> new ChatDtos.HistoryItem(
                        m.getId(), m.getRole(), m.getContent(), m.getModel(), m.getCreatedAt()))
                .toList();
    }
}
