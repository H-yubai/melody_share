mod config;
mod db;
mod handlers;
mod models;
mod routes;

use sqlx::PgPool;
use tracing_subscriber::EnvFilter;

use crate::{config::Config, db::init_db, routes::app_routes};

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt()
        .with_env_filter(EnvFilter::from_default_env())
        .init();

    dotenvy::dotenv().ok();
    let config = Config::from_env();

    let pool = PgPool::connect(&config.database_url)
        .await
        .expect("Failed to connect to PostgreSQL");

    init_db(&pool).await;

    let app = app_routes().with_state(pool);

    let addr = format!("{}:{}", config.host, config.port);
    let listener = tokio::net::TcpListener::bind(&addr)
        .await
        .unwrap();
    tracing::info!("Server running on http://{}", addr);
    axum::serve(listener, app).await.unwrap();
}
