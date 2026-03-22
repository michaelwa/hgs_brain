defmodule HgsBrain.RetrievalReviewScopeTest do
  # covers: hgs_brain.retrieval_review_scope.include_inbox
  # covers: hgs_brain.retrieval_review_scope.reviewed_only
  # covers: hgs_brain.retrieval_review_scope.ask_respected
  # covers: hgs_brain.retrieval_review_scope.search_respected
  # covers: hgs_brain.retrieval_review_scope.source_state_available

  use HgsBrain.DataCase, async: true

  import Mox

  alias HgsBrain.{Capture, Retrieval, Repo}

  setup :verify_on_exit!

  defp inbox_capture(doc_id) do
    Repo.insert!(%Capture{
      content: "An inbox capture.",
      segment: "personal",
      status: :inbox,
      origin_type: "quick_text",
      document_id: doc_id
    })
  end

  defp reviewed_capture(doc_id) do
    Repo.insert!(%Capture{
      content: "A reviewed capture.",
      segment: "personal",
      status: :reviewed,
      origin_type: "quick_text",
      document_id: doc_id
    })
  end

  describe "ask/3 with review_scope" do
    test "includes inbox sources when scope is include_inbox" do
      inbox_doc_id = Ecto.UUID.generate()
      inbox_capture(inbox_doc_id)

      chunk = %{text: "Inbox content.", score: 0.9, chunk_index: 0, document_id: inbox_doc_id}

      expect(HgsBrain.MockArcanaClient, :ask, fn _q, _opts ->
        {:ok, "Answer.", [chunk]}
      end)

      assert {:ok, "Answer.", sources} =
               Retrieval.ask("question", :personal, review_scope: :include_inbox)

      assert length(sources) == 1
      assert hd(sources).review_state == :inbox
    end

    test "excludes inbox sources when scope is reviewed_only" do
      inbox_doc_id = Ecto.UUID.generate()
      inbox_capture(inbox_doc_id)

      chunk = %{text: "Inbox content.", score: 0.9, chunk_index: 0, document_id: inbox_doc_id}

      expect(HgsBrain.MockArcanaClient, :ask, fn _q, _opts ->
        {:ok, "Answer.", [chunk]}
      end)

      assert {:ok, "Answer.", sources} =
               Retrieval.ask("question", :personal, review_scope: :reviewed_only)

      assert sources == []
    end

    test "keeps reviewed captures with reviewed_only scope" do
      reviewed_doc_id = Ecto.UUID.generate()
      reviewed_capture(reviewed_doc_id)

      chunk = %{
        text: "Reviewed content.",
        score: 0.9,
        chunk_index: 0,
        document_id: reviewed_doc_id
      }

      expect(HgsBrain.MockArcanaClient, :ask, fn _q, _opts ->
        {:ok, "Answer.", [chunk]}
      end)

      assert {:ok, "Answer.", sources} =
               Retrieval.ask("question", :personal, review_scope: :reviewed_only)

      assert length(sources) == 1
      assert hd(sources).review_state == :reviewed
    end

    test "filters only inbox sources, keeps reviewed sources in mixed results" do
      inbox_doc_id = Ecto.UUID.generate()
      reviewed_doc_id = Ecto.UUID.generate()
      inbox_capture(inbox_doc_id)
      reviewed_capture(reviewed_doc_id)

      chunks = [
        %{text: "Inbox.", score: 0.95, chunk_index: 0, document_id: inbox_doc_id},
        %{text: "Reviewed.", score: 0.80, chunk_index: 0, document_id: reviewed_doc_id}
      ]

      expect(HgsBrain.MockArcanaClient, :ask, fn _q, _opts ->
        {:ok, "Answer.", chunks}
      end)

      assert {:ok, "Answer.", sources} =
               Retrieval.ask("question", :personal, review_scope: :reviewed_only)

      assert length(sources) == 1
      assert hd(sources).text == "Reviewed."
    end

    test "file sources (no capture record) are treated as reviewed" do
      file_doc_id = Ecto.UUID.generate()
      # No capture record — this represents a file ingestion source

      chunk = %{text: "File content.", score: 0.85, chunk_index: 0, document_id: file_doc_id}

      expect(HgsBrain.MockArcanaClient, :ask, fn _q, _opts ->
        {:ok, "Answer.", [chunk]}
      end)

      assert {:ok, "Answer.", sources} =
               Retrieval.ask("question", :personal, review_scope: :reviewed_only)

      assert length(sources) == 1
      assert hd(sources).review_state == :reviewed
    end
  end

  describe "search/3 with review_scope" do
    test "excludes inbox sources when scope is reviewed_only" do
      inbox_doc_id = Ecto.UUID.generate()
      inbox_capture(inbox_doc_id)

      chunk = %{text: "Inbox result.", score: 0.9, chunk_index: 0, document_id: inbox_doc_id}

      expect(HgsBrain.MockArcanaClient, :search, fn _q, _opts ->
        [chunk]
      end)

      results = Retrieval.search("query", :personal, review_scope: :reviewed_only)
      assert results == []
    end

    test "includes inbox sources when scope is include_inbox" do
      inbox_doc_id = Ecto.UUID.generate()
      inbox_capture(inbox_doc_id)

      chunk = %{text: "Inbox result.", score: 0.9, chunk_index: 0, document_id: inbox_doc_id}

      expect(HgsBrain.MockArcanaClient, :search, fn _q, _opts ->
        [chunk]
      end)

      results = Retrieval.search("query", :personal, review_scope: :include_inbox)
      assert length(results) == 1
    end

    test "does not pass review_scope to arcana search opts" do
      expect(HgsBrain.MockArcanaClient, :search, fn _q, opts ->
        refute Keyword.has_key?(opts, :review_scope)
        []
      end)

      Retrieval.search("query", :personal, review_scope: :reviewed_only)
    end
  end

  describe "source review_state field" do
    test "sources include review_state indicating inbox or reviewed" do
      inbox_doc_id = Ecto.UUID.generate()
      reviewed_doc_id = Ecto.UUID.generate()
      inbox_capture(inbox_doc_id)
      reviewed_capture(reviewed_doc_id)

      chunks = [
        %{text: "Inbox.", score: 0.9, chunk_index: 0, document_id: inbox_doc_id},
        %{text: "Reviewed.", score: 0.8, chunk_index: 0, document_id: reviewed_doc_id}
      ]

      expect(HgsBrain.MockArcanaClient, :ask, fn _q, _opts ->
        {:ok, "Answer.", chunks}
      end)

      assert {:ok, "Answer.", sources} =
               Retrieval.ask("question", :personal, review_scope: :include_inbox)

      states = Enum.map(sources, & &1.review_state) |> MapSet.new()
      assert MapSet.member?(states, :inbox)
      assert MapSet.member?(states, :reviewed)
    end
  end
end
