use crate::pic_info::PicInfo;
use axum::{routing::{get, patch, post}, Extension, Router};
mod pic_info;

mod util;
mod entities;

#[tokio::main]
async fn main() -> anyhow::Result<()>{

    // let pic = include_bytes!("../20240518_214102.jpg");
    // println!("{:?}", PicInfo::from_slice(pic).await?);
    dotenv::dotenv()?;

    let app = Router::new()
        .route("/auth", get(|| async {"Auth User!"}))
        .layer(Extension(util::connect_to_db().await?));
    
    let listener = tokio::net::TcpListener::bind("0.0.0.0:8000")
        .await
        .unwrap();

    axum::serve(listener, app)
        .await
        .unwrap();

    Ok(())
}
