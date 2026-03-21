defmodule HgsBrain.RetrievalTest do
  # covers: hgs_brain.retrieval.accepts_query
  # covers: hgs_brain.retrieval.scoped
  # covers: hgs_brain.retrieval.rag_answer

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

      assert {:ok, _, _} = Retrieval.ask("work question", :work)
    end

    test "propagates arcana errors" do
      expect(HgsBrain.MockArcanaClient, :ask, fn _question, _opts ->
        {:error, :no_llm_configured}
      end)

      assert {:error, :no_llm_configured} = Retrieval.ask("question", :personal)
    end
  end

  describe "search/2" do
    test "passes the personal collection to arcana" do
      chunks = [%{text: "Elixir runs on the BEAM.", score: 0.91}]

      expect(HgsBrain.MockArcanaClient, :search, fn query, opts ->
        assert query == "BEAM"
        assert opts[:collection] == "personal"
        assert opts[:repo] == Repo
        chunks
      end)

      assert ^chunks = Retrieval.search("BEAM", :personal)
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
  end
end
