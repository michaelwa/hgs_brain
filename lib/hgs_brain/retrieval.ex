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
  <!-- covers: hgs_brain.retrieval_review_scope.include_inbox -->
  <!-- covers: hgs_brain.retrieval_review_scope.reviewed_only -->
  <!-- covers: hgs_brain.retrieval_review_scope.ask_respected -->
  <!-- covers: hgs_brain.retrieval_review_scope.search_respected -->
  <!-- covers: hgs_brain.retrieval_review_scope.source_state_available -->
  """

  import Ecto.Query

  alias Arcana.Document
  alias HgsBrain.Capture
  alias HgsBrain.Repo

  @arcana_client Application.compile_env(:hgs_brain, :arcana_client, Arcana)

  @type segment :: :work | :personal
  @type review_scope :: :reviewed_only | :include_inbox

  @type source :: %{
          text: String.t(),
          source: String.t() | nil,
          segment: segment(),
          score: float() | nil,
          chunk_index: non_neg_integer() | nil,
          document_id: String.t() | nil,
          review_state: :reviewed | :inbox
        }

  @doc """
  Asks a natural language question against the given segment's knowledge base.

  Accepts a `review_scope` option (`:reviewed_only` | `:include_inbox`).
  Defaults to `:include_inbox` when not specified.

  Returns `{:ok, answer, sources}` on success.
  """
  @spec ask(String.t(), segment(), keyword()) ::
          {:ok, String.t(), list(source())} | {:error, term()}
  def ask(question, segment, opts \\ [])
      when is_binary(question) and segment in [:work, :personal] do
    review_scope = Keyword.get(opts, :review_scope, :include_inbox)

    case @arcana_client.ask(question,
           repo: Repo,
           collection: collection_name(segment)
         ) do
      {:ok, answer, chunks} ->
        sources =
          chunks
          |> enrich_sources(segment)
          |> apply_review_scope(review_scope)

        {:ok, answer, sources}

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Performs a semantic search without LLM generation.

  Accepts a `review_scope` option (`:reviewed_only` | `:include_inbox`).
  Defaults to `:include_inbox` when not specified.

  Returns a list of enriched source maps scoped to the given segment.
  """
  @spec search(String.t(), segment(), keyword()) :: list(source())
  def search(query, segment, opts \\ [])
      when is_binary(query) and segment in [:work, :personal] do
    review_scope = Keyword.get(opts, :review_scope, :include_inbox)

    chunks =
      @arcana_client.search(
        query,
        Keyword.merge(Keyword.delete(opts, :review_scope),
          repo: Repo,
          collection: collection_name(segment)
        )
      )

    chunks
    |> enrich_sources(segment)
    |> apply_review_scope(review_scope)
  end

  defp collection_name(:work), do: "work"
  defp collection_name(:personal), do: "personal"

  defp enrich_sources([], _segment), do: []

  defp enrich_sources(chunks, segment) do
    file_paths = fetch_file_paths(chunks)
    inbox_ids = fetch_inbox_doc_ids(chunks)

    chunks
    |> Enum.map(fn chunk ->
      doc_id = Map.get(chunk, :document_id)

      %{
        text: Map.get(chunk, :text, ""),
        source: Map.get(file_paths, doc_id),
        segment: segment,
        score: Map.get(chunk, :score),
        chunk_index: Map.get(chunk, :chunk_index),
        document_id: doc_id,
        review_state: if(doc_id in inbox_ids, do: :inbox, else: :reviewed)
      }
    end)
    |> Enum.sort_by(& &1.score, fn
      nil, nil -> true
      nil, _ -> false
      _, nil -> true
      a, b -> a >= b
    end)
  end

  defp apply_review_scope(sources, :include_inbox), do: sources

  defp apply_review_scope(sources, :reviewed_only) do
    Enum.reject(sources, &(&1.review_state == :inbox))
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

  defp fetch_inbox_doc_ids(chunks) do
    ids =
      chunks
      |> Enum.map(&Map.get(&1, :document_id))
      |> Enum.reject(&is_nil/1)

    case ids do
      [] ->
        MapSet.new()

      ids ->
        from(c in Capture,
          where: c.document_id in ^ids and c.status == :inbox,
          select: c.document_id
        )
        |> Repo.all()
        |> MapSet.new()
    end
  end
end
