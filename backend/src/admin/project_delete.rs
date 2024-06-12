use axum::{
    extract::{Path, State},
    http::StatusCode,
    response::IntoResponse,
};
use sea_orm::{EntityTrait, Set};
use crate::{entities::projects, state::AppState};

#[derive(thiserror::Error, Debug)]
pub enum DeleteProjectError {
    #[error("Project not found")]
    NotFound,
    
    #[error("Database error: {0}")]
    DbError(#[from] sea_orm::DbErr),
}

impl IntoResponse for DeleteProjectError {
    fn into_response(self) -> axum::response::Response {
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            match self {
                Self::NotFound => "Project not found".to_string(),
                Self::DbError(err) => format!("Database error: {}", err),
            },
        )
            .into_response()
    }
}

pub async fn delete(
    Path(project_id): Path<i32>,
    State(state): State<AppState>,
) -> Result<StatusCode, DeleteProjectError> {
    let result = projects::Entity::delete_by_id(project_id)
        .exec(&state.db_conn)
        .await?;

    if result.rows_affected == 0 {
        return Err(DeleteProjectError::NotFound);
    }

    Ok(StatusCode::NO_CONTENT)
}
