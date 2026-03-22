defmodule HgsBrainWeb.CaptureInboxLiveTest do
  # covers: hgs_brain.capture_inbox.quick_capture
  # covers: hgs_brain.capture_inbox.segment_assigned
  # covers: hgs_brain.capture_inbox.inbox_state
  # covers: hgs_brain.capture_inbox.display_ready

  use HgsBrainWeb.ConnCase, async: false

  import Mox
  import Phoenix.LiveViewTest

  setup :set_mox_global
  setup :verify_on_exit!

  describe "mount" do
    test "renders capture form and empty inbox", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/inbox")

      assert html =~ "Capture a thought"
      assert html =~ "No captures yet"
    end

    test "shows segment selector", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/inbox")

      assert html =~ "Personal"
      assert html =~ "Work"
    end
  end

  describe "submitting a capture" do
    test "adds capture to inbox after successful submission", %{conn: conn} do
      stub(HgsBrain.MockArcanaClient, :ingest, fn _text, _opts ->
        {:ok, %{id: Ecto.UUID.generate()}}
      end)

      {:ok, view, _html} = live(conn, "/inbox")

      view
      |> form("form", text: "A quick thought.")
      |> render_submit()

      html = render(view)
      assert html =~ "A quick thought."
      assert html =~ "Inbox (1)"
    end

    test "clears text input after submission", %{conn: conn} do
      stub(HgsBrain.MockArcanaClient, :ingest, fn _text, _opts ->
        {:ok, %{id: Ecto.UUID.generate()}}
      end)

      {:ok, view, _html} = live(conn, "/inbox")

      view
      |> form("form", text: "Something.")
      |> render_submit()

      refute render(view) =~ ~s(value="Something.")
    end

    test "shows error for blank submission", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/inbox")

      view
      |> form("form", text: "")
      |> render_submit()

      assert render(view) =~ "cannot be blank"
    end
  end

  describe "segment switching" do
    test "shows captures for the selected segment only", %{conn: conn} do
      stub(HgsBrain.MockArcanaClient, :ingest, fn _text, _opts ->
        {:ok, %{id: Ecto.UUID.generate()}}
      end)

      {:ok, view, _html} = live(conn, "/inbox")

      view |> form("form", text: "Personal note.") |> render_submit()

      view |> element("button", "Work") |> render_click()

      refute render(view) =~ "Personal note."
      assert render(view) =~ "No captures yet"
    end
  end
end
