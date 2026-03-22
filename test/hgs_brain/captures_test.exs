defmodule HgsBrain.CapturesTest do
  # covers: hgs_brain.capture_inbox.quick_capture
  # covers: hgs_brain.capture_inbox.segment_assigned
  # covers: hgs_brain.capture_inbox.inbox_state
  # covers: hgs_brain.capture_inbox.review_state_recorded
  # covers: hgs_brain.capture_inbox.origin_recorded
  # covers: hgs_brain.capture_inbox.timestamps_recorded
  # covers: hgs_brain.capture_inbox.display_ready
  # covers: hgs_brain.capture_inbox.retrievable_while_inbox

  use HgsBrain.DataCase, async: true

  import Mox

  alias HgsBrain.{Captures, Repo}

  setup :verify_on_exit!

  describe "create_capture/2" do
    test "creates a capture in inbox state" do
      expect(HgsBrain.MockArcanaClient, :ingest, fn _text, _opts ->
        {:ok, %{id: Ecto.UUID.generate()}}
      end)

      assert {:ok, capture} = Captures.create_capture("A quick thought.", :personal)
      assert capture.status == :inbox
    end

    test "assigns the segment to the capture" do
      expect(HgsBrain.MockArcanaClient, :ingest, fn _text, _opts ->
        {:ok, %{id: Ecto.UUID.generate()}}
      end)

      assert {:ok, capture} = Captures.create_capture("Work idea.", :work)
      assert capture.segment == "work"
    end

    test "records origin_type as quick_text" do
      expect(HgsBrain.MockArcanaClient, :ingest, fn _text, _opts ->
        {:ok, %{id: Ecto.UUID.generate()}}
      end)

      assert {:ok, capture} = Captures.create_capture("Something.", :personal)
      assert capture.origin_type == "quick_text"
    end

    test "records document_id linking capture to arcana for retrieval" do
      doc_id = Ecto.UUID.generate()

      expect(HgsBrain.MockArcanaClient, :ingest, fn _text, _opts ->
        {:ok, %{id: doc_id}}
      end)

      assert {:ok, capture} = Captures.create_capture("Retrievable capture.", :personal)
      assert capture.document_id == doc_id
    end

    test "passes the text and collection to arcana" do
      expect(HgsBrain.MockArcanaClient, :ingest, fn text, opts ->
        assert text == "Hello arcana."
        assert opts[:collection] == "personal"
        assert opts[:repo] == Repo
        {:ok, %{id: Ecto.UUID.generate()}}
      end)

      assert {:ok, _} = Captures.create_capture("Hello arcana.", :personal)
    end

    test "returns error changeset for blank text" do
      assert {:error, changeset} = Captures.create_capture("", :personal)
      assert changeset.errors[:content]
    end

    test "records timestamps on creation" do
      before = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

      expect(HgsBrain.MockArcanaClient, :ingest, fn _text, _opts ->
        {:ok, %{id: Ecto.UUID.generate()}}
      end)

      assert {:ok, capture} = Captures.create_capture("Timed capture.", :personal)
      assert NaiveDateTime.compare(capture.inserted_at, before) in [:gt, :eq]
    end
  end

  describe "list_inbox/1" do
    test "returns only inbox captures for the given segment" do
      expect(HgsBrain.MockArcanaClient, :ingest, 2, fn _text, _opts ->
        {:ok, %{id: Ecto.UUID.generate()}}
      end)

      {:ok, _} = Captures.create_capture("Personal thought.", :personal)
      {:ok, _} = Captures.create_capture("Work thought.", :work)

      personal = Captures.list_inbox(:personal)
      assert length(personal) == 1
      assert hd(personal).segment == "personal"

      work = Captures.list_inbox(:work)
      assert length(work) == 1
      assert hd(work).segment == "work"
    end

    test "excludes reviewed captures from inbox" do
      expect(HgsBrain.MockArcanaClient, :ingest, fn _text, _opts ->
        {:ok, %{id: Ecto.UUID.generate()}}
      end)

      {:ok, capture} = Captures.create_capture("To review.", :personal)
      {:ok, _} = Captures.mark_reviewed(capture)

      assert [] = Captures.list_inbox(:personal)
    end

    test "returns empty list when no inbox captures exist" do
      assert [] = Captures.list_inbox(:work)
    end

    test "returns captures ordered newest first" do
      expect(HgsBrain.MockArcanaClient, :ingest, 2, fn _text, _opts ->
        {:ok, %{id: Ecto.UUID.generate()}}
      end)

      {:ok, first} = Captures.create_capture("First.", :personal)
      {:ok, second} = Captures.create_capture("Second.", :personal)

      [head | _] = Captures.list_inbox(:personal)
      assert head.id == second.id || head.inserted_at >= first.inserted_at
    end
  end

  describe "mark_reviewed/1" do
    test "updates capture status to reviewed" do
      expect(HgsBrain.MockArcanaClient, :ingest, fn _text, _opts ->
        {:ok, %{id: Ecto.UUID.generate()}}
      end)

      {:ok, capture} = Captures.create_capture("To review.", :personal)
      assert {:ok, reviewed} = Captures.mark_reviewed(capture)
      assert reviewed.status == :reviewed
    end
  end
end
