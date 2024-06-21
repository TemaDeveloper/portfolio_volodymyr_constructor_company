use axum::body::Bytes;
use chrono::NaiveDateTime;
use reqwest::Client;
use rexiv2::Metadata as Rexiv2Metadata;
use serde::{Deserialize, Serialize};
use thiserror::Error;
use num_traits::cast::ToPrimitive;

#[derive(Error, Debug)]
pub enum PicInfoError {
    #[error("{0}")]
    ParseError(#[from] rexiv2::Rexiv2Error),
    #[error("Failed to fetch country name: {0}")]
    CountryFetchError(String),
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct GeoData {
    pub country: String,
    pub latitude: f64,
    pub longitude: f64,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct PicInfo {
    pub date_time: Option<NaiveDateTime>,
    pub geo_data: Option<GeoData>,
}

async fn fetch_country_name(latitude: f64, longitude: f64) -> Result<String, reqwest::Error> {
    let client = Client::new();
    let url = format!("https://api.bigdatacloud.net/data/reverse-geocode-client?latitude={}&longitude={}&localityLanguage=en", latitude, longitude);
    let response: serde_json::Value = client.get(&url).send().await?.json().await?;

    tracing::info!("Request(latitude: {latitude}, longitude: {longitude})|Api Cord Response: {response}");

    Ok(response["countryName"]
        .as_str()
        .unwrap_or("Unknown")
        .to_string())
}

fn get_meta(metadata: Rexiv2Metadata) ->(Option<NaiveDateTime>, Option<rexiv2::GpsInfo>) {

    let date_time = metadata
        .get_tag_string("Exif.Photo.DateTimeOriginal")
        .ok()
        .and_then(|dt| NaiveDateTime::parse_from_str(&dt, "%Y:%m:%d %H:%M:%S").ok());

    let gps_info = metadata
        .get_gps_info();

    (date_time, gps_info)
}

impl GeoData {
    async fn from_gps_info(
        gps_info: rexiv2::GpsInfo
    ) -> Result<Self, PicInfoError> {
        let country = fetch_country_name(gps_info.latitude, gps_info.longitude)
            .await
            .map_err(|e| PicInfoError::CountryFetchError(e.to_string()))?;
        let country = country.trim().to_owned();
        Ok(Self {
            country,
            latitude: gps_info.latitude,
            longitude: gps_info.longitude,
        })
    }
}

impl PicInfo {
    #[allow(unused)]
    pub async fn from_bytes(bytes: Bytes) -> Result<Self, PicInfoError> {
        // we use separate funciton as borrow checker is not happy when we create
        // Rexiv2Metadata in an async function
        let (date_time, gps_info) = get_meta(Rexiv2Metadata::new_from_buffer(&bytes)?);
        let geo_data = if let Some(gps_info) = gps_info {
            Some(GeoData::from_gps_info(gps_info).await?)
        } else {
            None
        };

        Ok(Self {
            date_time,
            geo_data,
        })
    }

    pub async fn from_file(file_name: &str) -> Result<Self, PicInfoError> {
        let (date_time, gps_info) = get_meta(Rexiv2Metadata::new_from_path(file_name)?);
        let geo_data = if let Some(gps_info) = gps_info {
            Some(GeoData::from_gps_info(gps_info).await?)
        } else {
            None
        };

        Ok(Self {
            date_time,
            geo_data,
        })
    }
}

