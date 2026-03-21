defmodule HgsBrain.Retrieval do
  @moduledoc """
  Retrieves answers from the knowledge base using RAG, scoped by segment.

  Queries are always filtered to a single segment so work and personal
  knowledge never mix.

  <!-- covers: hgs_brain.retrieval.accepts_query -->
  <!-- covers: hgs_brain.retrieval.scoped -->
  <!-- covers: hgs_brain.retrieval.rag_answer -->
  <!-- covers: hgs_brain.retrieval.enriched_sources -->
  <!-- covers: hgs_brain.source_transparency.source_metadata -->
  <!-- covers: hgs_brain.source_transparency.source_excerpt -->
  <!-- covers: hgs_brain.source_transparency.multiple_sources -->
  <!-- covers: hgs_brain.source_transparency.relevance_signal -->
  """

  import Ecto.Query

  alias Arcana.Document
  alias HgsBrain.Repo

  @arcana_client Application.compile_env(:hgs_brain, :arcana_client, Arcana)

  @type segment :: :work | :personal

  @type source :: %{
          text: String.t(),
          source: String.t() | nil,
          segment: segment(),
          score: float() | nil,
          chunk_index: non_neg_integer() | nil,
          document_id: String.t() | nil
        }

  @doc """
  Asks a natural language question against the given segment's knowledge base.

  Returns `{:ok, answer, sources}` on success, where `sources` is a list of
  enriched source maps containing the passage text, origin file path, segment,
  relevance score, and chunk position.
  """
  @spec ask(String.t(), segment()) :: {:ok, String.t(), list(source())} | {:error, term()}
  def ask(question, segment) when is_binary(question) and segment in [:work, :personal] do
    case @arcana_client.ask(question,
           repo: Repo,
           collection: collection_name(segment)
         ) do
      {:ok, answer, chunks} -> {:ok, answer, enrich_sources(chunks, segment)}
      {:error, _} = error -> error
    end
  end

  @doc """
  Performs a semantic search without LLM generation.

  Returns a list of enriched source maps with passage text, origin file path,
  segment, relevance score, and chunk position, scoped to the given segment.
  """
  @spec search(String.t(), segment(), keyword()) :: list(source())
  def search(query, segment, opts \\ [])
      when is_binary(query) and segment in [:work, :personal] do
    chunks =
      @arcana_client.search(
        query,
        Keyword.merge(opts,
          repo: Repo,
          collection: collection_name(segment)
        )
      )

    enrich_sources(chunks, segment)
  end

  defp collection_name(:work), do: "work"
  defp collection_name(:personal), do: "personal"

  defp enrich_sources([], _segment), do: []

  defp enrich_sources(chunks, segment) do
    file_paths = fetch_file_paths(chunks)

    Enum.map(chunks, fn chunk ->
      %{
        text: Map.get(chunk, :text, ""),
        source: Map.get(file_paths, Map.get(chunk, :document_id)),
        segment: segment,
        score: Map.get(chunk, :score),
        chunk_index: Map.get(chunk, :chunk_index),
        document_id: Map.get(chunk, :document_id)
      }
    end)
  end

  defp fetch_file_paths(chunks) do
    ids =
      chunks
      |> Enum.map(&Map.get(&1, :document_id))
      |> Enum.reject(&is_nil/1)

    case ids do
      [] ->
        %{}

      ids ->
        Repo.all(from d in Document, where: d.id in ^ids, select: {d.id, d.file_path})
        |> Map.new()
    end
  end
end
