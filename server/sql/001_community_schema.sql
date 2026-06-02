-- Community schema for MelodyShare server
-- Run order: single file, all CREATE IF NOT EXISTS

-- ============================================================
-- Users
-- ============================================================
CREATE TABLE IF NOT EXISTS users (
    id              UUID PRIMARY KEY,
    username        VARCHAR(50) UNIQUE NOT NULL,
    email           VARCHAR(255) UNIQUE NOT NULL,
    password_hash   VARCHAR(255) NOT NULL,
    display_name    VARCHAR(100) NOT NULL DEFAULT '',
    bio             TEXT NOT NULL DEFAULT '',
    avatar_url      VARCHAR(512) NOT NULL DEFAULT '',
    role            VARCHAR(20) NOT NULL DEFAULT 'user',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- Auth sessions / refresh tokens
-- ============================================================
CREATE TABLE IF NOT EXISTS sessions (
    id              UUID PRIMARY KEY,
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash      VARCHAR(255) NOT NULL,
    device_info     VARCHAR(255) NOT NULL DEFAULT '',
    expires_at      TIMESTAMPTZ NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- User-created playlists
-- ============================================================
CREATE TABLE IF NOT EXISTS playlists (
    id              UUID PRIMARY KEY,
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title           VARCHAR(255) NOT NULL,
    description     TEXT NOT NULL DEFAULT '',
    cover_url       VARCHAR(512) NOT NULL DEFAULT '',
    is_public       BOOLEAN NOT NULL DEFAULT TRUE,
    track_count     INTEGER NOT NULL DEFAULT 0,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- Playlist ↔ tracks (ordered many-to-many)
-- ============================================================
CREATE TABLE IF NOT EXISTS playlist_tracks (
    id              UUID PRIMARY KEY,
    playlist_id     UUID NOT NULL REFERENCES playlists(id) ON DELETE CASCADE,
    track_id        UUID NOT NULL REFERENCES tracks(id) ON DELETE CASCADE,
    sort_order      INTEGER NOT NULL DEFAULT 0,
    added_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(playlist_id, track_id)
);

-- ============================================================
-- User follows (directed)
-- ============================================================
CREATE TABLE IF NOT EXISTS follows (
    id              UUID PRIMARY KEY,
    follower_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    followee_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(follower_id, followee_id)
);

-- ============================================================
-- Track likes / favorites
-- ============================================================
CREATE TABLE IF NOT EXISTS track_likes (
    id              UUID PRIMARY KEY,
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    track_id        UUID NOT NULL REFERENCES tracks(id) ON DELETE CASCADE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, track_id)
);

-- ============================================================
-- Comments on tracks (threaded via parent_id)
-- ============================================================
CREATE TABLE IF NOT EXISTS comments (
    id              UUID PRIMARY KEY,
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    track_id        UUID NOT NULL REFERENCES tracks(id) ON DELETE CASCADE,
    parent_id       UUID REFERENCES comments(id) ON DELETE CASCADE,
    content         TEXT NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- Notification feed
-- ============================================================
CREATE TABLE IF NOT EXISTS notifications (
    id              UUID PRIMARY KEY,
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    actor_id        UUID REFERENCES users(id) ON DELETE SET NULL,
    type            VARCHAR(50) NOT NULL,
    entity_type     VARCHAR(50) NOT NULL DEFAULT '',
    entity_id       UUID,
    content         TEXT NOT NULL DEFAULT '',
    is_read         BOOLEAN NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- Indexes
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_sessions_user_id      ON sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_expires_at   ON sessions(expires_at);
CREATE INDEX IF NOT EXISTS idx_playlists_user_id     ON playlists(user_id);
CREATE INDEX IF NOT EXISTS idx_playlist_tracks_playlist ON playlist_tracks(playlist_id);
CREATE INDEX IF NOT EXISTS idx_playlist_tracks_track    ON playlist_tracks(track_id);
CREATE INDEX IF NOT EXISTS idx_playlist_tracks_sort     ON playlist_tracks(playlist_id, sort_order);
CREATE INDEX IF NOT EXISTS idx_follows_follower      ON follows(follower_id);
CREATE INDEX IF NOT EXISTS idx_follows_followee      ON follows(followee_id);
CREATE INDEX IF NOT EXISTS idx_track_likes_user      ON track_likes(user_id);
CREATE INDEX IF NOT EXISTS idx_track_likes_track     ON track_likes(track_id);
CREATE INDEX IF NOT EXISTS idx_comments_track        ON comments(track_id);
CREATE INDEX IF NOT EXISTS idx_comments_parent       ON comments(parent_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user    ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_unread  ON notifications(user_id, is_read);
