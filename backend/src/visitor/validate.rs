use axum::{
    async_trait, body::Body, extract::{rejection::PathRejection, FromRequestParts, Path, State}, http::{request::Parts, Request, Response, StatusCode}, middleware::Next, response::IntoResponse, RequestExt, RequestPartsExt
};
use sea_orm::{ColumnTrait, DatabaseConnection, EntityTrait, PaginatorTrait, QueryFilter};
use uuid::Uuid;

use crate::{entities::visitor, state::AppState};

async fn validate_visitor_uuid(db_conn: &DatabaseConnection, uuid: &Uuid) -> bool {
    let count = visitor::Entity::find()
        .filter(visitor::Column::Uuid.eq(uuid.to_string()))
        .filter(visitor::Column::TimeOut.gte(chrono::Local::now().naive_local()))
        .count(db_conn)
        .await
        .unwrap_or(0);

    if count > 1 {
        tracing::warn!("It's probaly an error, or there are 2 duplicate uuids");
    }

    count == 1
}

pub struct ValidVisitorUuid(pub Uuid);
pub struct InvalidVisitorUuid;

#[async_trait]
impl FromRequestParts<AppState> for ValidVisitorUuid {
    type Rejection = InvalidVisitorUuid;

    async fn from_request_parts(
        parts: &mut Parts,
        state: &AppState,
    ) -> Result<Self, Self::Rejection> {
        let uuid = parts.extract::<Path<Uuid>>().await?;

        if validate_visitor_uuid(&state.db_conn, &uuid).await {
            Ok(Self(*uuid))
        } else {
            Err(InvalidVisitorUuid {})
        }
    }
}

// TODO: make this into a redirect to an error page
impl IntoResponse for InvalidVisitorUuid {
    fn into_response(self) -> Response<Body> {
        let response = Response::builder()
            .status(StatusCode::UNAUTHORIZED)
            .body(Body::from(
                "Contact big boss to get proper link".to_string(),
            ))
            .unwrap();

        response
    }
}

impl From<PathRejection> for InvalidVisitorUuid {
    fn from(_value: PathRejection) -> Self {
        Self {}
    }
}
