defmodule HgsBrain.Capture do
  use Ecto.Schema
  import Ecto.Changeset

  # covers: hgs_brain.capture_inbox.quick_capture
  # covers: hgs_brain.capture_inbox.segment_assigned
  # covers: hgs_brain.capture_inbox.inbox_state
  # covers: hgs_brain.capture_inbox.review_state_recorded
  # covers: hgs_brain.capture_inbox.origin_recorded
  # covers: hgs_brain.capture_inbox.timestamps_recorded
  # covers: hgs_brain.capture_inbox.display_ready
  # covers: hgs_brain.capture_inbox.retrievable_while_inbox

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "captures" do
    field :content, :string
    field :segment, :string
    field :status, Ecto.Enum, values: [:inbox, :reviewed], default: :inbox
    field :origin_type, :string, default: "quick_text"
    field :document_id, :binary_id

    timestamps()
  end

  def changeset(capture, attrs) do
    capture
    |> cast(attrs, [:content, :segment, :status, :origin_type, :document_id])
    |> validate_required([:content, :segment, :status, :origin_type])
    |> validate_length(:content, min: 1)
  end
end
