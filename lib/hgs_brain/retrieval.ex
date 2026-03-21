defmodule HgsBrain.Retrieval do
  @moduledoc """
  Retrieves answers from the knowledge base using RAG, scoped by segment.

  Queries are always filtered to a single segment so work and personal
  knowledge never mix.

  <!-- covers: hgs_brain.retrieval.accepts_query -->
  <!-- covers: hgs_brain.retrieval.scoped -->
  <!-- covers: hgs_brain.retrieval.rag_answer -->
  """

  alias HgsBrain.Repo

  @arcana_client Application.compile_env(:hgs_brain, :arcana_client, Arcana)

  @type segment :: :work | :personal

  @doc """
  Asks a natural language question against the given segment's knowledge base.

  Returns `{:ok, answer, context_chunks}` on success, where `context_chunks`
  is the list of retrieved passages used to generate the answer.
  """
  @spec ask(String.t(), segment()) :: {:ok, String.t(), list()} | {:error, term()}
  def ask(question, segment) when is_binary(question) and segment in [:work, :personal] do
    @arcana_client.ask(question,
      repo: Repo,
      collection: collection_name(segment)
    )
  end

  @doc """
  Performs a semantic search without LLM generation.

  Useful for surfacing source passages directly. Returns a list of chunk maps
  with `:text` and `:score` keys, scoped to the given segment.
  """
  @spec search(String.t(), segment(), keyword()) :: list()
  def search(query, segment, opts \\ [])
      when is_binary(query) and segment in [:work, :personal] do
    @arcana_client.search(query,
      Keyword.merge(opts,
        repo: Repo,
        collection: collection_name(segment)
      )
    )
  end

  defp collection_name(:work), do: "work"
  defp collection_name(:personal), do: "personal"
end
