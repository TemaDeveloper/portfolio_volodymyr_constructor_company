use axum::{
    body::Body,
    http::{Request, StatusCode},
    middleware::Next,
    response::IntoResponse,
};
use axum_extra::{
    headers::{authorization::Bearer, Authorization},
    TypedHeader,
};
use chrono::Utc;
use jsonwebtoken::{decode, DecodingKey, Validation};
use crate::state;
use super::JwtClaims;

pub async fn is_admin(
    bearer: Option<TypedHeader<Authorization<Bearer>>>,
    req: Request<Body>,
    next: Next,
) -> impl axum::response::IntoResponse {
    if !cfg!(debug_assertions) && bearer.is_none() {
        /* require authentication in release mode */
        tracing::warn!("No bearer token");
        return StatusCode::UNAUTHORIZED.into_response();
    }

    if let Some(TypedHeader(Authorization(token))) = bearer {
        let claims = if let Ok(claims) = decode::<JwtClaims>(
            token.token(),
            &DecodingKey::from_secret(state::SECRET_KEY.as_bytes()),
            &Validation::default(),
        ) {
            claims
        } else {
            return StatusCode::UNAUTHORIZED.into_response();
        };

        if claims.claims.exp >= Utc::now().timestamp() as usize {
            next.run(req).await
        } else {
            StatusCode::UNAUTHORIZED.into_response()
        }
    } else {
        /* should not happen in release ever */
        next.run(req).await
    }
}
