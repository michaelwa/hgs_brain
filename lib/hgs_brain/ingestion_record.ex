defmodule HgsBrain.IngestionRecord do
  use Ecto.Schema
  import Ecto.Changeset

  # covers: hgs_brain.ingestion_health.status_recorded
  # covers: hgs_brain.ingestion_health.last_successful_ingestion
  # covers: hgs_brain.ingestion_health.failures_visible
  # covers: hgs_brain.ingestion_health.source_change_detected
  # covers: hgs_brain.ingestion_health.reprocessing_supported

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "ingestion_records" do
    field :file_path, :string
    field :segment, :string
    field :status, Ecto.Enum, values: [:ok, :error]
    field :error_reason, :string
    field :file_hash, :string
    field :ingested_at, :utc_datetime

    timestamps()
  end

  def changeset(record, attrs) do
    record
    |> cast(attrs, [:file_path, :segment, :status, :error_reason, :file_hash, :ingested_at])
    |> validate_required([:file_path, :segment, :status])
    |> unique_constraint([:file_path, :segment])
  end
end
