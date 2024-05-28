use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        manager
            .create_table(
                Table::create()
                    .table(User::Table)
                    .if_not_exists()
                    .col(
                        ColumnDef::new(User::Id)
                            .integer()
                            .not_null()
                            .auto_increment()
                            .primary_key()
                    )
                    .col(
                        ColumnDef::new(User::Name)
                            .string()
                            .not_null()
                            .char_len(255)
                    )
                    .col(
                        ColumnDef::new(User::LastName)
                            .string()
                            .not_null()
                            .text()
                    )
                    .col(
                        ColumnDef::new(User::Email)
                            .string()
                    )
                    .col(
                        ColumnDef::new(User::Password)
                            .binary()
                            .not_null()
                    )
                    .to_owned(),
            )
            .await
    }

    async fn down(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        manager
            .drop_table(Table::drop()
                .if_exists()
                .table(User::Table).to_owned()
            )
            .await
    }
}

#[derive(DeriveIden)]
enum User {
    Table,
    Id,
    Name,
    LastName,
    Email,
    Password,
}
