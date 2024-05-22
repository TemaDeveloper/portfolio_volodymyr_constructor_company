use chrono::NaiveDateTime;
use reqwest::Client;
use rexiv2::Metadata as Rexiv2Metadata;
use serde::{Deserialize, Serialize};
use thiserror::Error;

#[derive(Error, Debug)]
pub enum PicInfoError {
    #[error("{0}")]
    ParseError(#[from] rexiv2::Rexiv2Error),
    #[error("No Latitude supplied in file's metadata")]
    NoLatitude,
    #[error("No Longitude supplied in file's metadata")]
    NoLongitude,
    #[error("Failed to fetch country name: {0}")]
    CountryFetchError(String),
}

#[derive(Serialize, Deserialize, Debug)]
pub struct PicInfo {
    country: String,
    date_time: Option<NaiveDateTime>,
    latitude: f64,
    longitude: f64,
}

impl PicInfo {
    pub async fn from_slice(file: &[u8]) -> Result<Self, PicInfoError> {
        let metadata = Rexiv2Metadata::new_from_buffer(file)?;

        let date_time = metadata
            .get_tag_string("Exif.Photo.DateTimeOriginal")
            .ok()
            .and_then(|dt| NaiveDateTime::parse_from_str(&dt, "%Y:%m:%d %H:%M:%S").ok());

        let latitude_str = metadata
            .get_tag_string("Exif.GPSInfo.GPSLatitude")
            .map_err(|_| PicInfoError::NoLatitude)?;

        let longitude_str = metadata
            .get_tag_string("Exif.GPSInfo.GPSLongitude")
            .map_err(|_| PicInfoError::NoLongitude)?;

        let latitude = parse_gps_coordinate(
            &latitude_str,
            metadata
                .get_tag_string("Exif.GPSInfo.GPSLatitudeRef")
                .unwrap_or("N".into()),
        );
        let longitude = parse_gps_coordinate(
            &longitude_str,
            metadata
                .get_tag_string("Exif.GPSInfo.GPSLongitudeRef")
                .unwrap_or("E".into()),
        );

        let country = fetch_country_name(latitude, longitude)
            .await
            .map_err(|e| PicInfoError::CountryFetchError(e.to_string()))?;

        Ok(Self {
            country,
            date_time,
            latitude,
            longitude,
        })
    }

    pub fn google_map_link(&self) -> String {
        format!(
            "https://www.google.com/maps?q={},{}",
            self.latitude, self.longitude
        )
    }

    pub fn country(&self) -> &str {
        &self.country
    }

    pub fn cords(&self) -> (f64, f64) {
        (self.latitude, self.longitude)
    }
}

fn parse_gps_coordinate(gps_str: &str, direction: String) -> f64 {
    let parts: Vec<f64> = gps_str
        .split_whitespace()
        .map(|s| {
            let fraction: Vec<&str> = s.split('/').collect();
            fraction[0].parse::<f64>().unwrap() / fraction[1].parse::<f64>().unwrap()
        })
        .collect();

    let mut coordinate = parts[0] + (parts[1] / 60.0) + (parts[2] / 3600.0);
    if direction == "S" || direction == "W" {
        coordinate = -coordinate;
    }
    coordinate
}

async fn fetch_country_name(latitude: f64, longitude: f64) -> Result<String, reqwest::Error> {
    let client = Client::new();
    let url = format!("https://api.bigdatacloud.net/data/reverse-geocode-client?latitude={}&longitude={}&localityLanguage=en", latitude, longitude);
    let response: serde_json::Value = client.get(&url).send().await?.json().await?;

    Ok(response["countryName"]
        .as_str()
        .unwrap_or("Unknown")
        .to_string())
}
