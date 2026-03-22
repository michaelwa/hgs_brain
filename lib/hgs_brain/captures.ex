defmodule HgsBrain.Captures do
  @moduledoc """
  Context for managing captures — lightweight knowledge items that enter an
  inbox state before further organization.

  <!-- covers: hgs_brain.capture_inbox.quick_capture -->
  <!-- covers: hgs_brain.capture_inbox.segment_assigned -->
  <!-- covers: hgs_brain.capture_inbox.inbox_state -->
  <!-- covers: hgs_brain.capture_inbox.review_state_recorded -->
  <!-- covers: hgs_brain.capture_inbox.origin_recorded -->
  <!-- covers: hgs_brain.capture_inbox.timestamps_recorded -->
  <!-- covers: hgs_brain.capture_inbox.display_ready -->
  <!-- covers: hgs_brain.capture_inbox.retrievable_while_inbox -->
  <!-- covers: hgs_brain.knowledge_source_ingestion.multiple_source_types -->
  <!-- covers: hgs_brain.knowledge_source_ingestion.normalized_source_record -->
  <!-- covers: hgs_brain.knowledge_source_ingestion.segment_preserved -->
  <!-- covers: hgs_brain.knowledge_source_ingestion.extracts_ingestible_content -->
  <!-- covers: hgs_brain.knowledge_source_ingestion.retrieval_eligibility -->
  <!-- covers: hgs_brain.knowledge_source_ingestion.processing_failure_visible -->
  """

  import Ecto.Query

  alias HgsBrain.Repo
  alias HgsBrain.Capture
  alias HgsBrain.KnowledgeSource

  @arcana_client Application.compile_env(:hgs_brain, :arcana_client, Arcana)

  @type segment :: :work | :personal

  @doc """
  Creates a capture from freeform text and ingests it into the segment's
  knowledge base so it participates in retrieval immediately.

  Returns `{:ok, capture}` on success or `{:error, changeset}` on validation failure.
  """
  @spec create_capture(String.t(), segment()) :: {:ok, Capture.t()} | {:error, Ecto.Changeset.t()}
  def create_capture(text, segment) when segment in [:work, :personal] and is_binary(text) do
    source = KnowledgeSource.from_capture(text, segment)
    collection = source.segment

    attrs = %{
      content: source.content,
      segment: source.segment,
      status: :inbox,
      origin_type: source.origin_type
    }

    with {:ok, capture} <- insert_capture(attrs),
         {:ok, doc} <- @arcana_client.ingest(source.content, repo: Repo, collection: collection) do
      capture
      |> Capture.changeset(%{document_id: Map.get(doc, :id)})
      |> Repo.update()
    end
  end

  @doc """
  Lists all inbox captures for a segment, ordered newest first.
  """
  @spec list_inbox(segment()) :: [Capture.t()]
  def list_inbox(segment) when segment in [:work, :personal] do
    seg = Atom.to_string(segment)

    from(c in Capture,
      where: c.segment == ^seg and c.status == :inbox,
      order_by: [desc: c.inserted_at]
    )
    |> Repo.all()
  end

  @doc """
  Marks a capture as reviewed.
  """
  @spec mark_reviewed(Capture.t()) :: {:ok, Capture.t()} | {:error, Ecto.Changeset.t()}
  def mark_reviewed(%Capture{} = capture) do
    capture
    |> Capture.changeset(%{status: :reviewed})
    |> Repo.update()
  end

  defp insert_capture(attrs) do
    %Capture{}
    |> Capture.changeset(attrs)
    |> Repo.insert()
  end
end
