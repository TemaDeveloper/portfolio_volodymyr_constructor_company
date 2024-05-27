use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        // Replace the sample below with your own migration scripts
        return Ok(());

        manager
            .create_table(
                Table::create()
                    .table(User::Table)
                    .if_not_exists()
                    .col(
                        ColumnDef::new(User::Name)
                            .not_null()
                            .char_len(255)
                    )
                    .col(
                        ColumnDef::new(User::LastName)
                            .not_null()
                            .char_len(255)
                    )
                    .col(
                        ColumnDef::new(User::Email)
                            .not_null()
                            .char_len(255)
                    )
                    .col(
                        ColumnDef::new(User::Password)
                            .not_null()
                            .binary()
                    )
                    .to_owned(),
            )
            .await
    }

    async fn down(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        return Ok(());

        manager
            .drop_table(Table::drop().table(User::Table).to_owned())
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
