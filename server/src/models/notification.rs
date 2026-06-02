use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct Notification {
    pub id: Uuid,
    pub user_id: Uuid,
    pub actor_id: Option<Uuid>,
    pub r#type: String,
    pub entity_type: String,
    pub entity_id: Option<Uuid>,
    pub content: String,
    pub is_read: bool,
    pub created_at: DateTime<Utc>,
}
