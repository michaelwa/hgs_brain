defmodule HgsBrain.IngestionRecord do
  use Ecto.Schema
  import Ecto.Changeset

  # covers: hgs_brain.ingestion_health.status_recorded
  # covers: hgs_brain.ingestion_health.last_successful_ingestion
  # covers: hgs_brain.ingestion_health.failures_visible
  # covers: hgs_brain.ingestion_health.source_change_detected
  # covers: hgs_brain.ingestion_health.reprocessing_supported
  # covers: hgs_brain.ingestion_source_metadata.origin_metadata
  # covers: hgs_brain.ingestion_source_metadata.display_name
  # covers: hgs_brain.ingestion_source_metadata.segment_recorded
  # covers: hgs_brain.ingestion_source_metadata.timestamps_recorded
  # covers: hgs_brain.ingestion_source_metadata.content_fingerprint
  # covers: hgs_brain.ingestion_source_metadata.source_chunk_separation
  # covers: hgs_brain.ingestion_source_metadata.frontmatter_preserved

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "ingestion_records" do
    field :file_path, :string
    field :segment, :string
    field :status, Ecto.Enum, values: [:ok, :error]
    field :error_reason, :string
    field :file_hash, :string
    field :ingested_at, :utc_datetime
    field :title, :string
    field :document_id, :binary_id
    field :frontmatter, :map

    timestamps()
  end

  def changeset(record, attrs) do
    record
    |> cast(attrs, [
      :file_path,
      :segment,
      :status,
      :error_reason,
      :file_hash,
      :ingested_at,
      :title,
      :document_id,
      :frontmatter
    ])
    |> validate_required([:file_path, :segment, :status])
    |> unique_constraint([:file_path, :segment])
  end
end
