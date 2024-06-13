use crate::{entities::projects, state::AppState};
use axum::{
    body::Body, extract::{Query, State}, http::{Request, StatusCode}, middleware::{self, Next}, response::IntoResponse, routing, Json
};
use sea_orm::{ColumnTrait, EntityTrait, QueryFilter, QueryOrder, QuerySelect};
use serde::{Deserialize, Serialize};
use serde_json::json;
use tower_http::services::ServeDir;

const ALLOWED_FILE_EXT: [&'static str; 7] = [
    "jpg",
    "jpeg",
    "png",
    "heic",
    "html",
    "css",
    "js"
];

async fn filter_file_ext(req: Request<Body>, next: Next) -> impl IntoResponse {
    let req_path = req.uri().path();
    let is_allowed = ALLOWED_FILE_EXT.iter().any(|ext| req_path.ends_with(ext));
    if is_allowed {
        next.run(req).await
    } else {
        (
            StatusCode::UNSUPPORTED_MEDIA_TYPE, 
            Json(json!({"allowed_ext": ALLOWED_FILE_EXT}))
        )
            .into_response()
    }
}

#[derive(Deserialize)]
struct ProjectsQuery {
    pub country: Option<String>,
    pub year: Option<u64>,
}

#[derive(Serialize)]
struct ProjectsResponse {
    projects: Vec<projects::Model>,
}

async fn list_projects(State(state): State<AppState>, Query(query): Query<ProjectsQuery>) -> impl IntoResponse {
    let db_query = if let Some(year) = query.year {
        projects::Entity::find()
            .filter(projects::Column::Year.eq(year))
    } else {
        projects::Entity::find()
    };

    let db_query = if let Some(country) = query.country {
        db_query.filter(projects::Column::Country.eq(country))
    } else {
        db_query
    };

    let projects = db_query
        .order_by_desc(projects::Column::Year)
        .all(&state.db_conn)
        .await
        .unwrap();

    Json(ProjectsResponse { projects })
}

#[derive(Deserialize)]
struct YearsQuery {
    pub country: Option<String>,
}

#[derive(Serialize)]
struct YearsResponse {
    pub years: Vec<i32>,
}

async fn list_years(
    State(state): State<AppState>,
    Query(q): Query<YearsQuery>,
) -> impl IntoResponse {
    let db_query = if let Some(country) = q.country {
        projects::Entity::find().filter(projects::Column::Country.eq(&country))
    } else {
        projects::Entity::find()
    };

    let years: Vec<i32> = db_query
        .select_only()
        .column(projects::Column::Year)
        .order_by_desc(projects::Column::Year)
        .distinct()
        .into_tuple()
        .all(&state.db_conn)
        .await
        .unwrap();

    Json(YearsResponse { years })
}

#[derive(Deserialize)]
struct CountriesQuery {
    pub year: Option<u64>,
}

#[derive(Serialize)]
struct CountriesResponse {
    pub countries: Vec<String>,
}

async fn list_countries(
    State(state): State<AppState>,
    Query(q): Query<CountriesQuery>,
) -> impl IntoResponse {
    let db_query = if let Some(year) = q.year {
        projects::Entity::find().filter(projects::Column::Year.eq(year))
    } else {
        projects::Entity::find()
    };

    let countries: Vec<String> = db_query
        .select_only()
        .column(projects::Column::Country)
        .order_by_asc(projects::Column::Country) /* alphabetically */
        .distinct()
        .into_tuple()
        .all(&state.db_conn)
        .await
        .unwrap();

    Json(CountriesResponse { countries })
}

/// NOTE: verification should be done on higher level
pub fn get_router() -> axum::Router<AppState> {
    let static_router = axum::Router::new()
        .nest_service("/", ServeDir::new("storage"))
        .layer(middleware::from_fn(filter_file_ext));

    axum::Router::new()
        .route("/", routing::get(list_projects))
        .route("/years", routing::get(list_years))
        .route("/countries", routing::get(list_countries))
        .nest("/storage", static_router)
}
