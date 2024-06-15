use axum::{extract::DefaultBodyLimit, routing, Router};
use state::AppState;
use tower_http::{cors::CorsLayer, limit::RequestBodyLimitLayer};

pub mod admin;
pub mod entities;
pub mod state;
pub mod common;

mod visitor;


pub async fn create_routes() -> anyhow::Result<Router> {
    let state = AppState::init().await?;

    Ok(Router::new()
        .nest("/admin", Router::new()
            .nest("/", admin::page_router()) /* get actuall html for admin page */
            .nest("/api", admin::api_router()) /* everything that needs verification */
            .route("/auth", routing::post(admin::auth))) /* auth endpoint */

        .nest("/visitor", Router::new()
            .route("/:visitor_uuid", routing::get(visitor::page))
            .nest_service("/static", visitor::static_router())
            .nest("/api", visitor::api_router(state.clone())))

        .with_state(state)
        .layer(CorsLayer::permissive())
        .layer(DefaultBodyLimit::max(100 * 1024 * 1024)) // 100mb
        .layer(RequestBodyLimitLayer::new(100 * 1024 * 1024))
    )

}
