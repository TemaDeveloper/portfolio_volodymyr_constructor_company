use axum::{middleware, response::{Html, IntoResponse}, routing};
use serde::{Deserialize, Serialize};
use tower_http::services::ServeDir;

use crate::{common, state::AppState};

mod auth;
mod register;
mod visitor;
mod verify;
mod projects;

pub use auth::auth;

#[derive(Serialize, Deserialize)]
pub struct JwtClaims {
    exp: usize,
}

pub fn api_router() -> axum::Router<AppState> {
    axum::Router::new()
        .route("/register-admin", routing::post(register::new_admin))
        .route("/visitor", routing::post(visitor::create))
        .nest("/projects", projects::get_router()) /* admin routes */
        .nest("/projects", common::get_router())
        .layer(middleware::from_fn(verify::is_admin))
}

// async fn page() -> Html<String> {
//     Html::from(include_str!("../../../frontend_admin/build/web/index.html").to_string())
// }

pub fn page_router() -> axum::Router<AppState> {
    axum::Router::new()
        .nest_service("/", ServeDir::new("../frontend_admin/build/web"))
}
