defmodule HgsBrain.Repo.Migrations.CreateCaptures do
  use Ecto.Migration

  def change do
    create table(:captures, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :content, :text, null: false
      add :segment, :string, null: false
      add :status, :string, null: false, default: "inbox"
      add :origin_type, :string, null: false, default: "quick_text"
      add :document_id, :binary_id

      timestamps()
    end

    create index(:captures, [:segment, :status])
  end
end
