use axum::routing;

use crate::state::AppState;
mod create;
mod delete;
mod update;
mod upload;
mod util;
mod pic_info;

pub fn get_router() -> axum::Router<AppState> {
    axum::Router::new()
        .route("/", routing::post(create::project)) 
        .route("/:id", routing::patch(update::project)) 
        .route("/:id", routing::delete(delete::project)) 
        .route("/pictures", routing::post(upload::pictures))
        .route("/videos", routing::post(upload::videos))
        /* delete is there because of issue, of dynamic route conflicts*/
        .route("/storage/delete/:file_name", routing::delete(delete::file))
}
