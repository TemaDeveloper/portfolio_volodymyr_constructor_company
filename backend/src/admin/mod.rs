use axum::{middleware, routing};
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

pub fn page_router(state: AppState) -> axum::Router<AppState> {
    axum::Router::new()
        .nest_service("/", ServeDir::new(state.admin_dir.as_ref()))
}
