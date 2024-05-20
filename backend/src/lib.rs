use axum::{
    routing::get,
    Router,
};

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

    Router::new()
    .route("/auth", get(|| async {"Auth User!"}))

}
