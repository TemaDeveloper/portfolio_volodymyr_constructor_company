use axum::{body::Body, http::{Request, StatusCode}, middleware::{self, Next}, response::IntoResponse, routing, Router};
use tower_http::services::ServeDir;

pub mod validate;
mod create;
mod home;
mod projects;

pub use create::create;
use crate::state::AppState;

use self::validate::ValidVisitorUuid;

const ALLOWED_EXTENSIONS: [&'static str; 5] = [
    ".css",
    ".js",
    ".jpg",
    ".jpeg",
    ".png"
];

async fn filter_extension(req: Request<Body>, next: Next) -> impl axum::response::IntoResponse {
    let path = req.uri().path();

    let is_allowed_ext = ALLOWED_EXTENSIONS.iter()
        .any(|ext| path.ends_with(ext));

    if is_allowed_ext {
        next.run(req).await
    } else {
        StatusCode::FORBIDDEN.into_response()
    }
}

// NOTE: it is VERY VERY important that when `appending`
// this route you do .nest("/:visitor_uuid", ...)
// instead of anything else
pub fn get_visitor_router(state: AppState) -> Router<AppState> {
    let static_router = Router::new()
        .nest_service("/", ServeDir::new("./storage"))
        .route_layer(middleware::from_fn(filter_extension));

    Router::new()
        .nest("/home", home::get_routes())
        .nest("/projects", projects::get_routes())
        .nest("/storage", static_router)
        .route_layer(middleware::from_extractor_with_state::<ValidVisitorUuid, _>(state))
}
