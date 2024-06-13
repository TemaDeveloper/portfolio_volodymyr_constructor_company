use crate::{entities, state};
use axum::{
    extract::{Path, State},
    http::StatusCode,
    response::{IntoResponse, Response},
    Json,
};
use entities::projects;
use sea_orm::{ActiveModelTrait, DbErr, EntityTrait};
use serde::{Deserialize, Serialize};
use state::AppState;

#[derive(thiserror::Error, Debug)]
pub enum UpdateProjectError {
    #[error("No project id({0}) found")]
    NoProjectFound(i32),

    #[error("Db error: {0}")]
    DbError(#[from] DbErr),
}

impl IntoResponse for UpdateProjectError {
    fn into_response(self) -> Response {
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            format!("There was a problem: {}", self)
        )
            .into_response()
    }
}

#[derive(Deserialize, Serialize, Default)]
pub struct UpdateProjectResponse {
    id: i32,
}

#[derive(Deserialize, Debug)]
pub struct UpdateProjectRequest {
    pub name: Option<String>,
    pub description: Option<String>,
    pub year: Option<i32>,
    pub country: Option<String>,

    pub pictures: Option<Vec<String>>,
    pub videos: Option<Vec<String>>,
}

pub async fn project(
    State(state): State<AppState>,
    Path(project_id): Path<i32>,
    Json(info): Json<UpdateProjectRequest>
) -> Result<StatusCode, UpdateProjectError> {
    let existing_project = projects::Entity::find_by_id(project_id)
        .one(&state.db_conn)
        .await?
        .ok_or(UpdateProjectError::NoProjectFound(project_id))?;

    let mut project: projects::ActiveModel = existing_project.into();

    if let Some(name) = info.name {
        project.name = sea_orm::Set(name);
    }

    if let Some(description) = info.description {
        project.description = sea_orm::Set(description);
    }

    if let Some(year) = info.year {
        project.year = sea_orm::Set(year);
    }

    if let Some(country) = info.country {
        project.country = sea_orm::Set(country);
    }

    if let Some(pictures) = info.pictures {
        project.pictures = sea_orm::Set(pictures);
    }

    if let Some(videos) = info.videos {
        project.videos = sea_orm::Set(videos);
    }

    let _res = project.update(&state.db_conn).await?;

    Ok(StatusCode::OK)
}
