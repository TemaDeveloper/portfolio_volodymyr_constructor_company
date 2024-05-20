use axum::{
    routing::get,
    Router
};
use axum::http::Method;
use tower_http::cors::{Any, CorsLayer};

pub async fn run(){

    let app = create_routes();
    let listener = tokio::net::TcpListener::bind("0.0.0.0:8000")
        .await
        .unwrap();

    axum::serve(listener, app)
        .await
        .unwrap();

} 

pub fn create_routes() -> Router<>{
    let cors = CorsLayer::new()
        .allow_methods([Method::GET, Method::POST])
        .allow_origin(Any);

    Router::new()
        .route("/auth", get(|| async {"Auth User!"}))
        .layer(cors)

}
