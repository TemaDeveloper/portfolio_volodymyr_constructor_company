use axum::response::IntoResponse;
use super::validate::ValidVisitorUuid;

pub async fn get(visitor: ValidVisitorUuid) -> impl IntoResponse {
    format!("You got in <-> ur uuid is alright: {}", visitor.0)
}
