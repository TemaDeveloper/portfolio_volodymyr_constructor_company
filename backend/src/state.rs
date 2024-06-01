use chrono::NaiveDateTime;
use sea_orm::{ColumnTrait, DatabaseConnection, DbErr, EntityTrait, QueryFilter};
use std::{env, sync::Arc, time::Duration};
use tokio::sync::Mutex;

use crate::entities::visitor;

#[derive(Clone)]
pub struct AppState {
    pub db_conn: DatabaseConnection,
    pub valid_tokens: Arc<Mutex<Vec<(NaiveDateTime, String)>>>,
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
        let valid_tokens: Arc<Mutex<Vec<(NaiveDateTime, String)>>> = Default::default();
        let s = Self {
            db_conn: db_conn.clone(),
            valid_tokens: valid_tokens.clone()
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

                let valid_tokens = valid_tokens.get_mut();
                valid_tokens = valid_tokens.iter().filter(move |(exp, _)| exp <= &now).collect();

                tokio::time::sleep(Duration::from_secs(30)).await;
            }
        });

        Ok(s)
    }
}
