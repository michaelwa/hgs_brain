defmodule HgsBrain.Resurfacing do
  @moduledoc """
  Surfaces relevant knowledge items for review without requiring explicit queries.

  Provides recent, revisit-worthy, and contextually related items to complement
  explicit ask and search workflows.

  <!-- covers: hgs_brain.review_resurfacing.recent_items -->
  <!-- covers: hgs_brain.review_resurfacing.related_items -->
  <!-- covers: hgs_brain.review_resurfacing.revisit_items -->
  <!-- covers: hgs_brain.review_resurfacing.source_state_visible -->
  """

  import Ecto.Query

  alias HgsBrain.{Capture, Repo, Retrieval}

  @type segment :: :work | :personal

  @recent_days 7
  @default_limit 5

  @doc """
  Returns the most recently added captures for the given segment.

  Returns captures inserted within the last #{@recent_days} days, newest first.
  All statuses are included so the user can review captures in any state.
  """
  @spec recent_items(segment(), keyword()) :: [Capture.t()]
  def recent_items(segment, opts \\ []) when segment in [:work, :personal] do
    limit = Keyword.get(opts, :limit, @default_limit)
    cutoff = NaiveDateTime.add(NaiveDateTime.utc_now(), -@recent_days * 86_400)
    seg = Atom.to_string(segment)

    from(c in Capture,
      where: c.segment == ^seg and c.inserted_at >= ^cutoff,
      order_by: [desc: c.inserted_at],
      limit: ^limit
    )
    |> Repo.all()
  end

  @doc """
  Returns older captures worth revisiting for the given segment.

  Returns captures inserted more than #{@recent_days} days ago, oldest first.
  Surfaces items that may have been overlooked or are worth re-evaluating.
  """
  @spec revisit_items(segment(), keyword()) :: [Capture.t()]
  def revisit_items(segment, opts \\ []) when segment in [:work, :personal] do
    limit = Keyword.get(opts, :limit, @default_limit)
    cutoff = NaiveDateTime.add(NaiveDateTime.utc_now(), -@recent_days * 86_400)
    seg = Atom.to_string(segment)

    from(c in Capture,
      where: c.segment == ^seg and c.inserted_at < ^cutoff,
      order_by: [asc: c.inserted_at],
      limit: ^limit
    )
    |> Repo.all()
  end

  @doc """
  Returns knowledge items semantically related to the given context text.

  Defaults to `:include_inbox` review scope so inbox captures participate
  in related-item surfacing, matching the inbox-refinement workflow intent.
  """
  @spec related_items(String.t(), segment(), keyword()) :: list()
  def related_items(text, segment, opts \\ [])
      when is_binary(text) and segment in [:work, :personal] do
    review_scope = Keyword.get(opts, :review_scope, :include_inbox)
    limit = Keyword.get(opts, :limit, @default_limit)

    Retrieval.search(text, segment, review_scope: review_scope)
    |> Enum.take(limit)
  end
end
