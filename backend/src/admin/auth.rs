use std::sync::Arc;

use axum::{
    extract::{Extension, Json, State},
    http::StatusCode,
    response::IntoResponse,
};
use bcrypt::{hash, verify, DEFAULT_COST};
use chrono::{NaiveDateTime, Utc};
use jsonwebtoken::{encode, EncodingKey, Header};
use sea_orm::{ActiveModelTrait, ColumnTrait, DatabaseConnection, EntityTrait, QueryFilter};
use serde::{Deserialize, Serialize};
use serde_json::json;
use tokio::sync::Mutex;
use tracing::{info, error};
use lazy_static::lazy_static;

use crate::{entities, state::AppState};

const JWT_SECRET: &[u8] = b"secret";

#[derive(Deserialize, Debug)]
pub struct GetReqBody {
    pub name: Option<String>,
    pub email: Option<String>,
    pub password: String,
}

#[derive(Debug, Deserialize, Serialize)]
struct Claims {
    sub: String,
    exp: usize,
}

use jsonwebtoken::Algorithm;

pub fn create_jwt(uid: &str) -> Result<String, String> {
    let expiration = Utc::now()
        .checked_add_signed(chrono::Duration::seconds(3600))
        .expect("valid timestamp")
        .timestamp();

    let claims = Claims {
        sub: uid.to_owned(),
        exp: expiration as usize,
    };
    let header = Header::new(Algorithm::HS512);
    encode(&header, &claims, &EncodingKey::from_secret(JWT_SECRET))
        .map_err(|_| "JWTTokenCreationError".to_string())
}

pub async fn login(
    State(state): State<AppState>,
    Json(user_info): Json<GetReqBody>,
) -> impl IntoResponse {
    use entities::user;
    use sea_orm::ColumnTrait;

    info!("Received user_info: {:?}", user_info);

    let user_result = user::Entity::find()
        .filter(
            user::Column::Name
                .eq(user_info.name.as_deref().unwrap_or_default())
                .or(user::Column::Email.eq(user_info.email.as_deref().unwrap_or_default())),
        )
        .one(&state.db_conn)
        .await;

    match user_result {
        Ok(Some(user)) => {
            info!("User found: {:?}", user);
            let stored_password = String::from_utf8(user.password).expect("Password decoding error");
            match verify(&user_info.password, &stored_password) {
                Ok(is_valid) => {
                    if is_valid {
                        match create_jwt(&user.email.clone().unwrap()) {
                            Ok(token) => {
                                info!("Authentication successful for user: {:?}", user.email);
                                return (StatusCode::OK, Json(json!({ "token": token }))).into_response();
                            }
                            Err(err) => {
                                error!("JWT creation error: {:?}", err);
                                return (StatusCode::INTERNAL_SERVER_ERROR, Json(json!({ "error": "JWT creation error" }))).into_response();
                            }
                        }
                    } else {
                        info!("Password verification failed for user: {:?}", user_info);
                        return (StatusCode::UNAUTHORIZED, Json(json!({ "error": "Invalid credentials" }))).into_response();
                    }
                }
                Err(e) => {
                    error!("Password verification error for user: {:?}, error: {:?}", user_info, e);
                    return (StatusCode::INTERNAL_SERVER_ERROR, Json(json!({ "error": "Password verification error" }))).into_response();
                }
            }
        }
        Ok(None) => {
            info!("User not found: {:?}", user_info);
            return (StatusCode::NOT_FOUND, Json(json!({ "error": "User not found" }))).into_response();
        }
        Err(e) => {
            error!("Database query error: {:?}", e);
            return (StatusCode::INTERNAL_SERVER_ERROR, Json(json!({ "error": "Database query error" }))).into_response();
        }
    }
}

#[derive(Deserialize, Debug)]
pub struct AddUserReqBody {
    pub name: String,
    pub last_name: String,
    pub email: String,
    pub password: String,
}

pub async fn add_user(
    State(state): State<AppState>,
    Json(user_info): Json<AddUserReqBody>,
) -> impl IntoResponse {
    use entities::user;

    info!("Received user_info: {:?}", user_info);

    // Check if the user already exists
    let existing_user = user::Entity::find()
        .filter(user::Column::Email.eq(user_info.email.clone()))
        .one(&state.db_conn)
        .await;

    if let Ok(Some(_)) = existing_user {
        info!("User with email {} already exists", user_info.email);
        return (StatusCode::CONFLICT, Json(json!({ "error": "User already exists" }))).into_response();
    }

    // Hash the password
    let hashed_password = match hash(&user_info.password, DEFAULT_COST) {
        Ok(pwd) => pwd,
        Err(e) => {
            error!("Password hashing error: {:?}", e);
            return (StatusCode::INTERNAL_SERVER_ERROR, Json(json!({ "error": "Password hashing error" }))).into_response();
        }
    };

    // Create the new user
    let new_user = user::ActiveModel {
        name: sea_orm::Set(user_info.name.clone()),
        last_name: sea_orm::Set(user_info.last_name.clone()),
        email: sea_orm::Set(Some(user_info.email.clone())),
        password: sea_orm::Set(hashed_password.into_bytes()),
        ..Default::default()
    };

    // Insert the new user into the database
    match new_user.insert(&state.db_conn).await {
        Ok(user) => {
            info!("User created: {:?}", user);
            (StatusCode::CREATED, Json(json!({ "message": "User created" }))).into_response()
        }
        Err(e) => {
            error!("Database insertion error: {:?}", e);
            (StatusCode::INTERNAL_SERVER_ERROR, Json(json!({ "error": "Database insertion error" }))).into_response()
        }
    }
}
