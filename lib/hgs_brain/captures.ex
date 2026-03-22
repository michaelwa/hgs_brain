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
  """

  import Ecto.Query

  alias HgsBrain.Repo
  alias HgsBrain.Capture

  @arcana_client Application.compile_env(:hgs_brain, :arcana_client, Arcana)

  @type segment :: :work | :personal

  @doc """
  Creates a capture from freeform text and ingests it into the segment's
  knowledge base so it participates in retrieval immediately.

  Returns `{:ok, capture}` on success or `{:error, changeset}` on validation failure.
  """
  @spec create_capture(String.t(), segment()) :: {:ok, Capture.t()} | {:error, Ecto.Changeset.t()}
  def create_capture(text, segment) when segment in [:work, :personal] and is_binary(text) do
    collection = collection_name(segment)

    attrs = %{
      content: text,
      segment: Atom.to_string(segment),
      status: :inbox,
      origin_type: "quick_text"
    }

    with {:ok, capture} <- insert_capture(attrs),
         {:ok, doc} <- @arcana_client.ingest(text, repo: Repo, collection: collection) do
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

  defp collection_name(:work), do: "work"
  defp collection_name(:personal), do: "personal"
end
