use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct Follow {
    pub id: Uuid,
    pub follower_id: Uuid,
    pub followee_id: Uuid,
    pub created_at: DateTime<Utc>,
}
