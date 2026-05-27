use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct Track {
    pub id: Uuid,
    pub title: String,
    pub artist: String,
    pub filename: String,
    pub filepath: String,
    pub uploaded_at: DateTime<Utc>,
}
