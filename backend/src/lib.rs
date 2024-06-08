use axum::{extract::DefaultBodyLimit, routing, Router};
use state::AppState;
use tower_http::{cors::{self, CorsLayer}, limit::RequestBodyLimitLayer};

pub mod admin;
pub mod entities;
pub mod state;
pub mod common;

mod pic_info;
mod visitor;

pub fn bytes_to_img_format(bytes: &[u8]) -> Option<&'static str> {
    match bytes {
        [0x89, b'P', b'N', b'G', 0x0D, 0x0A, 0x1A, 0x0A, ..] => Some("png"),
        [0xFF, 0xD8, 0xFF, ..] => Some("jpeg"),
        [b'R', b'I', b'F', b'F', _, _, _, _, b'W', b'E', b'B', b'P', ..] => Some("webp"),
        _ => None,
    }
}

pub async fn create_routes() -> anyhow::Result<Router> {
    let state = AppState::init().await?;

    Ok(Router::new()
        .nest("/admin", Router::new()
            .route("/", routing::get(admin::page)) /* get actuall html for admin page */
            .route("/auth", routing::post(admin::auth)) /* auth endpoint */
            .nest("/api", admin::api_router())) /* everything that needs verification */

        .nest("/visitor", Router::new()
            .route("/:visitor_uuid", routing::get(visitor::page))
            .nest("/api", visitor::api_router(state.clone())))

        .with_state(state)
        .layer(CorsLayer::permissive())
        .layer(DefaultBodyLimit::max(100 * 1024 * 1024)) // 100mb
        .layer(RequestBodyLimitLayer::new(100 * 1024 * 1024))
    )

}
