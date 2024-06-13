use axum::{
    extract::{multipart::MultipartError, Multipart}, response::IntoResponse, Json,
    http::StatusCode
};
use futures::future::join_all;
use serde::Serialize;
use thiserror::Error;
use uuid::Uuid;
use crate::admin::projects::util;

#[derive(Serialize)]
pub struct UploadResponse {
    file_ids: Vec<String>,
}

#[derive(Error, Debug)]
pub enum UploadError {
    #[error("{0}")]
    MultipartError(#[from] MultipartError),

    #[error("Unknown file extension")]
    UnknownExtension,

    #[error("{0}")]
    ErrorSavingFile(#[from] util::SaveError)
}

impl IntoResponse for UploadError {
    fn into_response(self) -> axum::response::Response {
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            self.to_string()
        )
            .into_response()
    }
}

pub async fn pictures(mut req: Multipart) -> Result<Json<UploadResponse>, UploadError> {
    let mut file_names = vec![];
    let mut file_workers = vec![];

    while let Some(field) = req.next_field().await? {
        let field_name = field.file_name().unwrap_or("").to_string();
        let bytes = field.bytes().await?;
        let file_name = format!(
            "{}_{field_name}.{}",
            Uuid::new_v4().to_string(),
            util::bytes_to_pic_ext(&bytes).ok_or(UploadError::UnknownExtension)?
        );

        file_names.push(file_name.clone());
        file_workers.push(util::save_bytes(bytes, file_name))
    }
    
    for r in join_all(file_workers).await {
        if let Err(e) = r {
            util::delete_all(file_names).await;
            return Err(UploadError::ErrorSavingFile(e));
        }
    }
    
    Ok(Json(UploadResponse { file_ids: file_names }))
}


pub async fn videos(mut req: Multipart) -> Result<Json<UploadResponse>, UploadError> {
    let mut file_names = vec![];
    let mut file_workers = vec![];

    while let Some(field) = req.next_field().await? {
        let field_name = field.file_name().unwrap_or("").to_string();
        let bytes = field.bytes().await?;
        let file_name = format!(
            "{}_{field_name}.{}",
            Uuid::new_v4().to_string(),
            util::bytes_to_video_ext(&bytes).ok_or(UploadError::UnknownExtension)?
        );

        file_names.push(file_name.clone());
        file_workers.push(util::save_bytes(bytes, file_name))
    }
    
    for r in join_all(file_workers).await {
        if let Err(e) = r {
            util::delete_all(file_names).await;
            return Err(UploadError::ErrorSavingFile(e));
        }
    }
    
    Ok(Json(UploadResponse { file_ids: file_names }))
}
