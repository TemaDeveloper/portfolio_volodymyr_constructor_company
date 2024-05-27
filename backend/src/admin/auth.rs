use axum::{
    extract::{Extension, Json},
    http::StatusCode,
    response::IntoResponse,
};
use bcrypt::verify;
use sea_orm::{DatabaseConnection, EntityTrait, QueryFilter};
use serde::{Deserialize, Serialize};
use tracing::{info, error};

use crate::entities;

#[derive(Deserialize, Debug)]
pub struct GetReqBody {
    pub name: Option<String>,
    pub email: Option<String>,
    pub password: String,
}

#[derive(Serialize, Debug)]
pub struct GetResponse {
    pub id: i32,
    pub name: String,
    pub email: String,
    pub is_admin: bool,
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
            match verify(&user_info.password, &String::from_utf8_lossy(&user.password)) {
                Ok(is_valid) => {
                    if is_valid {
                        let user_response = GetResponse {
                            id: user.id,
                            name: user.name,
                            email: user.email,
                            is_admin: true, // Assuming there's an `is_admin` field
                        };
                        info!("Authentication successful for user: {:?}", user_response);
                        return (StatusCode::OK, Json(user_response)).into_response();
                    } else {
                        info!("Password verification failed for user: {:?}", user_info);
                        return (StatusCode::UNAUTHORIZED, Json("Invalid credentials")).into_response();
                    }
                }
                Err(e) => {
                    error!("Password verification error for user: {:?}, error: {:?}", user_info, e);
                    return (StatusCode::INTERNAL_SERVER_ERROR, Json("Password verification error")).into_response();
                }
            }
        }
        Ok(None) => {
            info!("User not found: {:?}", user_info);
            return (StatusCode::NOT_FOUND, Json("User not found")).into_response();
        }
        Err(e) => {
            error!("Database query error: {:?}", e);
            return (StatusCode::INTERNAL_SERVER_ERROR, Json("Database query error")).into_response();
        }
    }
}
