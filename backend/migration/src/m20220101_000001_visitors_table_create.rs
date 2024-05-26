use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        manager
            .create_table(
                Table::create()
                    .table(Visitor::Table)
                    .if_not_exists()
                    .col(
                        ColumnDef::new(Visitor::Uuid)
                            .string()
                            .not_null()
                            .primary_key(),
                    )
                    .col(ColumnDef::new(Visitor::TimeOut).date_time())
                    .to_owned(),
            )
            .await
    }

    async fn down(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        manager
            .drop_table(Table::drop().table(Visitor::Table).to_owned())
            .await
    }
}

#[derive(DeriveIden)]
enum Visitor {
    Table,
    Uuid,
    TimeOut,
}
