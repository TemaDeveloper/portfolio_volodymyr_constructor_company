use axum::{extract::State, response::IntoResponse};
use crate::{state::AppState, templates};

use super::validate::ValidVisitorUuid;

pub async fn get(visitor: ValidVisitorUuid, State(state): State<AppState>) -> impl IntoResponse {
    let _ = templates::HomeTemplate::from_db_conn(&state.db_conn, visitor.0)
        .await;
    format!("You got in <-> ur uuid is alright: {}", visitor.0)
}
