defmodule HgsBrain.Repo.Migrations.AddSourceMetadataToIngestionRecords do
  use Ecto.Migration

  def change do
    alter table(:ingestion_records) do
      add :title, :string
      add :document_id, :binary_id
      add :frontmatter, :map
    end
  end
end
