defmodule HgsBrainWeb.ChatLiveTest do
  # covers: hgs_brain.chat_ui.segment_selector
  # covers: hgs_brain.chat_ui.question_input
  # covers: hgs_brain.chat_ui.answer_display
  # covers: hgs_brain.chat_ui.loading_state
  # covers: hgs_brain.chat_ui.mode_selector

  use HgsBrainWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import Mox

  setup :set_mox_global
  setup :verify_on_exit!

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
      assert render(view) =~ "A personal answer."

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
      assert render(view) =~ "An answer."

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
      assert render(view) =~ "Elixir runs on the BEAM virtual machine."
    end

    test "displays an error message on failure", %{conn: conn} do
      stub(HgsBrain.MockArcanaClient, :ask, fn _q, _opts ->
        {:error, :no_llm_configured}
      end)

      {:ok, view, _html} = live(conn, "/chat")

      render_submit(view, "submit", %{"question" => "anything"})
      assert render(view) =~ "no_llm_configured"
    end

    test "ignores empty submissions", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/chat")

      # No mock expectation — if arcana were called this would raise
      render_submit(view, "submit", %{"question" => ""})
    end
  end

  describe "submit in search mode" do
    test "displays ranked passages", %{conn: conn} do
      stub(HgsBrain.MockArcanaClient, :search, fn _q, _opts ->
        [%{text: "Elixir is built on Erlang.", score: 0.93}]
      end)

      {:ok, view, _html} = live(conn, "/chat")

      render_click(view, "set_mode", %{"mode" => "search"})
      render_submit(view, "submit", %{"question" => "Elixir origins"})

      html = render(view)
      assert html =~ "Elixir is built on Erlang."
      assert html =~ "0.93"
    end
  end
end
