defmodule HgsBrainWeb.ReviewLive do
  use HgsBrainWeb, :live_view

  # <!-- covers: hgs_brain.review_resurfacing.recent_items -->
  # <!-- covers: hgs_brain.review_resurfacing.related_items -->
  # <!-- covers: hgs_brain.review_resurfacing.revisit_items -->
  # <!-- covers: hgs_brain.review_resurfacing.dismiss_supported -->
  # <!-- covers: hgs_brain.review_resurfacing.defer_supported -->
  # <!-- covers: hgs_brain.review_resurfacing.source_state_visible -->

  alias HgsBrain.Resurfacing

  @impl true
  def mount(_params, _session, socket) do
    segment = :personal

    {:ok,
     assign(socket,
       segment: segment,
       recent_items: Resurfacing.recent_items(segment),
       revisit_items: Resurfacing.revisit_items(segment),
       related_items: [],
       loading_related: false,
       selected_capture: nil,
       dismissed_ids: MapSet.new(),
       deferred_items: []
     )}
  end

  @impl true
  def handle_event("set_segment", %{"segment" => segment}, socket) do
    seg = String.to_existing_atom(segment)

    {:noreply,
     assign(socket,
       segment: seg,
       recent_items: Resurfacing.recent_items(seg),
       revisit_items: Resurfacing.revisit_items(seg),
       related_items: [],
       loading_related: false,
       selected_capture: nil,
       dismissed_ids: MapSet.new(),
       deferred_items: []
     )}
  end

  def handle_event("select_capture", %{"id" => id}, socket) do
    all_items = socket.assigns.recent_items ++ socket.assigns.revisit_items
    capture = Enum.find(all_items, &(to_string(&1.id) == id))
    segment = socket.assigns.segment

    socket =
      assign(socket,
        selected_capture: capture,
        loading_related: true,
        related_items: []
      )

    {:noreply,
     start_async(socket, :load_related, fn ->
       if capture, do: Resurfacing.related_items(capture.content, segment), else: []
     end)}
  end

  def handle_event("dismiss", %{"id" => id}, socket) do
    {:noreply, assign(socket, dismissed_ids: MapSet.put(socket.assigns.dismissed_ids, id))}
  end

  def handle_event("defer", %{"id" => id}, socket) do
    all_items =
      socket.assigns.recent_items ++
        socket.assigns.revisit_items ++
        socket.assigns.related_items

    deferred =
      Enum.find(all_items, fn
        %{id: item_id} -> to_string(item_id) == id
        %{document_id: doc_id} -> to_string(doc_id) == id
        _ -> false
      end)

    dismissed_ids = MapSet.put(socket.assigns.dismissed_ids, id)

    deferred_items =
      if deferred,
        do: [deferred | socket.assigns.deferred_items],
        else: socket.assigns.deferred_items

    {:noreply, assign(socket, dismissed_ids: dismissed_ids, deferred_items: deferred_items)}
  end

  @impl true
  def handle_async(:load_related, {:ok, sources}, socket) do
    {:noreply, assign(socket, loading_related: false, related_items: sources)}
  end

  def handle_async(:load_related, {:exit, _reason}, socket) do
    {:noreply, assign(socket, loading_related: false, related_items: [])}
  end

  defp dismissed?(%{id: id}, dismissed_ids), do: MapSet.member?(dismissed_ids, to_string(id))

  defp dismissed?(%{document_id: id}, dismissed_ids),
    do: MapSet.member?(dismissed_ids, to_string(id))

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto px-4 py-10 space-y-8">
      <h1 class="text-2xl font-semibold text-zinc-800">Review</h1>

      <%!-- Segment selector --%>
      <div class="flex gap-2">
        <button
          :for={seg <- [:personal, :work]}
          phx-click="set_segment"
          phx-value-segment={seg}
          class={[
            "px-4 py-1.5 rounded-full text-sm font-medium transition-colors",
            if(@segment == seg,
              do: "bg-zinc-800 text-white",
              else: "bg-zinc-100 text-zinc-600 hover:bg-zinc-200"
            )
          ]}
        >
          {String.capitalize(Atom.to_string(seg))}
        </button>
      </div>

      <%!-- Recent items --%>
      <section>
        <h2 class="text-xs font-semibold uppercase tracking-wide text-zinc-400 mb-3">Recent</h2>
        <div :if={@recent_items == []} class="text-sm text-zinc-400 italic">No recent items.</div>
        <div class="space-y-2">
          <div
            :for={item <- Enum.reject(@recent_items, &dismissed?(&1, @dismissed_ids))}
            class={[
              "rounded-lg border px-4 py-3 space-y-2 transition-colors",
              if(@selected_capture && @selected_capture.id == item.id,
                do: "border-zinc-400 bg-zinc-50",
                else: "border-zinc-200"
              )
            ]}
          >
            <p class="text-sm text-zinc-700 line-clamp-3">{item.content}</p>
            <div class="flex items-center justify-between">
              <span class="text-xs text-zinc-400">
                {String.capitalize(to_string(item.status))} &middot; {Calendar.strftime(
                  item.inserted_at,
                  "%b %d, %Y"
                )}
              </span>
              <div class="flex gap-2">
                <button
                  phx-click="select_capture"
                  phx-value-id={item.id}
                  class="text-xs text-zinc-500 hover:text-zinc-800 font-medium"
                >
                  Related
                </button>
                <button
                  phx-click="defer"
                  phx-value-id={item.id}
                  class="text-xs text-zinc-400 hover:text-zinc-600"
                >
                  Defer
                </button>
                <button
                  phx-click="dismiss"
                  phx-value-id={item.id}
                  class="text-xs text-zinc-400 hover:text-zinc-600"
                >
                  Dismiss
                </button>
              </div>
            </div>
          </div>
        </div>
      </section>

      <%!-- Related items --%>
      <section :if={@selected_capture}>
        <h2 class="text-xs font-semibold uppercase tracking-wide text-zinc-400 mb-3">Related</h2>
        <p class="text-xs text-zinc-400 italic mb-3">
          Showing knowledge related to:
          <span class="font-medium text-zinc-600">
            {String.slice(@selected_capture.content, 0, 60)}
          </span>
        </p>
        <div :if={@loading_related} class="text-sm text-zinc-400 italic">Loading related…</div>
        <div :if={!@loading_related && @related_items == []} class="text-sm text-zinc-400 italic">
          No related items found.
        </div>
        <div class="space-y-2">
          <div
            :for={source <- Enum.reject(@related_items, &dismissed?(&1, @dismissed_ids))}
            class="rounded-lg border border-zinc-200 px-4 py-3 space-y-2"
          >
            <p class="text-sm text-zinc-700 line-clamp-3">{source.text}</p>
            <div class="flex items-center justify-between">
              <span class="text-xs text-zinc-400">
                {String.capitalize(to_string(source.review_state))} &middot; {String.capitalize(
                  Atom.to_string(source.segment)
                )}
              </span>
              <div class="flex gap-2">
                <button
                  phx-click="defer"
                  phx-value-id={source.document_id}
                  class="text-xs text-zinc-400 hover:text-zinc-600"
                >
                  Defer
                </button>
                <button
                  phx-click="dismiss"
                  phx-value-id={source.document_id}
                  class="text-xs text-zinc-400 hover:text-zinc-600"
                >
                  Dismiss
                </button>
              </div>
            </div>
          </div>
        </div>
      </section>

      <%!-- Revisit items --%>
      <section>
        <h2 class="text-xs font-semibold uppercase tracking-wide text-zinc-400 mb-3">Revisit</h2>
        <div :if={@revisit_items == []} class="text-sm text-zinc-400 italic">
          No older items to revisit.
        </div>
        <div class="space-y-2">
          <div
            :for={item <- Enum.reject(@revisit_items, &dismissed?(&1, @dismissed_ids))}
            class="rounded-lg border border-zinc-200 px-4 py-3 space-y-2"
          >
            <p class="text-sm text-zinc-700 line-clamp-3">{item.content}</p>
            <div class="flex items-center justify-between">
              <span class="text-xs text-zinc-400">
                {String.capitalize(to_string(item.status))} &middot; {Calendar.strftime(
                  item.inserted_at,
                  "%b %d, %Y"
                )}
              </span>
              <div class="flex gap-2">
                <button
                  phx-click="select_capture"
                  phx-value-id={item.id}
                  class="text-xs text-zinc-500 hover:text-zinc-800 font-medium"
                >
                  Related
                </button>
                <button
                  phx-click="defer"
                  phx-value-id={item.id}
                  class="text-xs text-zinc-400 hover:text-zinc-600"
                >
                  Defer
                </button>
                <button
                  phx-click="dismiss"
                  phx-value-id={item.id}
                  class="text-xs text-zinc-400 hover:text-zinc-600"
                >
                  Dismiss
                </button>
              </div>
            </div>
          </div>
        </div>
      </section>

      <%!-- Deferred items --%>
      <section :if={@deferred_items != []}>
        <h2 class="text-xs font-semibold uppercase tracking-wide text-zinc-400 mb-3">
          Deferred ({length(@deferred_items)})
        </h2>
        <div class="space-y-2">
          <div
            :for={item <- @deferred_items}
            class="rounded-lg border border-zinc-100 bg-zinc-50 px-4 py-3 space-y-1 opacity-60"
          >
            <p class="text-sm text-zinc-600 line-clamp-2">
              {Map.get(item, :content) || Map.get(item, :text, "")}
            </p>
            <span class="text-xs text-zinc-400">Deferred for later review</span>
          </div>
        </div>
      </section>
    </div>
    """
  end
end
