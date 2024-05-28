use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        manager
            .create_table(
                Table::create()
                    .table(Projects::Table)
                    .if_not_exists()
                    .col(
                        ColumnDef::new(Projects::Id)
                            .integer()
                            .auto_increment()
                            .primary_key()
                            .not_null()
                    )
                    .col(
                        ColumnDef::new(Projects::Name)
                            .not_null()
                            .char_len(255)
                    )
                    .col(
                        ColumnDef::new(Projects::Description)
                            .not_null()
                            .text()
                    )
                    .col(
                        ColumnDef::new(Projects::Pictures)
                            .not_null()
                            .array(ColumnType::Text)
                    )
                    .col(
                        ColumnDef::new(Projects::Year)
                            .not_null()
                            .integer()
                    )
                    .col(
                        ColumnDef::new(Projects::Country)
                            .char_len(512) // should be enough for any countrie's name
                            .not_null()
                    )
                    .col(
                        ColumnDef::new(Projects::Latitude)
                            .not_null()
                            .double()
                    )
                    .col(
                        ColumnDef::new(Projects::Longitude)
                            .not_null()
                            .double()
                    )
                    .to_owned(),
            )
            .await
    }

    async fn down(&self, manager: &SchemaManager) -> Result<(), DbErr> {

        manager
            .drop_table(Table::drop()
                .if_exists()
                .table(Projects::Table).to_owned()
            )
            .await
    }
}

#[derive(DeriveIden)]
enum Projects {
    Table, 
    Id, 
    Name, 
    Description,
    Pictures,
    Year,
    Country,
    Latitude,
    Longitude
}
