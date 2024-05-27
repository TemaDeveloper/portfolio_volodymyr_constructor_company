use axum::{
    extract::{Extension, Json},
    http::StatusCode,
    response::IntoResponse,
};
use bcrypt::verify;
use chrono::Utc;
use jsonwebtoken::{encode, EncodingKey, Header};
use sea_orm::{DatabaseConnection, EntityTrait, QueryFilter};
use serde::{Deserialize, Serialize};
use serde_json::json;
use tracing::{info, error};

use crate::entities;

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
    Extension(db_conn): Extension<DatabaseConnection>,
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
        .one(&db_conn)
        .await;

    match user_result {
        Ok(Some(user)) => {
            info!("User found: {:?}", user);
            let stored_password = String::from_utf8(user.password).expect("Password decoding error");
            match verify(&user_info.password, &stored_password) {
                Ok(is_valid) => {
                    if is_valid {
                        match create_jwt(&user.email) {
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
