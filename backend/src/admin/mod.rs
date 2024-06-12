use axum::{middleware, response::IntoResponse, routing};
use serde::{Deserialize, Serialize};

use crate::{common, state::AppState};

mod auth;
mod register;
mod visitor;
mod verify;
mod project_create;
mod project_update;
mod project_delete;

pub use auth::auth;

#[derive(Serialize, Deserialize)]
pub struct JwtClaims {
    exp: usize,
}

pub fn api_router() -> axum::Router<AppState> {
    axum::Router::new()
        .route("/register-admin", routing::post(register::new_admin))
        .route("/visitor", routing::post(visitor::create))
        .route("/projects", routing::post(project_create::create))
        .route("/projects/:id", routing::patch(project_update::update))
        .route("/projects/:id", routing::delete(project_delete::delete))
        .nest("/", common::get_router())
        .layer(middleware::from_fn(verify::is_admin))
}

pub async fn page() -> impl IntoResponse {
    todo!("Return admin frontend(html)")
}
