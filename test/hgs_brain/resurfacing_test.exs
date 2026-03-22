defmodule HgsBrain.ResurfacingTest do
  # covers: hgs_brain.review_resurfacing.recent_items
  # covers: hgs_brain.review_resurfacing.related_items
  # covers: hgs_brain.review_resurfacing.revisit_items
  # covers: hgs_brain.review_resurfacing.source_state_visible

  use HgsBrain.DataCase, async: true

  import Mox

  alias HgsBrain.{Capture, Repo, Resurfacing}

  setup :verify_on_exit!

  defp insert_capture(opts \\ []) do
    Repo.insert!(%Capture{
      content: Keyword.get(opts, :content, "Some content."),
      segment: Keyword.get(opts, :segment, "personal"),
      status: Keyword.get(opts, :status, :inbox),
      origin_type: "quick_text"
    })
  end

  defp set_inserted_at(capture, naive_datetime) do
    Repo.update_all(
      from(c in Capture, where: c.id == ^capture.id),
      set: [inserted_at: naive_datetime]
    )

    Repo.get!(Capture, capture.id)
  end

  describe "recent_items/2" do
    test "returns captures inserted within the last 7 days" do
      recent = insert_capture()
      assert recent.id in Enum.map(Resurfacing.recent_items(:personal), & &1.id)
    end

    test "excludes captures older than 7 days" do
      old = insert_capture()
      old_date = NaiveDateTime.add(NaiveDateTime.utc_now(), -8 * 86_400)
      set_inserted_at(old, old_date)

      ids = Enum.map(Resurfacing.recent_items(:personal), & &1.id)
      refute old.id in ids
    end

    test "scopes results to the given segment" do
      personal = insert_capture(segment: "personal")
      _work = insert_capture(segment: "work")

      ids = Enum.map(Resurfacing.recent_items(:personal), & &1.id)
      assert personal.id in ids
      refute Enum.any?(Resurfacing.recent_items(:personal), &(&1.segment == "work"))
    end

    test "returns captures ordered newest first" do
      older = insert_capture()
      newer = insert_capture()

      older_date = NaiveDateTime.add(NaiveDateTime.utc_now(), -3 * 86_400)
      set_inserted_at(older, older_date)

      items = Resurfacing.recent_items(:personal)
      positions = Enum.map(items, & &1.id)

      assert Enum.find_index(positions, &(&1 == newer.id)) <
               Enum.find_index(positions, &(&1 == older.id))
    end

    test "source_state_visible: returned captures carry content, status, segment, and inserted_at" do
      insert_capture(content: "Review me.", status: :inbox)

      item = hd(Resurfacing.recent_items(:personal))
      assert item.content == "Review me."
      assert item.status == :inbox
      assert item.segment == "personal"
      assert %NaiveDateTime{} = item.inserted_at
    end
  end

  describe "revisit_items/2" do
    test "returns captures older than 7 days" do
      old = insert_capture()
      old_date = NaiveDateTime.add(NaiveDateTime.utc_now(), -10 * 86_400)
      old = set_inserted_at(old, old_date)

      ids = Enum.map(Resurfacing.revisit_items(:personal), & &1.id)
      assert old.id in ids
    end

    test "excludes captures from the last 7 days" do
      recent = insert_capture()

      ids = Enum.map(Resurfacing.revisit_items(:personal), & &1.id)
      refute recent.id in ids
    end

    test "scopes results to the given segment" do
      old_personal = insert_capture(segment: "personal")
      old_date = NaiveDateTime.add(NaiveDateTime.utc_now(), -10 * 86_400)
      set_inserted_at(old_personal, old_date)

      refute Enum.any?(Resurfacing.revisit_items(:work), &(&1.segment == "personal"))
    end

    test "source_state_visible: returned captures carry content, status, and inserted_at" do
      old = insert_capture(content: "Old thought.")
      old_date = NaiveDateTime.add(NaiveDateTime.utc_now(), -10 * 86_400)
      set_inserted_at(old, old_date)

      item = hd(Resurfacing.revisit_items(:personal))
      assert item.content == "Old thought."
      assert %NaiveDateTime{} = item.inserted_at
    end
  end

  describe "related_items/3" do
    test "returns search results for the given text and segment" do
      doc_id = Ecto.UUID.generate()

      expect(HgsBrain.MockArcanaClient, :search, fn _q, _opts ->
        [%{text: "Related content.", score: 0.9, chunk_index: 0, document_id: doc_id}]
      end)

      results = Resurfacing.related_items("context text", :personal)
      assert length(results) == 1
      assert hd(results).text == "Related content."
    end

    test "passes include_inbox review scope by default" do
      expect(HgsBrain.MockArcanaClient, :search, fn _q, opts ->
        refute Keyword.get(opts, :review_scope) == :reviewed_only
        []
      end)

      Resurfacing.related_items("some context", :personal)
    end

    test "accepts a custom review_scope option without error" do
      expect(HgsBrain.MockArcanaClient, :search, fn _q, _opts -> [] end)

      result = Resurfacing.related_items("some context", :personal, review_scope: :reviewed_only)
      assert is_list(result)
    end

    test "limits results to default limit" do
      chunks =
        Enum.map(1..10, fn i ->
          %{text: "Item #{i}.", score: 1.0 / i, chunk_index: 0, document_id: Ecto.UUID.generate()}
        end)

      expect(HgsBrain.MockArcanaClient, :search, fn _q, _opts -> chunks end)

      results = Resurfacing.related_items("context", :personal)
      assert length(results) <= 5
    end

    test "source_state_visible: related sources carry review_state, segment, and excerpt" do
      doc_id = Ecto.UUID.generate()

      expect(HgsBrain.MockArcanaClient, :search, fn _q, _opts ->
        [%{text: "Excerpt.", score: 0.8, chunk_index: 0, document_id: doc_id}]
      end)

      [source] = Resurfacing.related_items("context", :personal)
      assert source.text == "Excerpt."
      assert source.segment == :personal
      assert source.review_state in [:inbox, :reviewed]
    end
  end
end
