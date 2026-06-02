use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct Playlist {
    pub id: Uuid,
    pub user_id: Uuid,
    pub title: String,
    pub description: String,
    pub cover_url: String,
    pub is_public: bool,
    pub track_count: i32,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct PlaylistTrack {
    pub id: Uuid,
    pub playlist_id: Uuid,
    pub track_id: Uuid,
    pub sort_order: i32,
    pub added_at: DateTime<Utc>,
}
