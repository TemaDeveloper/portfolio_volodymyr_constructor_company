use crate::entities::visitor;
use chrono::{NaiveDateTime, TimeDelta};
use jsonwebtoken::{encode, Algorithm, EncodingKey, Header};
use sea_orm::{ColumnTrait, DatabaseConnection, DbErr, EntityTrait, QueryFilter};
use serde::{Deserialize, Serialize};
use std::{env, sync::Arc, time::Duration};
use tokio::sync::Mutex;


#[derive(Debug, Deserialize, Serialize)]
struct Claims {
    sub: String,
    exp: usize,
}

#[derive(Clone)]
pub struct AppState {
    pub db_conn: DatabaseConnection,
}

#[derive(Debug, thiserror::Error)]
pub enum StateInitError {
    #[error("No env var(DATABASE_URL) found, error: {0}")]
    NoEnvVar(#[from] env::VarError),

    #[error("Data base error: {0}")]
    DataBaseError(#[from] DbErr),
}

impl AppState {
    pub async fn init() -> Result<Self, StateInitError> {
        let db_conn = sea_orm::Database::connect(env::var("DATABASE_URL")?).await?;
        let s = Self {
            db_conn: db_conn.clone(),
        };

        tokio::spawn(async move {
            loop {
                let now = chrono::Local::now().naive_local();
                let res = visitor::Entity::delete_many()
                    .filter(visitor::Column::TimeOut.lte(now.clone()))
                    .exec(&db_conn)
                    .await;

                match res {
                    Ok(r) => tracing::info!("Deleted {} timed out visitors", r.rows_affected),
                    Err(e) => tracing::error!("DataBase Error: {}", e),
                }

                tokio::time::sleep(Duration::from_secs(30)).await;
            }
        });

        Ok(s)
    }
}
