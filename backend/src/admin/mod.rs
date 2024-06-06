use axum::{middleware, response::IntoResponse, routing};
use serde::{Deserialize, Serialize};

use crate::{common, state::AppState};

mod auth;
mod register;
mod visitor;
mod verify;
mod project_create;
mod project_update;

pub use auth::auth;

#[derive(Serialize, Deserialize)]
pub struct JwtClaims {
    exp: usize,
}

pub fn api_router() -> axum::Router<AppState> {
    axum::Router::new()
        .route("/register-admin", routing::post(register::new_admin))
        .route("/visitor", routing::post(visitor::create))
        .route("/project", routing::post(project_create::create))
        .route("/project", routing::patch(project_update::update))
        .nest("/", common::get_router())
        .layer(middleware::from_fn(verify::is_admin))
}

pub async fn page() -> impl IntoResponse {

}
