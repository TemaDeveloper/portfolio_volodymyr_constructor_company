use backend::create_routes;
use dotenv::dotenv;
use tokio::net::TcpListener;
mod util;
mod entities;

#[tokio::main]
async fn main() -> anyhow::Result<()>{
    tracing_subscriber::fmt()
        .with_max_level(tracing::Level::INFO)
        .init();
    dotenv()?;

    let router = create_routes()
        .await?;

    let listener = TcpListener::bind("0.0.0.0:8000")
        .await?;

    axum::serve(listener, router)
        .await?;
    Ok(())
}
