use axum::http::Method;
use axum::routing::post;
use axum::{routing::get, Router};
use state::AppState;
use tower_http::cors::{Any, CorsLayer};

mod visitor;
pub mod entities;
pub mod state;

pub async fn create_routes() -> anyhow::Result<Router> {
    let state = AppState::init()
        .await?;

    let cors = CorsLayer::new()
        .allow_methods([Method::GET, Method::POST])
        .allow_origin(Any);

    Ok(Router::new()
        .route("/auth", get(|| async { "Auth User!" }))
        .route("/api/create-visitor", post(visitor::create))
        .nest("/:visitor_uuid", visitor::get_visitor_router())
        .with_state(state)
        .layer(cors))
}
