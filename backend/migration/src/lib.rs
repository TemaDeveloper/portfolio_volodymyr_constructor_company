pub use sea_orm_migration::prelude::*;


mod m20220101_000001_user_table_create;
mod m20220101_000001_visitors_table_create;
mod m20240528_022228_projects;
mod m20240606_174153_entity;

pub struct Migrator;

#[async_trait::async_trait]
impl MigratorTrait for Migrator {
    fn migrations() -> Vec<Box<dyn MigrationTrait>> {
        vec![
            Box::new(m20220101_000001_user_table_create::Migration),
            Box::new(m20220101_000001_visitors_table_create::Migration),
            Box::new(m20240528_022228_projects::Migration),
            Box::new(m20240606_174153_entity::Migration),
        ]
    }
}
