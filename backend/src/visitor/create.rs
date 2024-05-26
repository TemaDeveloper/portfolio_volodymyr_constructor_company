use axum::{
    extract::State,
    http::StatusCode,
    response::IntoResponse,
    Json,
};
use chrono::{Local, NaiveDateTime, TimeDelta};
use sea_orm::{ActiveModelTrait, Set};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use crate::{
    entities::visitor,
    state::AppState,
};

#[derive(Serialize)]
pub struct CreateResponse {
    pub uuid: Uuid,
    pub valid_till: Option<NaiveDateTime>,
}

#[derive(Deserialize)]
pub struct CreateInfo {
    /* don't put i64/i32 here, so there is no messing with backend by putting negative time */
    pub valid_for_sec: Option<u64>,
}

pub async fn create(
    // TODO: add some verification here
    State(state): State<AppState>,
    Json(create_info): Json<CreateInfo>,
) -> impl IntoResponse {
    let now = Local::now().naive_local();
    let uuid = Uuid::new_v4();
    let valid_till = create_info
        .valid_for_sec
        .map(|valid_for| now + TimeDelta::seconds(valid_for as i64));

    let visitor = visitor::ActiveModel {
        uuid: Set(uuid.to_string()),
        time_out: Set(valid_till.clone()),
    };
    visitor.insert(&state.db_conn).await.unwrap();

    (StatusCode::OK, Json(CreateResponse { uuid, valid_till }))
}
