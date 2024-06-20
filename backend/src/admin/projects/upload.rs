use axum::{
    extract::{multipart::MultipartError, Multipart}, response::IntoResponse, Json,
    http::StatusCode
};
use futures::future::join_all;
use serde::Serialize;
use thiserror::Error;
use uuid::Uuid;
use crate::admin::projects::util;
// use rust_ffmpeg::{decoder::Video, encoder::Video as VideoEncoder, format::Pixel, format::context::{Input, Output}, software::scaling::{context::Context, flag::Flags}};
// use futures::future::join_all;

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
    ErrorSavingFile(#[from] util::SaveError),

    #[error("Invalid file type")]
    InvalidFileType,

    #[error("Failed to convert a file")]
    ConversionFailed
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
        let field_name = field.file_name()
            .unwrap_or("")
            .to_string()
            .replace(" ", "_");
        let bytes = field.bytes().await?;
        let file_name = format!(
            "{}_{field_name}.{}",
            Uuid::new_v4().to_string(),
            util::bytes_to_pic_ext(&bytes).ok_or(UploadError::UnknownExtension)?
        );

        file_workers.push(util::save_bytes(bytes, format!("storage/{file_name}")));
        file_names.push(file_name);
    }
    
    for r in join_all(file_workers).await {
        if let Err(e) = r {
            util::delete_all(file_names).await;
            return Err(UploadError::ErrorSavingFile(e));
        }
    }
    
    Ok(Json(UploadResponse { file_ids: file_names }))
}

use std::process::Command;
use std::fs::remove_file;

pub async fn videos(mut req: Multipart) -> Result<Json<UploadResponse>, UploadError> {
    let mut file_names = vec![];
    let mut file_workers = vec![];

    while let Some(field) = req.next_field().await? {
        let field_name = field.file_name()
            .unwrap_or("")
            .to_string()
            .replace(" ", "_");
        let bytes = field.bytes().await?;

        let ext = util::bytes_to_video_ext(&bytes).ok_or(UploadError::UnknownExtension)?;
        if !["mp4", "mov", "avi", "mkv", "webm"].contains(&ext) {
            return Err(UploadError::InvalidFileType);
        }

        let file_name = format!("{}_{}.mp4", Uuid::new_v4().to_string(), field_name);
        let temp_file_path = format!("storage/temp_{}.{}", Uuid::new_v4().to_string(), ext);
        util::save_bytes(bytes.clone(), temp_file_path.clone()).await?;

        file_workers.push(convert_to_mp4_h264(temp_file_path, format!("storage/{file_name}")));
        file_names.push(file_name);
    }
    
    for r in join_all(file_workers).await {
        if let Err(e) = r {
            util::delete_all(file_names).await;
            return Err(e);
        }
    }
    
    Ok(Json(UploadResponse { file_ids: file_names }))
}

async fn convert_to_mp4_h264(input_path: String, output_path: String) -> Result<(), UploadError> {
    let output = Command::new("ffmpeg")
        .arg("-i")
        .arg(&input_path)
        .arg("-c:v")
        .arg("libx264")
        .arg("-preset")
        .arg("fast")
        .arg("-crf")
        .arg("23")
        .arg("-y")
        .arg(&output_path)
        .output()
        .map_err(|_| UploadError::ConversionFailed)?;

    if !output.status.success() {
        return Err(UploadError::ConversionFailed);
    }

    remove_file(input_path).map_err(|_| UploadError::ConversionFailed)?;

    Ok(())
}
