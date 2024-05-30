use askama::Template;
use askama_axum::IntoResponse;
use axum::{
    extract::{Query, State},
    http::StatusCode,
    middleware, routing, Router,
};
use sea_orm::{
    ColumnTrait, DbErr, EntityTrait, QueryFilter, QuerySelect,
};
use serde::Deserialize;
use tower_http::services::ServeDir;

use crate::{
    entities::projects,
    state::AppState,
};

use super::filter_extension;

#[derive(Template)]
#[template(path = "projects/projects.html")]
struct ProjectsPage {
    year: i32,
    countries: Vec<String>,
    initial_projects: ProjectsListTemplate,
}

#[derive(Template)]
#[template(path = "projects/project_list.html")]
struct ProjectsListTemplate {
    projects: Vec<projects::Model>,
}

#[derive(thiserror::Error, Debug)]
enum ProjectsError {
    #[error("Db Error: {0}")]
    DbError(#[from] DbErr),
}

#[derive(Deserialize)]
struct QueryParams {
    year: i32,
}

#[derive(Deserialize)]
struct ProjectListQuery {
    year: i32,
    country: String
}

impl IntoResponse for ProjectsError {
    fn into_response(self) -> askama_axum::Response {
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            format!("Error: {}", self),
        )
            .into_response()
    }
}

async fn projects_page(
    Query(QueryParams { year }): Query<QueryParams>,
    State(state): State<AppState>,
) -> Result<ProjectsPage, ProjectsError> {
    let countries: Vec<String> = projects::Entity::find()
        .filter(projects::Column::Year.eq(year))
        .select_only()
        .column(projects::Column::Country)
        .distinct()
        .into_tuple()
        .all(&state.db_conn)
        .await?;

    if let Some(first_country) = countries.first() {
        let projects = projects::Entity::find()
            .filter(projects::Column::Country.eq(first_country))
            .filter(projects::Column::Year.eq(year))
            .all(&state.db_conn)
            .await?;
        Ok(ProjectsPage {
            year,
            countries,
            initial_projects: ProjectsListTemplate { projects },
        })
    } else {
        todo!("Make an empty template or something, say they are an idiot for messing with query params")
    }
}

async fn project_by_country(
    Query(ProjectListQuery { year, country }): Query<ProjectListQuery>,
    State(state): State<AppState>,
) -> Result<ProjectsListTemplate, ProjectsError> {
    let projects = projects::Entity::find()
        .filter(projects::Column::Country.eq(&country))
        .filter(projects::Column::Year.eq(year))
        .all(&state.db_conn)
        .await?;

    tracing::warn!("Getting by country: {}", country);

    Ok(ProjectsListTemplate { projects })
}

pub fn get_routes() -> Router<AppState> {
    let static_router = Router::new()
        .nest_service("/", ServeDir::new("../frontend/projects"))
        .route_layer(middleware::from_fn(filter_extension));

    Router::new()
        .route("/", routing::get(projects_page))
        .route("/list", routing::get(project_by_country))
        .nest("/assets", static_router)
}
