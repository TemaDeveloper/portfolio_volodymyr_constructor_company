use crate::{entities, state};
use axum::{
    extract::State,
    http::StatusCode,
    response::{IntoResponse, Response},
    Json,
};
use chrono::Datelike;
use entities::projects;
use sea_orm::{ActiveModelTrait, DbErr};
use serde::{Deserialize, Serialize};
use state::AppState;
use super::{pic_info::{GeoData, PicInfo, PicInfoError}, util};

#[derive(thiserror::Error, Debug)]
pub enum ProjectError {
    #[error("{0}")]
    DeserializeError(#[from] serde_json::Error),

    #[error("One of the fields is missing: {0}")]
    MissingInformation(String),

    #[error(
        "Error parsing metadata of one of the pictures, perhaps it is not a picture?| Error: {0}"
    )]
    PicParseError(#[from] PicInfoError),

    #[error("Db error: {0}")]
    DbError(#[from] DbErr),
}

impl IntoResponse for ProjectError {
    fn into_response(self) -> Response {
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            format!("There was a problem: {}", self),
        )
            .into_response()
    }
}

#[derive(Deserialize, Serialize, Default)]
pub struct ProjectResponse {
    id: i32,
    year: i32,
    country: String,
    pictures: Vec<String>,
    videos: Vec<String>
}

#[derive(Deserialize, Debug)]
pub struct ProjectRequest {
    pub name: String,
    pub description: String,
    #[serde(default)]
    pub pictures: Vec<String>,
    #[serde(default)]
    pub videos: Vec<String>,
    /* will attempt to infer from a picture, or return an error if unable to do so */
    pub year: Option<i32>,
    pub geo_data: Option<GeoData>,
}

pub async fn project(
    State(state): State<AppState>,
    Json(info): Json<ProjectRequest>,
) -> Result<(StatusCode, Json<ProjectResponse>), ProjectError> {
    let PicInfo {
        date_time,
        geo_data,
    } = util::get_meta_for(&info.pictures).await?;

    let year = match info.year {
        Some(year) => year,
        None => match date_time {
            Some(date_time) => date_time.year(),
            None => return Err(ProjectError::MissingInformation("DateTime(year)".into())),
        },
    };

    let geo_data = match info.geo_data {
        Some(geo_data) => geo_data,
        None => match geo_data {
            Some(geo_data) => geo_data,
            None => return Err(ProjectError::MissingInformation("GeoData".into())),
        },
    };

    let res = projects::ActiveModel {
        id: sea_orm::NotSet,
        name: sea_orm::Set(info.name),
        description: sea_orm::Set(info.description),
        pictures: sea_orm::Set(info.pictures),
        videos: sea_orm::Set(info.videos),
        year: sea_orm::Set(year),
        country: sea_orm::Set(geo_data.country),
        latitude: sea_orm::Set(geo_data.latitude),
        longitude: sea_orm::Set(geo_data.longitude),
    }
    .insert(&state.db_conn)
    .await?;

    Ok((
        StatusCode::OK,
        Json(ProjectResponse {
            id: res.id,
            year: res.year,
            country: res.country,
            pictures: res.pictures,
            videos: res.videos,
        }),
    ))
}
