use crate::{entities, state};
use axum::{
    extract::{multipart::{self, Multipart}, Path, State},
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
    #[error("{0}")]
    MultipartError(#[from] multipart::MultipartError),

    #[error("{0}")]
    DeserializeError(#[from] serde_json::Error),

    #[error("No field name supplied")]
    NoFieldName,

    #[error("No json field supplied, use `json` as field name")]
    NoJsonPart,

    #[error("One of the fields is missing: {0}")]
    MissingInformation(String),

    #[error("Db error: {0}")]
    DbError(#[from] DbErr),
}

impl IntoResponse for UpdateProjectError {
    fn into_response(self) -> Response {
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            match self {
                Self::MultipartError(_err) => todo!(),
                _ => format!("There was a problem: {}", self)
            }
        )
            .into_response()
    }
}

#[derive(Deserialize, Serialize, Default)]
pub struct UpdateProjectResponse {
    id: i32,
    year: i32,
    country: String,
}

#[derive(Deserialize, Debug)]
pub struct UpdateProjectRequest {
    pub name: Option<String>,
    pub description: Option<String>,
    pub year: Option<i32>,
    pub country: Option<String>,
}

pub async fn update(
    Path(project_id): Path<i32>,
    State(state): State<AppState>,
    mut req: Multipart,
) -> Result<(StatusCode, Json<UpdateProjectResponse>), UpdateProjectError> {
    let mut project_info: Option<UpdateProjectRequest> = None;

    while let Some(field) = req.next_field().await? {
        let field_name = field
            .name()
            .ok_or(UpdateProjectError::NoFieldName)?
            .to_string();

        if field_name == "json" {
            assert!(project_info.is_none());
            let bytes = field.bytes().await?;
            project_info = Some(serde_json::from_slice(&bytes)?);
        }
    }

    let project_info = project_info.ok_or(UpdateProjectError::NoJsonPart)?;

    let existing_project = projects::Entity::find_by_id(project_id)
        .one(&state.db_conn)
        .await?
        .ok_or(UpdateProjectError::DbError(DbErr::RecordNotFound(format!("Project with id {} not found", project_id))))?;

    let mut project: projects::ActiveModel = existing_project.into();

    if let Some(name) = project_info.name {
        project.name = sea_orm::Set(name);
    }
    if let Some(description) = project_info.description {
        project.description = sea_orm::Set(description);
    }
    if let Some(year) = project_info.year {
        project.year = sea_orm::Set(year);
    }
    if let Some(country) = project_info.country {
        project.country = sea_orm::Set(country);
    }

    let res = project.update(&state.db_conn).await?;

    Ok((
        StatusCode::OK,
        Json(UpdateProjectResponse {
            id: res.id,
            year: res.year,
            country: res.country,
        }),
    ))
}
