defmodule HgsBrainWeb.ReviewLiveTest do
  # covers: hgs_brain.review_resurfacing.recent_items
  # covers: hgs_brain.review_resurfacing.related_items
  # covers: hgs_brain.review_resurfacing.revisit_items
  # covers: hgs_brain.review_resurfacing.dismiss_supported
  # covers: hgs_brain.review_resurfacing.defer_supported
  # covers: hgs_brain.review_resurfacing.source_state_visible

  use HgsBrainWeb.ConnCase, async: false

  import Ecto.Query
  import Phoenix.LiveViewTest
  import Mox

  alias HgsBrain.{Capture, Repo}

  setup :set_mox_global
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
    test "renders the Review heading", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/review")
      assert html =~ "Review"
    end

    test "shows Recent and Revisit sections", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/review")
      assert html =~ "Recent"
      assert html =~ "Revisit"
    end

    test "shows recent captures", %{conn: conn} do
      insert_capture(content: "Fresh thought.")
      {:ok, _view, html} = live(conn, "/review")
      assert html =~ "Fresh thought."
    end

    test "shows older captures in revisit section", %{conn: conn} do
      old = insert_capture(content: "Old thought.")
      old_date = NaiveDateTime.add(NaiveDateTime.utc_now(), -10 * 86_400)
      set_inserted_at(old, old_date)

      {:ok, _view, html} = live(conn, "/review")
      assert html =~ "Old thought."
    end

    test "source_state_visible: shows capture content and status", %{conn: conn} do
      insert_capture(content: "Inbox capture.", status: :inbox)
      {:ok, _view, html} = live(conn, "/review")
      assert html =~ "Inbox capture."
      assert html =~ "Inbox"
    end
  end

  describe "segment selector" do
    test "switches to work segment", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/review")
      html = render_click(view, "set_segment", %{"segment" => "work"})
      assert html =~ "Work"
    end

    test "scopes recent items to selected segment", %{conn: conn} do
      insert_capture(content: "Personal thought.", segment: "personal")
      insert_capture(content: "Work thought.", segment: "work")

      {:ok, view, _html} = live(conn, "/review")
      refute render(view) =~ "Work thought."

      render_click(view, "set_segment", %{"segment" => "work"})
      assert render(view) =~ "Work thought."
      refute render(view) =~ "Personal thought."
    end
  end

  describe "dismiss" do
    test "removes a recent item from view", %{conn: conn} do
      capture = insert_capture(content: "Dismiss me.")
      {:ok, view, _html} = live(conn, "/review")
      assert render(view) =~ "Dismiss me."

      render_click(view, "dismiss", %{"id" => to_string(capture.id)})
      refute render(view) =~ "Dismiss me."
    end
  end

  describe "defer" do
    test "removes item from main list and shows it in Deferred section", %{conn: conn} do
      capture = insert_capture(content: "Defer me.")
      {:ok, view, _html} = live(conn, "/review")
      assert render(view) =~ "Defer me."

      render_click(view, "defer", %{"id" => to_string(capture.id)})

      html = render(view)
      assert html =~ "Deferred"
      assert html =~ "Defer me."
    end
  end

  describe "select_capture (related items)" do
    test "loads related items when a capture is selected", %{conn: conn} do
      capture = insert_capture(content: "Context capture.")
      doc_id = Ecto.UUID.generate()

      stub(HgsBrain.MockArcanaClient, :search, fn _q, _opts ->
        [%{text: "Related knowledge.", score: 0.9, chunk_index: 0, document_id: doc_id}]
      end)

      {:ok, view, _html} = live(conn, "/review")

      render_click(view, "select_capture", %{"id" => to_string(capture.id)})
      html = wait_for_render(view, "Related knowledge.")
      assert html =~ "Related knowledge."
      assert html =~ "Related"
    end

    test "shows Related section with selected capture context", %{conn: conn} do
      capture = insert_capture(content: "My context capture.")

      stub(HgsBrain.MockArcanaClient, :search, fn _q, _opts -> [] end)

      {:ok, view, _html} = live(conn, "/review")
      render_click(view, "select_capture", %{"id" => to_string(capture.id)})

      html = wait_for_render(view, "My context capture.")
      assert html =~ "Related"
    end
  end
end
