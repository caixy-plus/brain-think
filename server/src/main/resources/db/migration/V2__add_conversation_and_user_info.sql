-- 多会话支持：为每条 chat_message 关联一个 conversation
CREATE TABLE IF NOT EXISTS conversation (
    id          BIGSERIAL PRIMARY KEY,
    session_id  VARCHAR(64)  NOT NULL REFERENCES user_session(session_id) ON DELETE CASCADE,
    title       VARCHAR(255) NOT NULL DEFAULT '新会话',
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_conversation_session
    ON conversation (session_id, updated_at DESC);

-- chat_message.conversation_id（先可空，便于回填）
ALTER TABLE chat_message ADD COLUMN IF NOT EXISTS conversation_id BIGINT;

-- 把每个 session 的所有老消息合并到一条「历史对话」会话
INSERT INTO conversation (session_id, title, created_at, updated_at)
SELECT m.session_id, '历史对话', NOW(), NOW()
FROM chat_message m
WHERE m.conversation_id IS NULL
GROUP BY m.session_id;

UPDATE chat_message m
SET conversation_id = c.id
FROM conversation c
WHERE m.conversation_id IS NULL
  AND c.session_id = m.session_id
  AND c.title = '历史对话';

-- 之后强约束 NOT NULL + 外键
ALTER TABLE chat_message ALTER COLUMN conversation_id SET NOT NULL;
ALTER TABLE chat_message
    ADD CONSTRAINT fk_chat_message_conversation
    FOREIGN KEY (conversation_id) REFERENCES conversation(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_chat_message_conversation
    ON chat_message (conversation_id, created_at);

-- user_session 增加用户展示信息（email、display_name），用于客户端头像/弹窗
ALTER TABLE user_session ADD COLUMN IF NOT EXISTS email        VARCHAR(255);
ALTER TABLE user_session ADD COLUMN IF NOT EXISTS display_name VARCHAR(255);
