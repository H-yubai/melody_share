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
