use axum::body::Bytes;
use chrono::NaiveDateTime;
use reqwest::Client;
use rexiv2::Metadata as Rexiv2Metadata;
use serde::{Deserialize, Serialize};
use thiserror::Error;

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

fn parse_gps_coordinate(gps_str: &str, direction: &str) -> f64 {
    let parts: Vec<f64> = gps_str
        .split(',')
        .filter_map(|s| {
            let fraction: Vec<&str> = s.trim().split('/').collect();
            if fraction.len() == 2 {
                if let (Ok(num), Ok(den)) = (fraction[0].parse::<f64>(), fraction[1].parse::<f64>()) {
                    Some(num / den)
                } else {
                    None
                }
            } else {
                None
            }
        })
        .collect();

    if parts.is_empty() {
        panic!("Failed to parse GPS coordinates: {}", gps_str);
    }

    let mut coordinate = parts[0];
    if parts.len() > 1 {
        coordinate += parts[1] / 60.0;
    }
    if parts.len() > 2 {
        coordinate += parts[2] / 3600.0;
    }

    if direction == "S" || direction == "W" {
        coordinate = -coordinate;
    }
    coordinate
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

fn get_meta(metadata: Rexiv2Metadata) ->(Option<NaiveDateTime>, Option<f64>, Option<f64>) {

    let date_time = metadata
        .get_tag_string("Exif.Photo.DateTimeOriginal")
        .ok()
        .and_then(|dt| NaiveDateTime::parse_from_str(&dt, "%Y:%m:%d %H:%M:%S").ok());

    let latitude = metadata
        .get_tag_string("Exif.GPSInfo.GPSLatitude")
        .ok()
        .map(|latitude_str| {
            parse_gps_coordinate(
                &latitude_str,
                &metadata
                    .get_tag_string("Exif.GPSInfo.GPSLatitudeRef")
                    .unwrap_or("N".into()),
            )
        });

    let longitude = metadata
        .get_tag_string("Exif.GPSInfo.GPSLongitude")
        .ok()
        .map(|longitude_str| {
            parse_gps_coordinate(
                &longitude_str,
                &metadata
                    .get_tag_string("Exif.GPSInfo.GPSLongitudeRef")
                    .unwrap_or("E".into()),
            )
        });

    (date_time, latitude, longitude)
}

impl GeoData {
    async fn from_latlong(
        latitude: Option<f64>,
        longitude: Option<f64>,
    ) -> Result<Option<Self>, PicInfoError> {
        if latitude.is_some() && longitude.is_some() {
            let country = fetch_country_name(latitude.unwrap(), longitude.unwrap())
                .await
                .map_err(|e| PicInfoError::CountryFetchError(e.to_string()))?;
            let country = country.trim().to_owned();
            Ok(Some(Self {
                country,
                latitude: latitude.unwrap(),
                longitude: longitude.unwrap(),
            }))
        } else {
            Ok(None)
        }
    }
}

impl PicInfo {
    #[allow(unused)]
    pub async fn from_bytes(bytes: Bytes) -> Result<Self, PicInfoError> {
        // we use separate funciton as borrow checker is not happy when we create
        // Rexiv2Metadata in an async function
        let (date_time, latitude, longitude) = get_meta(Rexiv2Metadata::new_from_buffer(&bytes)?);
        let geo_data = GeoData::from_latlong(latitude, longitude).await?;

        Ok(Self {
            date_time,
            geo_data,
        })
    }

    pub async fn from_file(file_name: &str) -> Result<Self, PicInfoError> {
        let (date_time, latitude, longitude) = get_meta(Rexiv2Metadata::new_from_path(file_name)?);
        let geo_data = GeoData::from_latlong(latitude, longitude).await?;

        Ok(Self {
            date_time,
            geo_data,
        })
    }

    // pub fn google_map_link(&self) -> Option<String> {
    //     format!(
    //         "https://www.google.com/maps?q={},{}",
    //         self.latitude, self.longitude
    //     )
    // }
    //
    // pub fn country(&self) -> &str {
    //     &self.country
    // }
    //
    // pub fn cords(&self) -> (f64, f64) {
    //     (self.latitude, self.longitude)
    // }
}

