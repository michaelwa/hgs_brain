defmodule HgsBrainWeb.CaptureInboxLive do
  use HgsBrainWeb, :live_view

  # <!-- covers: hgs_brain.capture_inbox.quick_capture -->
  # <!-- covers: hgs_brain.capture_inbox.segment_assigned -->
  # <!-- covers: hgs_brain.capture_inbox.inbox_state -->
  # <!-- covers: hgs_brain.capture_inbox.display_ready -->

  alias HgsBrain.Captures

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       segment: :personal,
       text: "",
       captures: Captures.list_inbox(:personal),
       saving: false,
       error: nil
     )}
  end

  @impl true
  def handle_event("set_segment", %{"segment" => segment}, socket) do
    seg = String.to_existing_atom(segment)

    {:noreply,
     assign(socket,
       segment: seg,
       captures: Captures.list_inbox(seg),
       text: "",
       error: nil
     )}
  end

  def handle_event("update_text", %{"text" => text}, socket) do
    {:noreply, assign(socket, text: text, error: nil)}
  end

  def handle_event("submit_capture", %{"text" => text}, socket) do
    segment = socket.assigns.segment

    case Captures.create_capture(text, segment) do
      {:ok, _capture} ->
        {:noreply,
         assign(socket,
           text: "",
           captures: Captures.list_inbox(segment),
           saving: false,
           error: nil
         )}

      {:error, %Ecto.Changeset{}} ->
        {:noreply, assign(socket, saving: false, error: "Capture text cannot be blank.")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto p-6 space-y-8">
      <div class="flex items-center gap-3">
        <button
          :for={seg <- [:personal, :work]}
          phx-click="set_segment"
          phx-value-segment={seg}
          class={[
            "px-3 py-1 rounded text-sm font-medium",
            @segment == seg && "bg-zinc-800 text-white",
            @segment != seg && "text-zinc-400 hover:text-zinc-200"
          ]}
        >
          {String.capitalize(Atom.to_string(seg))}
        </button>
      </div>

      <form phx-submit="submit_capture" class="space-y-3">
        <textarea
          name="text"
          value={@text}
          phx-change="update_text"
          placeholder="Capture a thought…"
          rows="4"
          class="w-full bg-zinc-900 border border-zinc-700 rounded-lg p-3 text-zinc-100 placeholder-zinc-500 resize-none focus:outline-none focus:border-zinc-500"
        ></textarea>
        <div :if={@error} class="text-sm text-red-400">{@error}</div>
        <button
          type="submit"
          disabled={@saving}
          class="px-4 py-2 bg-zinc-700 hover:bg-zinc-600 text-white text-sm rounded-lg disabled:opacity-50"
        >
          Capture
        </button>
      </form>

      <section>
        <h2 class="text-sm font-semibold text-zinc-400 uppercase tracking-wide mb-4">
          Inbox ({length(@captures)})
        </h2>
        <div :if={@captures == []} class="text-sm text-zinc-500 italic">
          No captures yet.
        </div>
        <ul class="space-y-3">
          <li
            :for={capture <- @captures}
            class="bg-zinc-900 border border-zinc-800 rounded-lg p-4 space-y-1"
          >
            <p class="text-zinc-100 text-sm whitespace-pre-wrap">{capture.content}</p>
            <p class="text-xs text-zinc-500">
              {Calendar.strftime(capture.inserted_at, "%b %d, %Y")}
            </p>
          </li>
        </ul>
      </section>
    </div>
    """
  end
end
