package com.brainthink.domain;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface ConversationRepository extends JpaRepository<Conversation, Long> {
    List<Conversation> findBySessionIdOrderByUpdatedAtDesc(String sessionId);

    Optional<Conversation> findByIdAndSessionId(Long id, String sessionId);
}
