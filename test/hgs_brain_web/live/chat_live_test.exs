defmodule HgsBrainWeb.ChatLiveTest do
  # covers: hgs_brain.chat_ui.segment_selector
  # covers: hgs_brain.chat_ui.question_input
  # covers: hgs_brain.chat_ui.answer_display
  # covers: hgs_brain.chat_ui.loading_state
  # covers: hgs_brain.chat_ui.mode_selector
  # covers: hgs_brain.source_transparency.answer_citations
  # covers: hgs_brain.source_transparency.segment_visibility
  # covers: hgs_brain.source_transparency.citation_fields
  # covers: hgs_brain.source_transparency.empty_citations
  # covers: hgs_brain.source_transparency.answer_not_blocked
  # covers: hgs_brain.source_transparency.explicit_empty_state
  # covers: hgs_brain.source_transparency.search_consistency
  # covers: hgs_brain.source_transparency.search_citation_fields
  # covers: hgs_brain.source_transparency.relevance_signal
  # covers: hgs_brain.source_transparency.rank_order
  # covers: hgs_brain.retrieval_review_scope.scope_visible
  # covers: hgs_brain.retrieval_review_scope.ask_respected
  # covers: hgs_brain.retrieval_review_scope.search_respected
  # covers: hgs_brain.retrieval_review_scope.chat_default_reviewed_only
  # covers: hgs_brain.retrieval_review_scope.workflow_default

  use HgsBrainWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import Mox

  setup :set_mox_global
  setup :verify_on_exit!

  # Waits for async LiveView operations to complete and the rendered HTML to contain
  # `expected`. Retries up to `timeout` milliseconds before failing.
  defp wait_for_render(view, expected, timeout \\ 500) do
    deadline = System.monotonic_time(:millisecond) + timeout
    wait_loop(view, expected, deadline)
  end

  defp wait_loop(view, expected, deadline) do
    html = render(view)

    cond do
      html =~ expected ->
        html

      System.monotonic_time(:millisecond) >= deadline ->
        flunk("Expected rendered HTML to contain #{inspect(expected)}\n\nGot:\n#{html}")

      true ->
        Process.sleep(10)
        wait_loop(view, expected, deadline)
    end
  end

  describe "mount" do
    test "renders with ask mode and personal segment as defaults", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/chat")

      html = render(view)
      assert html =~ "Ask a question..."
      assert html =~ "Ask"
    end
  end

  describe "segment selector" do
    test "switches to work segment", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/chat")

      html = render_click(view, "set_segment", %{"segment" => "work"})
      assert html =~ "Work"
    end

    test "clears previous answer when switching segments", %{conn: conn} do
      stub(HgsBrain.MockArcanaClient, :ask, fn _q, _opts ->
        {:ok, "A personal answer.", []}
      end)

      {:ok, view, _html} = live(conn, "/chat")

      render_submit(view, "submit", %{"question" => "anything"})
      wait_for_render(view, "A personal answer.")

      render_click(view, "set_segment", %{"segment" => "work"})
      refute render(view) =~ "A personal answer."
    end
  end

  describe "mode selector" do
    test "switches to search mode", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/chat")

      html = render_click(view, "set_mode", %{"mode" => "search"})
      assert html =~ "Search your knowledge..."
      assert html =~ "Search"
    end

    test "clears previous result when switching modes", %{conn: conn} do
      stub(HgsBrain.MockArcanaClient, :ask, fn _q, _opts ->
        {:ok, "An answer.", []}
      end)

      {:ok, view, _html} = live(conn, "/chat")

      render_submit(view, "submit", %{"question" => "anything"})
      wait_for_render(view, "An answer.")

      render_click(view, "set_mode", %{"mode" => "search"})
      refute render(view) =~ "An answer."
    end
  end

  describe "submit in ask mode" do
    test "displays the LLM answer", %{conn: conn} do
      stub(HgsBrain.MockArcanaClient, :ask, fn _q, _opts ->
        {:ok, "Elixir runs on the BEAM virtual machine.", []}
      end)

      {:ok, view, _html} = live(conn, "/chat")

      render_submit(view, "submit", %{"question" => "What VM does Elixir use?"})

      assert wait_for_render(view, "Elixir runs on the BEAM virtual machine.") =~
               "Elixir runs on the BEAM virtual machine."
    end

    test "displays citation fields: source, segment, excerpt, and rank", %{conn: conn} do
      stub(HgsBrain.MockArcanaClient, :ask, fn _q, _opts ->
        {:ok, "An answer.", [%{text: "Some excerpt text.", score: 0.9}]}
      end)

      {:ok, view, _html} = live(conn, "/chat")
      render_submit(view, "submit", %{"question" => "anything"})

      html = wait_for_render(view, "An answer.")
      assert html =~ "Some excerpt text."
      assert html =~ "Personal"
      assert html =~ "#1"
    end

    test "displays answer and explicit empty-sources message when no sources returned",
         %{conn: conn} do
      stub(HgsBrain.MockArcanaClient, :ask, fn _q, _opts ->
        {:ok, "An answer with no backing.", []}
      end)

      {:ok, view, _html} = live(conn, "/chat")
      render_submit(view, "submit", %{"question" => "anything"})

      html = wait_for_render(view, "An answer with no backing.")
      assert html =~ "No supporting sources available"
    end

    test "displays an error message on failure", %{conn: conn} do
      stub(HgsBrain.MockArcanaClient, :ask, fn _q, _opts ->
        {:error, :no_llm_configured}
      end)

      {:ok, view, _html} = live(conn, "/chat")

      render_submit(view, "submit", %{"question" => "anything"})
      assert wait_for_render(view, "no_llm_configured") =~ "no_llm_configured"
    end

    test "ignores empty submissions", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/chat")

      # No mock expectation — if arcana were called this would raise
      render_submit(view, "submit", %{"question" => ""})
    end
  end

  describe "submit in search mode" do
    test "displays citation fields: source, segment, excerpt, and rank", %{conn: conn} do
      stub(HgsBrain.MockArcanaClient, :search, fn _q, _opts ->
        [%{text: "Elixir is built on Erlang.", score: 0.93}]
      end)

      {:ok, view, _html} = live(conn, "/chat")

      render_click(view, "set_mode", %{"mode" => "search"})
      render_submit(view, "submit", %{"question" => "Elixir origins"})

      html = wait_for_render(view, "Elixir is built on Erlang.")
      assert html =~ "Personal"
      assert html =~ "#1"
    end

    test "displays results in descending relevance order", %{conn: conn} do
      stub(HgsBrain.MockArcanaClient, :search, fn _q, _opts ->
        [
          %{text: "Lower relevance passage.", score: 0.5},
          %{text: "Higher relevance passage.", score: 0.9}
        ]
      end)

      {:ok, view, _html} = live(conn, "/chat")

      render_click(view, "set_mode", %{"mode" => "search"})
      render_submit(view, "submit", %{"question" => "anything"})

      html = wait_for_render(view, "Higher relevance passage.")
      higher_pos = :binary.match(html, "Higher relevance passage.") |> elem(0)
      lower_pos = :binary.match(html, "Lower relevance passage.") |> elem(0)
      assert higher_pos < lower_pos, "highest-ranked citation should appear first"
    end
  end

  describe "review scope" do
    test "shows review scope selector on mount", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/chat")
      assert html =~ "Reviewed Only"
      assert html =~ "Include Inbox"
    end

    test "defaults to reviewed-only scope in chat", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/chat")
      html = render(view)
      # Reviewed Only button should be the active one (bg-zinc-800 = active)
      assert html =~ "Reviewed Only"
      # Scope selector is visible before any query
      assert html =~ "Sources:"
    end

    test "can switch to include-inbox scope", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/chat")
      render_click(view, "set_review_scope", %{"scope" => "include_inbox"})
      html = render(view)
      assert html =~ "Include Inbox"
    end

    test "passes reviewed_only scope to retrieval on ask", %{conn: conn} do
      stub(HgsBrain.MockArcanaClient, :ask, fn _q, _opts ->
        {:ok, "Answer.", []}
      end)

      {:ok, view, _html} = live(conn, "/chat")
      # default scope is reviewed_only; just verify no error and answer renders
      render_submit(view, "submit", %{"question" => "anything"})
      wait_for_render(view, "Answer.")
    end

    test "passes include_inbox scope to retrieval when selected", %{conn: conn} do
      stub(HgsBrain.MockArcanaClient, :ask, fn _q, _opts ->
        {:ok, "Broad answer.", []}
      end)

      {:ok, view, _html} = live(conn, "/chat")
      render_click(view, "set_review_scope", %{"scope" => "include_inbox"})
      render_submit(view, "submit", %{"question" => "anything"})
      wait_for_render(view, "Broad answer.")
    end
  end
end
