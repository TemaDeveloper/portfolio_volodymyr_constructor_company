use crate::{common, state::AppState};
use axum::{
    body::Body,
    extract::{Path, State},
    http::{Request, StatusCode},
    middleware::{self, Next},
    response::{Html, IntoResponse},
    Json,
};
use axum_extra::extract::cookie::{Cookie, CookieJar};
use serde_json::json;
use tower_http::services::ServeDir;
const VISITOR_UUID_COOKIE_NAME: &'static str = "visitor-uuid";

pub async fn validate_visitor_cookie(
    State(state): State<AppState>,
    cookie_jar: CookieJar,
    req: Request<Body>,
    next: Next,
) -> impl IntoResponse {
    let uuid = cookie_jar.get(VISITOR_UUID_COOKIE_NAME);
    if let Some(uuid) = uuid {
        tracing::warn!("Cookie: {}", uuid.value());
        if state.validate_visitor(&uuid.value()).await.unwrap_or(false) {
            next.run(req).await
        } else {
            tracing::error!("Invalid uuid");
            StatusCode::UNAUTHORIZED.into_response()
        }
    } else {
        tracing::error!("No cookie found{uuid:?}");
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
    tracing::warn!("Got uuid on login: {uuid}");
    let is_valid = state.validate_visitor(&uuid)
        .await
        .unwrap_or(false);

    if is_valid {
        let file = include_str!("../../frontend_visitor/build/web/index.html");
        let mut cookie = Cookie::new(VISITOR_UUID_COOKIE_NAME, uuid);
        cookie.set_path("/");
        (
            StatusCode::OK,
            jar.add(cookie),
            Html::from(file)
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

pub fn static_router() -> ServeDir {
    ServeDir::new("../frontend_visitor/build/web") 
}

pub fn api_router(state: AppState) -> axum::Router<AppState> {
    axum::Router::new()
        .nest("/projects", common::get_router())
        .layer(middleware::from_fn_with_state(
            state,
            validate_visitor_cookie,
        ))
}
