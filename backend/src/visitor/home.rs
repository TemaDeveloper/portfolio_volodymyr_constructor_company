use std::env;

use askama_axum::Template;
use axum::{extract::State, http::StatusCode, middleware, response::IntoResponse, routing, Router};
use sea_orm::{DbErr, EntityTrait, QueryOrder, QuerySelect};
use tower_http::services::ServeDir;

use crate::{entities::projects, state::AppState};

use super::filter_extension;

#[derive(Template, Default)]
#[template(path = "home/index.html")]
pub struct HomeTemplate {
    years: Vec<i32>,

    first_name: String,
    last_name: String,
    email: String,
}

#[derive(thiserror::Error, Debug)]
pub enum HomeError {
    #[error("Database error: {0}")]
    DbError(#[from] DbErr),
}

impl IntoResponse for HomeError {
    fn into_response(self) -> axum::response::Response {
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            format!("Error: {}", self),
        )
            .into_response()
    }
}

async fn home(State(state): State<AppState>) -> Result<HomeTemplate, HomeError> {
    let years: Vec<i32> = projects::Entity::find()
        .select_only()
        .column(projects::Column::Year)
        .distinct()
        .order_by_asc(projects::Column::Year)
        .into_values::<_, projects::Column>()
        .all(&state.db_conn)
        .await?;

    let template = HomeTemplate {
        first_name: env::var("OWNER_FIRST_NAME").expect("You have set up server wrong, ooops!!!"),
        last_name: env::var("OWNER_LAST_NAME").expect("You have set up server wrong, ooops!!!"),
        email: env::var("OWNER_EMAIL").expect("You have set up server wrong, ooops!!!"),
        years,
    };

    Ok(template)
}

pub fn get_routes() -> Router<AppState> {
    let static_router = Router::new()
        .nest_service("/", ServeDir::new("../frontend/home"))
        .route_layer(middleware::from_fn(filter_extension));

    Router::new()
        .route("/", routing::get(home))
        .nest("/assets", static_router)
}
