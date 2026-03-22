defmodule HgsBrain.Repo.Migrations.CreateIngestionRecords do
  use Ecto.Migration

  def change do
    create table(:ingestion_records, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :file_path, :string, null: false
      add :segment, :string, null: false
      add :status, :string, null: false
      add :error_reason, :text
      add :file_hash, :string
      add :ingested_at, :utc_datetime

      timestamps()
    end

    create unique_index(:ingestion_records, [:file_path, :segment])
  end
end
