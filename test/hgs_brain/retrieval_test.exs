defmodule HgsBrain.RetrievalTest do
  # covers: hgs_brain.retrieval.accepts_query
  # covers: hgs_brain.retrieval.scoped
  # covers: hgs_brain.retrieval.rag_answer
  # covers: hgs_brain.retrieval.enriched_sources
  # covers: hgs_brain.source_transparency.source_metadata
  # covers: hgs_brain.source_transparency.source_excerpt
  # covers: hgs_brain.source_transparency.multiple_sources

  use ExUnit.Case, async: true

  import Mox

  alias HgsBrain.Retrieval
  alias HgsBrain.Repo

  setup :verify_on_exit!

  describe "ask/2" do
    test "passes the personal collection to arcana" do
      expect(HgsBrain.MockArcanaClient, :ask, fn question, opts ->
        assert question == "What is Elixir?"
        assert opts[:collection] == "personal"
        assert opts[:repo] == Repo
        {:ok, "Elixir is a functional language.", []}
      end)

      assert {:ok, "Elixir is a functional language.", []} =
               Retrieval.ask("What is Elixir?", :personal)
    end

    test "passes the work collection to arcana" do
      expect(HgsBrain.MockArcanaClient, :ask, fn _question, opts ->
        assert opts[:collection] == "work"
        {:ok, "Some work answer.", []}
      end)

      assert {:ok, _, []} = Retrieval.ask("work question", :work)
    end

    test "propagates arcana errors" do
      expect(HgsBrain.MockArcanaClient, :ask, fn _question, _opts ->
        {:error, :no_llm_configured}
      end)

      assert {:error, :no_llm_configured} = Retrieval.ask("question", :personal)
    end

    test "enriches context chunks with segment and normalised fields" do
      raw_chunk = %{
        text: "Elixir runs on the BEAM.",
        score: 0.88,
        chunk_index: 2,
        document_id: nil
      }

      expect(HgsBrain.MockArcanaClient, :ask, fn _q, _opts ->
        {:ok, "An answer.", [raw_chunk]}
      end)

      assert {:ok, "An answer.", [source]} = Retrieval.ask("question", :work)

      assert source.text == "Elixir runs on the BEAM."
      assert source.segment == :work
      assert source.score == 0.88
      assert source.chunk_index == 2
      assert source.document_id == nil
      assert source.source == nil
    end

    test "returns multiple enriched sources when multiple chunks are retrieved" do
      chunks = [
        %{text: "First passage.", score: 0.95, chunk_index: 0, document_id: nil},
        %{text: "Second passage.", score: 0.80, chunk_index: 1, document_id: nil}
      ]

      expect(HgsBrain.MockArcanaClient, :ask, fn _q, _opts ->
        {:ok, "Combined answer.", chunks}
      end)

      assert {:ok, "Combined answer.", sources} = Retrieval.ask("question", :personal)
      assert length(sources) == 2
      assert Enum.all?(sources, &(&1.segment == :personal))
      assert Enum.map(sources, & &1.text) == ["First passage.", "Second passage."]
    end
  end

  describe "search/2" do
    test "passes the personal collection to arcana" do
      raw_chunk = %{
        text: "Elixir runs on the BEAM.",
        score: 0.91,
        chunk_index: 0,
        document_id: nil
      }

      expect(HgsBrain.MockArcanaClient, :search, fn query, opts ->
        assert query == "BEAM"
        assert opts[:collection] == "personal"
        assert opts[:repo] == Repo
        [raw_chunk]
      end)

      assert [source] = Retrieval.search("BEAM", :personal)
      assert source.text == "Elixir runs on the BEAM."
      assert source.score == 0.91
      assert source.segment == :personal
      assert source.source == nil
    end

    test "passes the work collection to arcana" do
      expect(HgsBrain.MockArcanaClient, :search, fn _query, opts ->
        assert opts[:collection] == "work"
        []
      end)

      assert [] = Retrieval.search("anything", :work)
    end

    test "passes through additional opts to arcana" do
      expect(HgsBrain.MockArcanaClient, :search, fn _query, opts ->
        assert opts[:limit] == 3
        []
      end)

      Retrieval.search("query", :personal, limit: 3)
    end

    test "enriches results with segment" do
      expect(HgsBrain.MockArcanaClient, :search, fn _query, _opts ->
        [
          %{text: "Work note.", score: 0.75, chunk_index: 0, document_id: nil},
          %{text: "Another note.", score: 0.60, chunk_index: 1, document_id: nil}
        ]
      end)

      results = Retrieval.search("notes", :work)
      assert length(results) == 2
      assert Enum.all?(results, &(&1.segment == :work))
    end
  end
end
