use axum::extract::{multipart, DefaultBodyLimit, Multipart, Path, State};
use axum::http::{Method, StatusCode};
use axum::response::{IntoResponse, Response};
use axum::routing::post;
use axum::Json;
use axum::{Router};
use chrono::Datelike;
use entities::projects;
use futures::future::{self, join_all};
use pic_info::{GeoData, PicInfo, PicInfoError};
use sea_orm::{EntityTrait, ActiveModelTrait, DbErr};
use serde::{Deserialize, Serialize};
use state::AppState;
use tokio::fs::{OpenOptions};
use tokio::io::AsyncWriteExt;
use tokio::task::JoinError;
use tower_http::cors::{Any, CorsLayer};
use tower_http::limit::RequestBodyLimitLayer;
use uuid::Uuid;
use tokio::fs;


pub mod admin {
    pub mod auth;
}
pub mod entities;
mod pic_info;
pub mod state;
mod visitor;

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

    #[error("Error parsing metadata of one of the pictures, perhaps it is not a picture?| Error: {0}")]
    PicParseError(#[from] PicInfoError),

    #[error("Invalid image format")]
    InvalidImageFormat,

    #[error("Db error: {0}")]
    DbError(#[from] DbErr),

    #[error("Unable to join worker")]
    JoinError(#[from] JoinError),
}

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

    #[error("Error parsing metadata of one of the pictures, perhaps it is not a picture?| Error: {0}")]
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
                _ => format!("There was a problem: {}", self)
            }
        )
            .into_response()
    }
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



pub fn bytes_to_img_format(bytes: &[u8]) -> Option<&'static str> {
    match bytes {
        [0x89, b'P', b'N', b'G', 0x0D, 0x0A, 0x1A, 0x0A, ..] => Some("png"),
        [0xFF, 0xD8, 0xFF, ..] => Some("jpeg"),
        [b'R', b'I', b'F', b'F', _, _, _, _, b'W', b'E', b'B', b'P', ..] => Some("webp"),
        _ => None,
    }
}

pub async fn create_project(
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
                    bytes_to_img_format(&bytes)
                        .ok_or(CreateProjectError::InvalidImageFormat)?
                );
                Ok::<_, CreateProjectError>((pic_info, file_format, bytes))
            }));
        }
    }

    tracing::warn!("Number of file workers: {}", file_workers.len());

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

#[derive(Deserialize, Serialize, Default)]
pub struct UpdateProjectResponse {
    id: i32,
    year: i32,
    country: String,
    latitude: f64,
    longitude: f64,
}

#[derive(Deserialize, Debug)]
pub struct UpdateProjectRequest {
    pub name: Option<String>,
    pub description: Option<String>,
    pub year: Option<i32>,
    pub country: Option<String>,
    pub latitude: Option<f64>,
    pub longitude: Option<f64>,
}

pub async fn update_project(
    Path(project_id): Path<i32>,
    State(state): State<AppState>,
    mut req: Multipart,
) -> Result<(StatusCode, Json<UpdateProjectResponse>), UpdateProjectError> {
    let mut project_info: Option<UpdateProjectRequest> = None;
    let mut file_workers = vec![];

    while let Some(field) = req.next_field().await? {
        let field_name = field
            .name()
            .ok_or(UpdateProjectError::NoFieldName)?
            .to_string();

        if field_name == "json" {
            assert!(project_info.is_none());
            let bytes = field.bytes().await?;
            project_info = Some(serde_json::from_slice(&bytes)?);
        } else {
            let bytes = field.bytes().await?;
            file_workers.push(tokio::spawn(async move {
                let pic_info = PicInfo::from_bytes(bytes.clone()).await?;
                let file_format = format!(
                    "{}_{field_name}.{}",
                    Uuid::new_v4(),
                    bytes_to_img_format(&bytes).ok_or(UpdateProjectError::InvalidImageFormat)?
                );
                Ok::<_, UpdateProjectError>((pic_info, file_format, bytes))
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

    let project_info = project_info.ok_or(UpdateProjectError::NoJsonPart)?;

    let existing_project = projects::Entity::find_by_id(project_id)
        .one(&state.db_conn)
        .await?
        .ok_or(UpdateProjectError::DbError(DbErr::RecordNotFound(format!("Project with id {} not found", project_id))))?;

    // Delete previous images
    for file_name in &existing_project.pictures {
        let path = format!("assets/storage/{}", file_name);
        if let Err(e) = fs::remove_file(&path).await {
            eprintln!("Failed to delete file {}: {:?}", path, e);
        }
    }

    let country = project_info.country.clone().unwrap_or_else(|| existing_project.country.clone());
    let latitude = project_info.latitude.unwrap_or(existing_project.latitude);
    let longitude = project_info.longitude.unwrap_or(existing_project.longitude);
    let year = project_info.year.unwrap_or(existing_project.year);

    let mut file_names = Vec::with_capacity(files.len());
    for (name, bytes) in files {
        file_names.push(tokio::spawn(async move {
            let mut f = OpenOptions::new()
                .create(true)
                .write(true)
                .open(format!("assets/storage/{}", name))
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

    let mut project: projects::ActiveModel = existing_project.into();

    if let Some(name) = project_info.name {
        project.name = sea_orm::Set(name);
    }
    if let Some(description) = project_info.description {
        project.description = sea_orm::Set(description);
    }
    // Clear previous file names from the database
    project.pictures = sea_orm::Set(Vec::new());
    // Set new file names if there are any
    if !names.is_empty() {
        project.pictures = sea_orm::Set(names);
    }
    project.year = sea_orm::Set(year);
    project.country = sea_orm::Set(country);
    project.latitude = sea_orm::Set(latitude);
    project.longitude = sea_orm::Set(longitude);

    let res = project.update(&state.db_conn).await?;

    Ok((
        StatusCode::OK,
        Json(UpdateProjectResponse {
            id: res.id,
            year: res.year,
            country: res.country,
            latitude: res.latitude,
            longitude: res.longitude,
        }),
    ))
}

pub async fn create_routes() -> anyhow::Result<Router> {
    let state = AppState::init().await?;

    let cors = CorsLayer::new()
        .allow_methods([Method::GET, Method::POST])
        .allow_origin(Any);

    Ok(Router::new()
        .route("/auth", post(admin::auth::login))
        .route("/add-user", post(admin::auth::add_user))
        .route("/api/update-project/:project_id", post(update_project))
        .route("/api/create-visitor", post(visitor::create))
        .route("/api/projects", post(create_project))

        .nest("/:visitor_uuid", visitor::get_visitor_router(state.clone()))

        .with_state(state)
        .layer(cors)
        .layer(DefaultBodyLimit::max(100 * 1024 * 1024))
        .layer(RequestBodyLimitLayer::new(100 * 1024 * 1024))
    )

}
