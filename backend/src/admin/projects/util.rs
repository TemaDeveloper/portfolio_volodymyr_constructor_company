use axum::body::Bytes;
use futures::future::join_all;
use thiserror::Error;
use tokio::{
    fs::{remove_file, File},
    io::AsyncWriteExt,
};

use super::pic_info::{PicInfo, PicInfoError};

#[derive(Error, Debug)]
pub enum SaveError {
    #[error("Failed to create file: {0}")]
    CreateFileError(std::io::Error),
    #[error("Failed to write to file: {0}")]
    WriteError(std::io::Error),
}

pub async fn save_bytes(bytes: Bytes, file_name: String) -> Result<(), SaveError> {
    let mut file = File::create(&file_name)
        .await
        .map_err(SaveError::CreateFileError)?;

    file.write_all(&bytes)
        .await
        .map_err(SaveError::WriteError)?;

    Ok(())
}

pub async fn delete_all<I>(file_names: I)
where
    I: IntoIterator<Item = String>,
{
    for file_name in file_names {
        /* it is okay if try remove non existant file */
        let _ = remove_file(format!("storage/{file_name}")).await;
    }
}

pub async fn get_meta_for(file_names: &[String]) -> Result<PicInfo, PicInfoError> {
    let mut info = PicInfo {
        date_time: None,
        geo_data: None,
    };
    let mut file_workers = Vec::with_capacity(file_names.len());

    for f in file_names {
        file_workers.push(
            PicInfo::from_file(&f)
        );
    }
    
    let file_workers = join_all(file_workers).await;

    for m in file_workers {
        let PicInfo { date_time, geo_data } = m?;

        if info.date_time.is_none() {
            info.date_time = date_time;
        }

        if info.geo_data.is_none() {
            info.geo_data = geo_data;
        }
    }

    Ok(info)
}

pub fn bytes_to_pic_ext(bytes: &[u8]) -> Option<&'static str> {
    match bytes {
        [0x89, b'P', b'N', b'G', 0x0D, 0x0A, 0x1A, 0x0A, ..] => Some("png"),
        [0xFF, 0xD8, 0xFF, ..] => Some("jpeg"),
        [b'R', b'I', b'F', b'F', _, _, _, _, b'W', b'E', b'B', b'P', ..] => Some("webp"),
        _ => None,
    }
}

pub fn bytes_to_video_ext(bytes: &[u8]) -> Option<&'static str> {
    match bytes {
        [0x00, 0x00, 0x00, _, b'f', b't', b'y', b'p', ..] => Some("mp4"),
        [0x1A, 0x45, 0xDF, 0xA3, ..] => Some("mkv"),
        [0x47, 0x40, 0x00, 0x10, ..] => Some("ts"),
        [0x52, 0x49, 0x46, 0x46, _, _, _, _, b'A', b'V', b'I', b' '] => Some("avi"),
        _ => None,
    }
}
