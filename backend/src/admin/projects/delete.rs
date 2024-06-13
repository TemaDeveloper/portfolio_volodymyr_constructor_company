use crate::{entities::projects, state::AppState};
use axum::{
    extract::{Path, State},
    http::StatusCode,
    response::IntoResponse,
};
use sea_orm::EntityTrait;

use super::util;

#[derive(thiserror::Error, Debug)]
pub enum DeleteError {
    #[error("Not found")]
    NotFound,

    #[error("Database error: {0}")]
    DbError(#[from] sea_orm::DbErr),

    #[error("No project id({0}) found")]
    NoProjectFound(i32),
}

impl IntoResponse for DeleteError {
    fn into_response(self) -> axum::response::Response {
        match self {
            Self::NotFound => (StatusCode::NOT_FOUND, format!("Error: {}", self)).into_response(),
            _ => (
                StatusCode::INTERNAL_SERVER_ERROR,
                format!("Error: {}", self),
            )
                .into_response(),
        }
    }
}

pub async fn project(
    Path(id): Path<i32>,
    State(state): State<AppState>,
) -> Result<StatusCode, DeleteError> {
    let model = projects::Entity::find_by_id(id)
        .one(&state.db_conn)
        .await?
        .ok_or(DeleteError::NoProjectFound(id))?;

    util::delete_all(model.pictures).await;
    util::delete_all(model.videos).await;

    let x = projects::Entity::delete_by_id(id)
        .exec(&state.db_conn)
        .await?;

    assert!(x.rows_affected != 0);

    Ok(StatusCode::OK)
}

pub async fn file(Path(name): Path<String>) -> Result<StatusCode, DeleteError> {
    tokio::fs::remove_file(format!("storage/{name}"))
        .await
        .map_err(|e| {
            tracing::error!("Error removing file: {e}");
            DeleteError::NotFound
        })
        .map(|_| StatusCode::OK)
}
