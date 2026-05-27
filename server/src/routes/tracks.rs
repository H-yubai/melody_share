use axum::{routing::get, Router};
use sqlx::PgPool;

use crate::handlers::tracks;

pub fn tracks_router() -> Router<PgPool> {
    Router::new()
        .route("/", get(index))
        .route("/api/tracks", get(tracks::list))
        .route("/api/tracks/{id}", get(tracks::get_one))
        .route("/api/upload", axum::routing::post(tracks::upload))
}

async fn index() -> &'static str {
    "MelodyShare API"
}
