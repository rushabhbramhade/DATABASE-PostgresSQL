-- ============================================================
-- SOCIAL MEDIA PLATFORM DATABASE SCHEMA
-- Domain: Social networking (users, posts, comments, likes,
--         followers, direct messages, hashtags)
-- PostgreSQL 15+
-- ============================================================

-- ────────────────────────────────────────────────────────────
-- ENUM TYPES
-- ────────────────────────────────────────────────────────────

CREATE TYPE post_visibility AS ENUM ('public', 'friends', 'private');

CREATE TYPE account_status AS ENUM (
    'active', 'suspended', 'deactivated', 'banned'
);

CREATE TYPE message_status AS ENUM ('sent', 'delivered', 'read');

-- ────────────────────────────────────────────────────────────
-- 1. USERS
-- ────────────────────────────────────────────────────────────
CREATE TABLE users (
    user_id        SERIAL          PRIMARY KEY,
    username       VARCHAR(30)     NOT NULL UNIQUE,
    email          VARCHAR(100)    NOT NULL UNIQUE,
    password_hash  VARCHAR(255)    NOT NULL,
    display_name   VARCHAR(100),
    bio            TEXT,
    avatar_url     TEXT,
    date_of_birth  DATE,
    status         account_status  NOT NULL DEFAULT 'active',
    is_verified    BOOLEAN         NOT NULL DEFAULT FALSE,
    created_at     TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE users IS 'Platform user accounts';

CREATE INDEX idx_users_username  ON users (username);
CREATE INDEX idx_users_email     ON users (email);
CREATE INDEX idx_users_status    ON users (status);

-- ────────────────────────────────────────────────────────────
-- 2. FOLLOWERS  (self-referencing many-to-many)
-- ────────────────────────────────────────────────────────────
CREATE TABLE followers (
    follower_id    INT          NOT NULL
                                REFERENCES users(user_id)
                                ON DELETE CASCADE,
    following_id   INT          NOT NULL
                                REFERENCES users(user_id)
                                ON DELETE CASCADE,
    created_at     TIMESTAMPTZ  NOT NULL DEFAULT NOW(),

    PRIMARY KEY (follower_id, following_id),

    -- A user cannot follow themselves
    CONSTRAINT chk_no_self_follow CHECK (follower_id <> following_id)
);

COMMENT ON TABLE followers IS 'Self-referencing follow relationships between users';

CREATE INDEX idx_followers_following ON followers (following_id);

-- ────────────────────────────────────────────────────────────
-- 3. POSTS
-- ────────────────────────────────────────────────────────────
CREATE TABLE posts (
    post_id        SERIAL           PRIMARY KEY,
    user_id        INT              NOT NULL
                                    REFERENCES users(user_id)
                                    ON DELETE CASCADE,
    content        TEXT             NOT NULL
                                    CHECK (LENGTH(content) <= 5000),
    media_url      TEXT,
    visibility     post_visibility  NOT NULL DEFAULT 'public',
    like_count     INT              NOT NULL DEFAULT 0
                                    CHECK (like_count >= 0),
    comment_count  INT              NOT NULL DEFAULT 0
                                    CHECK (comment_count >= 0),
    is_deleted     BOOLEAN          NOT NULL DEFAULT FALSE,
    created_at     TIMESTAMPTZ      NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMPTZ      NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE posts IS 'User-generated posts with visibility controls';

CREATE INDEX idx_posts_user       ON posts (user_id);
CREATE INDEX idx_posts_created    ON posts (created_at DESC);
CREATE INDEX idx_posts_visibility ON posts (visibility);

-- Partial index: only non-deleted posts (used for feeds)
CREATE INDEX idx_posts_active ON posts (created_at DESC)
    WHERE is_deleted = FALSE;

-- ────────────────────────────────────────────────────────────
-- 4. COMMENTS
-- ────────────────────────────────────────────────────────────
CREATE TABLE comments (
    comment_id     SERIAL        PRIMARY KEY,
    post_id        INT           NOT NULL
                                 REFERENCES posts(post_id)
                                 ON DELETE CASCADE,
    user_id        INT           NOT NULL
                                 REFERENCES users(user_id)
                                 ON DELETE CASCADE,
    parent_id      INT           REFERENCES comments(comment_id)
                                 ON DELETE CASCADE,
    content        TEXT          NOT NULL
                                 CHECK (LENGTH(content) <= 2000),
    like_count     INT           NOT NULL DEFAULT 0
                                 CHECK (like_count >= 0),
    is_deleted     BOOLEAN       NOT NULL DEFAULT FALSE,
    created_at     TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE comments
    IS 'Threaded comments on posts (parent_id enables nested replies)';

CREATE INDEX idx_comments_post    ON comments (post_id);
CREATE INDEX idx_comments_user    ON comments (user_id);
CREATE INDEX idx_comments_parent  ON comments (parent_id);

-- ────────────────────────────────────────────────────────────
-- 5. LIKES
-- ────────────────────────────────────────────────────────────
CREATE TABLE likes (
    user_id        INT          NOT NULL
                                REFERENCES users(user_id)
                                ON DELETE CASCADE,
    post_id        INT          NOT NULL
                                REFERENCES posts(post_id)
                                ON DELETE CASCADE,
    created_at     TIMESTAMPTZ  NOT NULL DEFAULT NOW(),

    PRIMARY KEY (user_id, post_id)
);

COMMENT ON TABLE likes IS 'One-like-per-user-per-post relationship';

CREATE INDEX idx_likes_post ON likes (post_id);

-- ────────────────────────────────────────────────────────────
-- 6. MESSAGES  (direct / private messages)
-- ────────────────────────────────────────────────────────────
CREATE TABLE messages (
    message_id     SERIAL          PRIMARY KEY,
    sender_id      INT             NOT NULL
                                   REFERENCES users(user_id)
                                   ON DELETE CASCADE,
    receiver_id    INT             NOT NULL
                                   REFERENCES users(user_id)
                                   ON DELETE CASCADE,
    content        TEXT            NOT NULL,
    status         message_status  NOT NULL DEFAULT 'sent',
    is_deleted     BOOLEAN         NOT NULL DEFAULT FALSE,
    created_at     TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_no_self_message CHECK (sender_id <> receiver_id)
);

COMMENT ON TABLE messages IS 'Direct messages between two users';

CREATE INDEX idx_msg_sender    ON messages (sender_id);
CREATE INDEX idx_msg_receiver  ON messages (receiver_id);
CREATE INDEX idx_msg_created   ON messages (created_at DESC);

-- Conversation lookup: messages between two specific users
CREATE INDEX idx_msg_conversation
    ON messages (LEAST(sender_id, receiver_id),
                 GREATEST(sender_id, receiver_id),
                 created_at DESC);

-- ────────────────────────────────────────────────────────────
-- 7. HASHTAGS
-- ────────────────────────────────────────────────────────────
CREATE TABLE hashtags (
    hashtag_id     SERIAL        PRIMARY KEY,
    tag            VARCHAR(100)  NOT NULL UNIQUE,
    created_at     TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE hashtags IS 'Unique hashtag directory';

CREATE INDEX idx_hashtags_tag ON hashtags (tag);

-- ────────────────────────────────────────────────────────────
-- 8. POST_HASHTAGS  (many-to-many junction)
-- ────────────────────────────────────────────────────────────
CREATE TABLE post_hashtags (
    post_id        INT   NOT NULL
                         REFERENCES posts(post_id)
                         ON DELETE CASCADE,
    hashtag_id     INT   NOT NULL
                         REFERENCES hashtags(hashtag_id)
                         ON DELETE CASCADE,

    PRIMARY KEY (post_id, hashtag_id)
);

COMMENT ON TABLE post_hashtags IS 'Many-to-many link between posts and hashtags';

CREATE INDEX idx_ph_hashtag ON post_hashtags (hashtag_id);

-- ============================================================
-- KEY TAKEAWAYS
-- ============================================================
-- 1. followers is a self-referencing many-to-many on users
--    with a CHECK to prevent self-follows
-- 2. post_hashtags is a classic junction/bridge table
-- 3. comments.parent_id enables unlimited nesting (threaded)
-- 4. likes uses a composite PK (user_id, post_id) to enforce
--    one-like-per-user naturally
-- 5. Denormalized counters (like_count, comment_count) on posts
--    avoid expensive COUNT queries for feeds
-- 6. Conversation index on messages uses LEAST/GREATEST to
--    efficiently look up all messages between any two users
-- ============================================================
