use axum::{routing, Router};

mod validate;
mod home;
mod create;
pub use create::create;

use crate::state::AppState;


// NOTE: it is VERY VERY important that when `appending`
// this route you do .nest("/:visitor_uuid", ...)
// instead of anything else
pub fn get_visitor_router() -> Router<AppState> {
    Router::new()
        .route("/home", routing::get(home::get))
}
