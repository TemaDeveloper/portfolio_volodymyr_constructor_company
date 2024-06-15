use crate::entities::visitor;
use lazy_static::lazy_static;
use rand::{distributions::Alphanumeric, Rng};
use sea_orm::{ColumnTrait, DatabaseConnection, DbErr, EntityTrait, PaginatorTrait, QueryFilter};
use std::{env, time::Duration};

lazy_static! {
    /// NOTE: regenerated after each server restart
    pub static ref SECRET_KEY: String = rand::thread_rng()
        .sample_iter(&Alphanumeric)
        .take(32)
        .map(char::from)
        .collect();
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

    pub async fn validate_visitor(&self, uuid: &str) -> Result<bool, DbErr> {
        tracing::warn!("got uuid here: {uuid}");
        let count = visitor::Entity::find()
            .filter(visitor::Column::Uuid.eq(uuid))
            .filter(visitor::Column::TimeOut.gte(chrono::Local::now().naive_local()))
            .count(&self.db_conn)
            .await?;

        if count > 1 {
            tracing::warn!("It's probaly an error, or there are 2 duplicate uuids");
        }
        
        tracing::warn!("Count={count}");
        Ok(count == 1)
    }
}
