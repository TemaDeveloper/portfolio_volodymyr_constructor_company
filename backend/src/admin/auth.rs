use std::sync::Arc;

use axum::{
    body::Body, extract::{Extension, Json, State}, http::{header, Request, Response, StatusCode}, middleware::Next, response::IntoResponse
};
use bcrypt::{hash, verify, DEFAULT_COST};
use chrono::{Duration, Local, NaiveDateTime, Utc};
use jsonwebtoken::{decode, encode, Algorithm, DecodingKey, EncodingKey, Header, Validation};
use sea_orm::{ActiveModelTrait, ColumnTrait, DatabaseConnection, EntityTrait, QueryFilter};
use serde::{Deserialize, Serialize};
use serde_json::json;
use tokio::sync::Mutex;
use tracing::{info, error};
use lazy_static::lazy_static;

use crate::{entities::{self, user}, state::AppState};


#[derive(Deserialize, Debug)]
pub struct GetReqBody {
    pub name: Option<String>,
    pub email: Option<String>,
    pub password: String,
}


#[derive(Debug, Serialize, Deserialize)]
struct Claims {
    sub: String, // subject
    exp: usize,  // expiration time (as UTC timestamp)
}

lazy_static! {
    static ref SECRET_KEY: Arc<String> = Arc::new(generate_secret_key());
}

fn generate_secret_key() -> String {
    use rand::Rng;
    let mut rng = rand::thread_rng();
    (0..32).map(|_| (rng.gen::<u8>() % 26 + 97) as char).collect()
}

pub fn create_token(sub: &str, valid_for: Duration) -> Result<String, String> {
    let expiration = Local::now().naive_local() + valid_for;
    let exp_timestamp = expiration.and_utc().timestamp() as usize;

    let claims = Claims {
        sub: sub.to_owned(),
        exp: exp_timestamp,
    };

    encode(&Header::default(), &claims, &EncodingKey::from_secret(SECRET_KEY.as_ref().as_bytes()))
        .map_err(|e| e.to_string())
}

pub async fn validate_jwt(
    req: Request<Body>,
    next: Next,
) -> Result<Response<Body>, StatusCode> {
    if let Some(cookie) = req.headers().get("cookie") {
        if let Ok(cookie_str) = cookie.to_str() {
            let jwt_cookie = cookie_str
                .split(';')
                .find(|s| s.trim_start().starts_with("jwt="));

            if let Some(jwt_cookie) = jwt_cookie {
                let token = jwt_cookie.trim_start_matches("jwt=").trim();
                let decoding_key = DecodingKey::from_secret(SECRET_KEY.as_ref().as_bytes());
                let validation = Validation::new(Algorithm::HS256);

                match decode::<Claims>(token, &decoding_key, &validation) {
                    Ok(_) => return Ok(next.run(req).await),
                    Err(_) => return Err(StatusCode::UNAUTHORIZED),
                }
            }
        }
    }

    Err(StatusCode::UNAUTHORIZED)
}

pub async fn login(
    State(state): State<AppState>,
    Json(user_info): Json<GetReqBody>,
) -> impl IntoResponse {
    use bcrypt::verify;

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
                        match create_token(&user.email.clone().unwrap(), Duration::seconds(3600)) {
                            Ok(token) => {
                                info!("Authentication successful for user: {:?}", user.email);

                                let mut response = (StatusCode::OK, Json(json!({ "message": "Login successful" }))).into_response();
                                let cookie_header = format!("jwt={}; Path=/; HttpOnly", token);
                                response.headers_mut().insert(
                                    header::SET_COOKIE,
                                    cookie_header.parse().unwrap(),
                                );
                                return response;
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
