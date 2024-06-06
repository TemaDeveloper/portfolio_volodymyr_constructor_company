use crate::{
    entities::user,
    state::{self, AppState},
};
use axum::{
    body::Body, extract::State, http::{header, Response, StatusCode}, response::IntoResponse, Json
};
use chrono::Utc;
use jsonwebtoken::{encode, EncodingKey, Header};
use sea_orm::{ColumnTrait, EntityTrait, PaginatorTrait, QueryFilter};
use serde::Deserialize;
use super::JwtClaims;

const VALID_FOR: chrono::TimeDelta = chrono::TimeDelta::seconds(60*60*24); /* 1 day */

pub fn issue_jwt() -> Result<String, jsonwebtoken::errors::Error> {
    encode(
        &Header::default(),
        &JwtClaims { exp: (Utc::now() + VALID_FOR).timestamp() as usize },
        &EncodingKey::from_secret(state::SECRET_KEY.as_bytes()),
    )
}

#[derive(Deserialize)]
pub struct AuthReq {
    email: String,
    password: String,
}

pub async fn auth(
    State(state): State<AppState>,
    Json(body): Json<AuthReq>, 
) -> impl IntoResponse {
    let count = user::Entity::find()
        .filter(user::Column::Email.eq(&body.email))
        .filter(user::Column::Password.eq(&body.password))
        .count(&state.db_conn)
        .await;

    match count {
        Err(e) => {
            tracing::error!("Or here: {e}");
            StatusCode::INTERNAL_SERVER_ERROR.into_response()
        },
        Ok(count) => {
            if count != 1 {
                StatusCode::IM_A_TEAPOT /* hell yeah I am */
                    .into_response()
            } else {
                match issue_jwt() {
                    Err(_) => {
                        tracing::error!("here");
                        StatusCode::INTERNAL_SERVER_ERROR.into_response()
                    },
                    Ok(token) => {
                        Response::builder()
                            .status(StatusCode::OK)
                            .header(header::AUTHORIZATION, format!("Bearer {}", token))
                            .body(Body::default())
                            .unwrap()
                            
                    }
                }
            }
        }
    }
}
