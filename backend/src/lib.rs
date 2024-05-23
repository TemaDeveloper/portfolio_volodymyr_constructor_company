// use axum::{
//     routing::get,
//     Router, 
//     Extension
// };
// // use axum::http::Method;
// // use tower_http::cors::{Any, CorsLayer};

// mod countrie;
// mod util;

// pub async fn run(){

//     // let cors = CorsLayer::new()
//     //     .allow_methods([Method::GET, Method::POST])
//     //     .allow_origin(Any);

//     let app = Router::new()
//         .route("/auth", get(|| async {"Auth User!"}))
//         .layer(Extension(util::connect_to_db().await));
    
//     let listener = tokio::net::TcpListener::bind("0.0.0.0:8000")
//         .await
//         .unwrap();

//     axum::serve(listener, app)
//         .await
//         .unwrap();

// } 