CREATE TABLE IF NOT EXISTS user_session (
    session_id          VARCHAR(64) PRIMARY KEY,
    plat_user_id        BIGINT      NOT NULL,
    plat_access_token   TEXT        NOT NULL,
    plat_refresh_token  TEXT,
    plat_expires_at     TIMESTAMPTZ NOT NULL,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_user_session_uid ON user_session (plat_user_id);

CREATE TABLE IF NOT EXISTS chat_message (
    id          BIGSERIAL PRIMARY KEY,
    session_id  VARCHAR(64) NOT NULL REFERENCES user_session(session_id) ON DELETE CASCADE,
    role        VARCHAR(16) NOT NULL,
    content     TEXT        NOT NULL,
    model       VARCHAR(64),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_chat_message_session
    ON chat_message (session_id, created_at);
