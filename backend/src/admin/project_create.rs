use crate::{bytes_to_img_format, entities, pic_info, state};
use axum::{
    extract::{multipart, Multipart, State},
    http::StatusCode,
    response::{IntoResponse, Response},
    Json,
};
use chrono::Datelike;
use entities::projects;
use futures::future::{self, join_all};
use pic_info::{GeoData, PicInfo, PicInfoError};
use sea_orm::{ActiveModelTrait, DbErr};
use serde::{Deserialize, Serialize};
use state::AppState;
use tokio::{fs::OpenOptions, io::AsyncWriteExt, task::JoinError};
use uuid::Uuid;

#[derive(thiserror::Error, Debug)]
pub enum CreateProjectError {
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

    #[error(
        "Error parsing metadata of one of the pictures, perhaps it is not a picture?| Error: {0}"
    )]
    PicParseError(#[from] PicInfoError),

    #[error("Invalid image format")]
    InvalidImageFormat,

    #[error("Db error: {0}")]
    DbError(#[from] DbErr),

    #[error("Unable to join worker")]
    JoinError(#[from] JoinError),
}

impl IntoResponse for CreateProjectError {
    fn into_response(self) -> Response {
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            match self {
                Self::MultipartError(err) => format!("This one {err:?}"),
                _ => format!("There was a problem: {}", self),
            },
        )
            .into_response()
    }
}

#[derive(Deserialize, Serialize, Default)]
pub struct CreateProjectResponse {
    id: i32,
    year: i32,
    country: String,
    latitude: f64,
    longitude: f64,
}

#[derive(Deserialize, Debug)]
pub struct CreateProjectRequest {
    pub name: String,
    pub description: String,
    /* will attempt to infer from a picture, or return an error if unable to do so */
    pub year: Option<i32>,
    pub geo_data: Option<GeoData>,
}

pub async fn create(
    State(state): State<AppState>,
    mut req: Multipart,
) -> Result<(StatusCode, Json<CreateProjectResponse>), CreateProjectError> {
    let mut project_info: Option<CreateProjectRequest> = None;
    let mut file_workers = vec![];

    while let Some(field) = req.next_field().await? {
        let field_name = field
            .name()
            .ok_or(CreateProjectError::NoFieldName)?
            .to_string();

        if field_name == "json" {
            assert!(project_info.is_none());
            let bytes = field.bytes().await?;
            project_info = Some(serde_json::from_slice(&bytes)?);
        } else {
            let bytes = field.bytes().await.unwrap();
            file_workers.push(tokio::spawn(async move {
                let pic_info = PicInfo::from_bytes(bytes.clone()).await?;
                let file_format = format!(
                    "{}_{field_name}.{}",
                    Uuid::new_v4(),
                    bytes_to_img_format(&bytes).ok_or(CreateProjectError::InvalidImageFormat)?
                );
                Ok::<_, CreateProjectError>((pic_info, file_format, bytes))
            }));
        }
    }

    let file_workers = join_all(file_workers).await;

    let mut file_info = Vec::with_capacity(file_workers.len());
    let mut files = Vec::with_capacity(file_workers.len());
    for r in file_workers {
        let (pic_info, file_name, bytes) = r??;
        file_info.push(pic_info);
        files.push((file_name, bytes));
    }

    let project_info = project_info.ok_or(CreateProjectError::NoJsonPart)?;

    let geo_data = match project_info.geo_data {
        Some(geo_data) => geo_data,
        None => match file_info
            .iter()
            .find_map(|pic_info| pic_info.geo_data.clone())
        {
            Some(geo_data) => geo_data,
            None => return Err(CreateProjectError::MissingInformation("GeoData".into())),
        },
    };

    let year = match project_info.year {
        Some(year) => year,
        None => match file_info.iter().find_map(|pic_info| pic_info.date_time) {
            Some(date_time) => date_time.year(),
            None => {
                return Err(CreateProjectError::MissingInformation(
                    "DateTime(year)".into(),
                ))
            }
        },
    };

    let mut file_names = Vec::with_capacity(files.len());
    for (name, bytes) in files {
        file_names.push(tokio::spawn(async move {
            let mut f = OpenOptions::new()
                .create(true)
                .write(true)
                .open(format!("storage/{}", name))
                .await
                .unwrap();

            f.write(&bytes).await.unwrap();
            name
        }));
    }
    let file_names = future::join_all(file_names).await;

    let mut names = Vec::with_capacity(file_names.len());
    for r in file_names {
        names.push(r.unwrap());
    }

    let res = projects::ActiveModel {
        id: sea_orm::NotSet,
        name: sea_orm::Set(project_info.name),
        description: sea_orm::Set(project_info.description),
        pictures: sea_orm::Set(names),
        year: sea_orm::Set(year),
        country: sea_orm::Set(geo_data.country),
        latitude: sea_orm::Set(geo_data.latitude),
        longitude: sea_orm::Set(geo_data.longitude),
    }
    .insert(&state.db_conn)
    .await?;

    Ok((
        StatusCode::OK,
        Json(CreateProjectResponse {
            id: res.id,
            year: res.year,
            country: res.country,
            latitude: res.latitude,
            longitude: res.longitude,
        }),
    ))
}
