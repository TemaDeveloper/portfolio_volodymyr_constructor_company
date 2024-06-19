use std::path::PathBuf;

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
use tokio::{fs::File, io::AsyncReadExt};
use tower_http::services::ServeDir;

const VISITOR_UUID_COOKIE_NAME: &'static str = "visitor-uuid";

async fn read_file(path: impl AsRef<std::path::Path>) -> Option<String> {
    let mut file = File::open(path).await.ok()?;
    let mut contents = String::new();
    file.read_to_string(&mut contents).await.ok()?;
    Some(contents)
}

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
    Path(uuid): Path<String>,
) -> impl IntoResponse {
    tracing::warn!("Got uuid on login: {uuid}");
    let is_valid = state.validate_visitor(&uuid).await.unwrap_or(false);

    if is_valid {
        let file =
            match read_file(PathBuf::from(state.visitor_dir.as_ref()).join("index.html")).await {
                None => return StatusCode::INTERNAL_SERVER_ERROR.into_response(),
                Some(file) => file,
            };
        let mut cookie = Cookie::new(VISITOR_UUID_COOKIE_NAME, uuid);
        cookie.set_path("/");
        (StatusCode::OK, jar.add(cookie), Html::from(file)).into_response()
    } else {
        (
            StatusCode::UNAUTHORIZED,
            Json(json!({"error": "Invalid visitor uuid"})),
        )
            .into_response()
    }
}

pub fn static_router(state: AppState) -> axum::Router<AppState> {
    axum::Router::new()
        .nest_service("/", ServeDir::new(state.visitor_dir.as_ref()))
}

pub fn api_router(state: AppState) -> axum::Router<AppState> {
    axum::Router::new()
        .nest("/projects", common::get_router())
        .layer(middleware::from_fn_with_state(
            state,
            validate_visitor_cookie,
        ))
}
