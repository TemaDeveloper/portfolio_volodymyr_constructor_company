use crate::{common, state::AppState};
use axum::{
    body::Body,
    extract::{Path, State},
    http::{Request, StatusCode},
    middleware::{self, Next},
    response::IntoResponse,
    Json,
};
use axum_extra::extract::{cookie::CookieJar, cookie::Cookie};
use serde_json::json;

const VISITOR_UUID_COOKIE_NAME: &'static str = "visitor-uuid";

pub async fn validate_visitor_cookie(
    State(state): State<AppState>,
    cookie_jar: CookieJar,
    req: Request<Body>,
    next: Next,
) -> impl IntoResponse {
    tracing::warn!("Cookies: {cookie_jar:?}");
    let uuid = cookie_jar.get(VISITOR_UUID_COOKIE_NAME);
    if let Some(uuid) = uuid {
        if state.validate_visitor(&uuid.value()).await.unwrap_or(false) {
            next.run(req).await
        } else {
            StatusCode::UNAUTHORIZED.into_response()
        }
    } else {
        (
            StatusCode::EXPECTATION_FAILED,
            Json(json!({"error": format!("No cookie with name={}", VISITOR_UUID_COOKIE_NAME)})),
        )
            .into_response()
    }
}

pub async fn page(
    State(state): State<AppState>,
    jar: CookieJar,
    Path(uuid): Path<String>
) -> impl IntoResponse {
    let is_valid = state.validate_visitor(&uuid)
        .await
        .unwrap_or(false);

    if is_valid {
        (
            StatusCode::OK,
            jar.add(Cookie::new(VISITOR_UUID_COOKIE_NAME, uuid))
        )
            .into_response()
    } else {
        (
            StatusCode::UNAUTHORIZED,
            Json(json!({"error": "Invalid visitor uuid"}))
        )
            .into_response()
    }
}

pub fn api_router(state: AppState) -> axum::Router<AppState> {
    axum::Router::new()
        .nest("/projects", common::get_router())
        .layer(middleware::from_fn_with_state(
            state,
            validate_visitor_cookie,
        ))
}
