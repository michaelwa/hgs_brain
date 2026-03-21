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
  """

  import Ecto.Query

  alias HgsBrain.Repo
  alias Arcana.Document

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

    with :ok <- delete_existing(path, collection) do
      Arcana.ingest_file(path, repo: Repo, collection: collection)
    end
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
    Arcana.delete(document_id, repo: Repo)
  end

  defp delete_existing(path, collection) do
    from(d in Document,
      join: c in Arcana.Collection,
      on: d.collection_id == c.id,
      where: d.file_path == ^path and c.name == ^collection,
      select: d
    )
    |> Repo.all()
    |> Enum.each(fn doc -> Arcana.delete(doc.id, repo: Repo) end)

    :ok
  end

  defp collection_name(:work), do: "work"
  defp collection_name(:personal), do: "personal"
end
