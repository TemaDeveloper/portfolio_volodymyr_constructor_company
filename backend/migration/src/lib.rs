pub use sea_orm_migration::prelude::*;

pub mod m20220101_000001_visitors_table_create;
pub mod m20240526_233614_projects;

pub struct Migrator;

#[async_trait::async_trait]
impl MigratorTrait for Migrator {
    fn migrations() -> Vec<Box<dyn MigrationTrait>> {
        vec![
            Box::new(m20220101_000001_visitors_table_create::Migration),
            Box::new(m20240526_233614_projects::Migration),
        ]
    }
}
