use axum::{extract::{Query, State}, response::IntoResponse, routing};
use sea_orm::{ColumnTrait, EntityTrait, QueryFilter, QuerySelect};
use serde::{Deserialize, Serialize};
use crate::{entities::projects, state::AppState};



#[derive(Deserialize)]
struct ProjectsQuery {
    pub country: Option<String>,
    pub year: Option<u64>
}

#[derive(Serialize)]
struct ProjectsResponse {

}

async fn projects(Query(query): Query<ProjectsQuery>) -> impl IntoResponse {

}



#[derive(Deserialize)]
struct YearsQuery {
    pub country: Option<String>
}

#[derive(Serialize)]
struct YearsResponse {
    pub years: Vec<u32>
}

async fn list_years() -> impl IntoResponse {

}



#[derive(Deserialize)]
struct CountriesQuery {
    pub year: Option<u64>
}

#[derive(Serialize)]
struct CountriesResponse {
    pub countries: Vec<String>
}

async fn list_countries(State(state): State<AppState>, Query(q): Query<CountriesQuery>) -> impl IntoResponse {
    let db_query = projects::Entity::find() 
        .select_only()
        .column(projects::Column::Country);

    let db_query = if let Some(year) = q.year {
        db_query.filter(projects::Column::Year.eq(year))
    } else {
        db_query
    };

    let countries = db_query
        .all(&state.db_conn)
        .await?;

    todo!()
}

/// NOTE: verification should be done on higher level
pub async fn get_router() -> axum::Router<AppState> {
    axum::Router::new()
        .route("/project", routing::get(projects))
        .route("/list-years", routing::get(list_years))
        .route("/list-countries", routing::get(list_countries))
}
