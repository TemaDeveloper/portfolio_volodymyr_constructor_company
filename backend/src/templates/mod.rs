use askama::Template;
use sea_orm::{DatabaseConnection, DbErr, EntityOrSelect, EntityTrait, QuerySelect, SelectColumns};
use uuid::Uuid;

use crate::entities::projects;

#[derive(Default)]
pub struct HomeTemplate {
    uuid: Uuid,
    years: Vec<u32>,
}

#[derive(thiserror::Error, Debug)]
pub enum HomeError {
    #[error("Database error: {0}")]
    DbError(#[from] DbErr)
}

impl HomeTemplate {
    pub async fn from_db_conn(db_conn: &DatabaseConnection, uuid: Uuid) -> Result<HomeTemplate, HomeError> {
        let years: Vec<i32> = projects::Entity::find()
            .select_only()
            .column(projects::Column::Year)
            .distinct()
            .into_values::<_, projects::Column>()
            .all(db_conn)
            .await?;

        tracing::info!("Distinct years are: {years:?}");

        Ok(Default::default())
    }
}
