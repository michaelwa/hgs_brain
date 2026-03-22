defmodule HgsBrain.Ingestion do
  @moduledoc """
  Ingests markdown files into the knowledge base, scoped by segment.

  Each file is associated with a segment (`:work` or `:personal`), which maps
  to an arcana collection. Re-ingesting a file at the same path replaces its
  existing content.

  <!-- covers: hgs_brain.ingestion.accepts_markdown -->
  <!-- covers: hgs_brain.ingestion.segment_tagged -->
  <!-- covers: hgs_brain.ingestion.embedded -->
  <!-- covers: hgs_brain.ingestion.idempotent -->
  <!-- covers: hgs_brain.ingestion_health.status_recorded -->
  <!-- covers: hgs_brain.ingestion_health.last_successful_ingestion -->
  <!-- covers: hgs_brain.ingestion_health.failures_visible -->
  <!-- covers: hgs_brain.ingestion_health.source_change_detected -->
  <!-- covers: hgs_brain.ingestion_health.reprocessing_supported -->
  """

  import Ecto.Query

  alias HgsBrain.Repo
  alias HgsBrain.IngestionRecord
  alias Arcana.Document

  @arcana_client Application.compile_env(:hgs_brain, :arcana_client, Arcana)

  @type segment :: :work | :personal

  @doc """
  Ingests a markdown file into the given segment's knowledge base.

  If a document at the same file path has already been ingested into this
  segment, it is replaced.

  Returns `{:ok, document}` on success.
  """
  @spec ingest_file(Path.t(), segment()) :: {:ok, Arcana.Document.t()} | {:error, term()}
  def ingest_file(path, segment) when segment in [:work, :personal] do
    collection = collection_name(segment)

    result =
      with :ok <- delete_existing(path, collection) do
        @arcana_client.ingest_file(path, repo: Repo, collection: collection)
      end

    record_health(path, segment, result)
    result
  end

  @doc """
  Lists all ingested documents for a segment.
  """
  @spec list_documents(segment()) :: [Arcana.Document.t()]
  def list_documents(segment) when segment in [:work, :personal] do
    collection = collection_name(segment)

    from(d in Document,
      join: c in Arcana.Collection,
      on: d.collection_id == c.id,
      where: c.name == ^collection,
      order_by: [desc: d.inserted_at],
      select: d
    )
    |> Repo.all()
  end

  @doc """
  Deletes a document and all its embedded chunks by document ID.
  """
  @spec delete_document(binary()) :: :ok | {:error, :not_found}
  def delete_document(document_id) do
    @arcana_client.delete(document_id, repo: Repo)
  end

  defp delete_existing(path, collection) do
    from(d in Document,
      join: c in Arcana.Collection,
      on: d.collection_id == c.id,
      where: d.file_path == ^path and c.name == ^collection,
      select: d
    )
    |> Repo.all()
    |> Enum.each(fn doc -> @arcana_client.delete(doc.id, repo: Repo) end)

    :ok
  end

  @doc """
  Returns the ingestion health record for a specific source, or `nil` if none exists.
  """
  @spec ingestion_health(Path.t(), segment()) :: IngestionRecord.t() | nil
  def ingestion_health(path, segment) when segment in [:work, :personal] do
    Repo.get_by(IngestionRecord, file_path: path, segment: Atom.to_string(segment))
  end

  @doc """
  Returns `true` if the file at `path` has changed since its last successful ingestion
  into `segment`, or if no successful ingestion record exists.
  """
  @spec source_changed?(Path.t(), segment()) :: boolean()
  def source_changed?(path, segment) when segment in [:work, :personal] do
    case ingestion_health(path, segment) do
      %IngestionRecord{status: :ok, file_hash: stored_hash} when is_binary(stored_hash) ->
        current_hash(path) != stored_hash

      _ ->
        true
    end
  end

  defp record_health(path, segment, {:ok, _}) do
    attrs = %{
      file_path: path,
      segment: Atom.to_string(segment),
      status: :ok,
      error_reason: nil,
      file_hash: current_hash(path),
      ingested_at: DateTime.utc_now() |> DateTime.truncate(:second)
    }

    upsert_health(path, segment, attrs)
  end

  defp record_health(path, segment, {:error, reason}) do
    attrs = %{
      file_path: path,
      segment: Atom.to_string(segment),
      status: :error,
      error_reason: inspect(reason),
      file_hash: nil,
      ingested_at: nil
    }

    upsert_health(path, segment, attrs)
  end

  defp upsert_health(path, segment, attrs) do
    case Repo.get_by(IngestionRecord, file_path: path, segment: Atom.to_string(segment)) do
      nil ->
        %IngestionRecord{}
        |> IngestionRecord.changeset(attrs)
        |> Repo.insert!()

      record ->
        record
        |> IngestionRecord.changeset(attrs)
        |> Repo.update!()
    end
  end

  defp current_hash(path) do
    case File.read(path) do
      {:ok, content} -> :crypto.hash(:md5, content) |> Base.encode16(case: :lower)
      {:error, _} -> nil
    end
  end

  defp collection_name(:work), do: "work"
  defp collection_name(:personal), do: "personal"
end
