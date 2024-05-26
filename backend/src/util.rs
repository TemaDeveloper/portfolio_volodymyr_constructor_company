use std::env;
use sea_orm::{Database, DatabaseConnection};

pub async fn connect_to_db() -> anyhow::Result<DatabaseConnection> {
    Ok(Database::connect(env::var("DATABASE_URL")?).await?)
}