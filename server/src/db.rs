use sqlx::PgPool;
use uuid::Uuid;

use crate::models::track::Track;

pub async fn init_db(pool: &PgPool) {
    sqlx::query(
        r#"CREATE TABLE IF NOT EXISTS tracks (
            id UUID PRIMARY KEY,
            title VARCHAR(255) NOT NULL,
            artist VARCHAR(255) NOT NULL DEFAULT '',
            filename VARCHAR(255) NOT NULL,
            filepath VARCHAR(512) NOT NULL,
            uploaded_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
        )"#,
    )
    .execute(pool)
    .await
    .expect("Failed to create tracks table");

    init_community_db(pool).await;
}

async fn init_community_db(pool: &PgPool) {
    sqlx::query(
        r#"CREATE TABLE IF NOT EXISTS users (
            id UUID PRIMARY KEY,
            username VARCHAR(50) UNIQUE NOT NULL,
            email VARCHAR(255) UNIQUE NOT NULL,
            password_hash VARCHAR(255) NOT NULL,
            display_name VARCHAR(100) NOT NULL DEFAULT '',
            bio TEXT NOT NULL DEFAULT '',
            avatar_url VARCHAR(512) NOT NULL DEFAULT '',
            role VARCHAR(20) NOT NULL DEFAULT 'user',
            created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
            updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
        )"#,
    )
    .execute(pool)
    .await
    .expect("Failed to create users table");

    sqlx::query(
        r#"CREATE TABLE IF NOT EXISTS sessions (
            id UUID PRIMARY KEY,
            user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            token_hash VARCHAR(255) NOT NULL,
            device_info VARCHAR(255) NOT NULL DEFAULT '',
            expires_at TIMESTAMPTZ NOT NULL,
            created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
        )"#,
    )
    .execute(pool)
    .await
    .expect("Failed to create sessions table");

    sqlx::query(
        r#"CREATE TABLE IF NOT EXISTS playlists (
            id UUID PRIMARY KEY,
            user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            title VARCHAR(255) NOT NULL,
            description TEXT NOT NULL DEFAULT '',
            cover_url VARCHAR(512) NOT NULL DEFAULT '',
            is_public BOOLEAN NOT NULL DEFAULT TRUE,
            track_count INTEGER NOT NULL DEFAULT 0,
            created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
            updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
        )"#,
    )
    .execute(pool)
    .await
    .expect("Failed to create playlists table");

    sqlx::query(
        r#"CREATE TABLE IF NOT EXISTS playlist_tracks (
            id UUID PRIMARY KEY,
            playlist_id UUID NOT NULL REFERENCES playlists(id) ON DELETE CASCADE,
            track_id UUID NOT NULL REFERENCES tracks(id) ON DELETE CASCADE,
            sort_order INTEGER NOT NULL DEFAULT 0,
            added_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
            UNIQUE(playlist_id, track_id)
        )"#,
    )
    .execute(pool)
    .await
    .expect("Failed to create playlist_tracks table");

    sqlx::query(
        r#"CREATE TABLE IF NOT EXISTS follows (
            id UUID PRIMARY KEY,
            follower_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            followee_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
            UNIQUE(follower_id, followee_id)
        )"#,
    )
    .execute(pool)
    .await
    .expect("Failed to create follows table");

    sqlx::query(
        r#"CREATE TABLE IF NOT EXISTS track_likes (
            id UUID PRIMARY KEY,
            user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            track_id UUID NOT NULL REFERENCES tracks(id) ON DELETE CASCADE,
            created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
            UNIQUE(user_id, track_id)
        )"#,
    )
    .execute(pool)
    .await
    .expect("Failed to create track_likes table");

    sqlx::query(
        r#"CREATE TABLE IF NOT EXISTS comments (
            id UUID PRIMARY KEY,
            user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            track_id UUID NOT NULL REFERENCES tracks(id) ON DELETE CASCADE,
            parent_id UUID REFERENCES comments(id) ON DELETE CASCADE,
            content TEXT NOT NULL,
            created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
            updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
        )"#,
    )
    .execute(pool)
    .await
    .expect("Failed to create comments table");

    sqlx::query(
        r#"CREATE TABLE IF NOT EXISTS notifications (
            id UUID PRIMARY KEY,
            user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            actor_id UUID REFERENCES users(id) ON DELETE SET NULL,
            type VARCHAR(50) NOT NULL,
            entity_type VARCHAR(50) NOT NULL DEFAULT '',
            entity_id UUID,
            content TEXT NOT NULL DEFAULT '',
            is_read BOOLEAN NOT NULL DEFAULT FALSE,
            created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
        )"#,
    )
    .execute(pool)
    .await
    .expect("Failed to create notifications table");
}

pub async fn list_tracks(pool: &PgPool) -> Result<Vec<Track>, sqlx::Error> {
    sqlx::query_as::<_, Track>("SELECT * FROM tracks ORDER BY uploaded_at DESC")
        .fetch_all(pool)
        .await
}

pub async fn get_track(pool: &PgPool, id: Uuid) -> Result<Track, sqlx::Error> {
    sqlx::query_as::<_, Track>("SELECT * FROM tracks WHERE id = $1")
        .bind(id)
        .fetch_one(pool)
        .await
}

pub async fn create_track(pool: &PgPool, track: &Track) -> Result<Track, sqlx::Error> {
    sqlx::query_as::<_, Track>(
        r#"INSERT INTO tracks (id, title, artist, filename, filepath, uploaded_at)
        VALUES ($1, $2, $3, $4, $5, $6) RETURNING *"#,
    )
    .bind(track.id)
    .bind(&track.title)
    .bind(&track.artist)
    .bind(&track.filename)
    .bind(&track.filepath)
    .bind(track.uploaded_at)
    .fetch_one(pool)
    .await
}

