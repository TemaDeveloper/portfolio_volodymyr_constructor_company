use crate::{common, state::AppState};
use axum::{
    body::Body,
    extract::{Path, State},
    http::{Request, StatusCode},
    middleware::{self, Next},
    response::{Html, IntoResponse},
    Json,
};
use axum_extra::{extract::cookie::{Cookie, CookieJar}, headers::{authorization::Bearer, Authorization}, TypedHeader};
use serde_json::json;
use tower_http::services::ServeDir;
const VISITOR_UUID_COOKIE_NAME: &'static str = "visitor-uuid";

pub async fn validate_visitor(
    bearer: Option<TypedHeader<Authorization<Bearer>>>,
    State(state): State<AppState>,
    req: Request<Body>,
    next: Next,
) -> impl IntoResponse {

    if !cfg!(debug_assertions) && bearer.is_none() {
        /* require authentication in release mode */
        tracing::warn!("No bearer token");
        return StatusCode::UNAUTHORIZED.into_response();
    }

    if let Some(TypedHeader(Authorization(token))) = bearer {
        if state.validate_visitor(token.token()).await.unwrap_or(false) {
            next.run(req).await
        } else {
            StatusCode::UNAUTHORIZED.into_response()
        }
    } else {
        /* should not happen in release ever */
        tracing::warn!("No bearer token, although debug mode");
        next.run(req).await
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
        let file = include_str!("../../frontend_visitor/build/web/index.html");
        (
            StatusCode::OK,
            jar.add(Cookie::new(VISITOR_UUID_COOKIE_NAME, uuid)),
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
    ServeDir::new("../../frontend_visitor/build/web") 
}

pub fn api_router(state: AppState) -> axum::Router<AppState> {
    axum::Router::new()
        .nest("/projects", common::get_router())
        .layer(middleware::from_fn_with_state(
            state,
            validate_visitor,
        ))
}
