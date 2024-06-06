use axum::{extract::State, response::IntoResponse, Json, http::StatusCode};
use sea_orm::{ActiveModelTrait, ColumnTrait, EntityTrait, QueryFilter};
use serde::Deserialize;
use serde_json::json;
use crate::{entities, state::AppState};


#[derive(Deserialize)]
pub struct AddUserReqBody {
    pub name: Option<String>,
    pub last_name: Option<String>,
    pub email: String,
    pub password: String,
}

pub async fn new_admin(
    State(state): State<AppState>,
    Json(user_info): Json<AddUserReqBody>,
) -> impl IntoResponse {
    use entities::user;

    let AddUserReqBody { name, last_name, email, password } = user_info; 

    let existing_user = user::Entity::find()
        .filter(user::Column::Email.eq(&email))
        .one(&state.db_conn)
        .await;

    if let Ok(Some(_)) = existing_user {
        return (StatusCode::CONFLICT, Json(json!({ "error": "User already exists" }))).into_response();
    }

    let new_user = user::ActiveModel {
        name: sea_orm::Set(name),
        last_name: sea_orm::Set(last_name),
        email: sea_orm::Set(email),
        password: sea_orm::Set(password),
        ..Default::default()
    };

    match new_user.insert(&state.db_conn).await {
        Ok(_user) => {
            (StatusCode::CREATED, Json(json!({ "message": "User created" }))).into_response()
        }
        Err(_e) => {
            (StatusCode::INTERNAL_SERVER_ERROR, Json(json!({ "error": "Database insertion error" }))).into_response()
        }
    }
}
