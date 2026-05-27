pub mod tracks;

use axum::Router;
use sqlx::PgPool;
use tower_http::cors::CorsLayer;

pub fn app_routes() -> Router<PgPool> {
    Router::new()
        .merge(tracks::tracks_router())
        .layer(CorsLayer::permissive())
}
