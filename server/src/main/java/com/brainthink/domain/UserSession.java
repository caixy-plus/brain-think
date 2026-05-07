package com.brainthink.domain;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;

@Entity
@Table(name = "user_session")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class UserSession {

    @Id
    @Column(name = "session_id", length = 64)
    private String sessionId;

    @Column(name = "plat_user_id", nullable = false)
    private Long platUserId;

    @Column(name = "plat_access_token", nullable = false, columnDefinition = "TEXT")
    private String platAccessToken;

    @Column(name = "plat_refresh_token", columnDefinition = "TEXT")
    private String platRefreshToken;

    @Column(name = "plat_expires_at", nullable = false)
    private Instant platExpiresAt;

    @Column(name = "email", length = 255)
    private String email;

    @Column(name = "display_name", length = 255)
    private String displayName;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @PrePersist
    void onCreate() {
        Instant now = Instant.now();
        if (createdAt == null) createdAt = now;
        updatedAt = now;
    }

    @PreUpdate
    void onUpdate() {
        updatedAt = Instant.now();
    }
}
