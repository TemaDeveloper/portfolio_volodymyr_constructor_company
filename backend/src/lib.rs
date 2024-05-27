use axum::{http::Method, routing::post, Router, Extension};
use tower_http::cors::{Any, CorsLayer};
use state::AppState;

pub mod admin {
    pub mod auth;
}

pub mod entities;
pub mod state;
mod visitor;

pub async fn create_routes() -> anyhow::Result<Router> {
    let state = AppState::init().await?;

    let cors = CorsLayer::new()
        .allow_methods([Method::GET, Method::POST])
        .allow_origin(Any);

    let db_conn = state.db_conn.clone();
    let state_clone = state.clone();

    Ok(Router::new()
        .route("/auth", post(admin::auth::login))
        .route("/api/create-visitor", post(visitor::create))
        .nest("/:visitor_uuid", visitor::get_visitor_router())
        .with_state(state)
        .layer(Extension(db_conn))
        .with_state(state_clone)
        .layer(cors))
}
