use axum::{
    extract::{Multipart, Path, State},
    http::StatusCode,
    response::Json,
};
use sqlx::PgPool;
use uuid::Uuid;

use crate::{db, models::track::Track};

pub async fn list(State(pool): State<PgPool>) -> Result<Json<Vec<Track>>, StatusCode> {
    db::list_tracks(&pool)
        .await
        .map(Json)
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)
}

pub async fn get_one(
    State(pool): State<PgPool>,
    Path(id): Path<Uuid>,
) -> Result<Json<Track>, StatusCode> {
    db::get_track(&pool, id)
        .await
        .map(Json)
        .map_err(|_| StatusCode::NOT_FOUND)
}

pub async fn upload(
    State(pool): State<PgPool>,
    mut multipart: Multipart,
) -> Result<Json<Track>, StatusCode> {
    let mut title = String::new();
    let mut artist = String::new();
    let mut filename = String::new();
    let mut data = Vec::new();

    while let Some(field) = multipart.next_field().await.unwrap() {
        let name = field.name().unwrap_or("").to_string();
        match name.as_str() {
            "title" => title = field.text().await.unwrap_or_default(),
            "artist" => artist = field.text().await.unwrap_or_default(),
            "file" => {
                filename = field.file_name().unwrap_or("unknown").to_string();
                data = field.bytes().await.unwrap_or_default().to_vec();
            }
            _ => {}
        }
    }

    if data.is_empty() {
        return Err(StatusCode::BAD_REQUEST);
    }

    let id = Uuid::new_v4();
    let track = Track {
        id,
        title: if title.is_empty() { filename.clone() } else { title },
        artist,
        filename: filename.clone(),
        filepath: format!("uploads/{}.mp3", id),
        uploaded_at: chrono::Utc::now(),
    };

    let save_dir = std::path::Path::new("uploads");
    tokio::fs::create_dir_all(save_dir)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
    tokio::fs::write(&track.filepath, &data)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    db::create_track(&pool, &track)
        .await
        .map(Json)
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)
}
