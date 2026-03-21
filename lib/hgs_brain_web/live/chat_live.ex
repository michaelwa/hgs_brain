defmodule HgsBrainWeb.ChatLive do
  use HgsBrainWeb, :live_view

  # <!-- covers: hgs_brain.chat_ui.segment_selector -->
  # <!-- covers: hgs_brain.chat_ui.question_input -->
  # <!-- covers: hgs_brain.chat_ui.answer_display -->
  # <!-- covers: hgs_brain.chat_ui.loading_state -->
  # <!-- covers: hgs_brain.chat_ui.mode_selector -->
  # <!-- covers: hgs_brain.source_transparency.answer_citations -->
  # <!-- covers: hgs_brain.source_transparency.segment_visibility -->
  # <!-- covers: hgs_brain.source_transparency.empty_citations -->
  # <!-- covers: hgs_brain.source_transparency.search_consistency -->
  # <!-- covers: hgs_brain.source_transparency.relevance_signal -->

  alias HgsBrain.Retrieval

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       segment: :personal,
       mode: :ask,
       question: "",
       answer: nil,
       sources: [],
       results: [],
       loading: false,
       error: nil
     )}
  end

  @impl true
  def handle_event("set_segment", %{"segment" => segment}, socket) do
    {:noreply,
     assign(socket,
       segment: String.to_existing_atom(segment),
       answer: nil,
       sources: [],
       results: [],
       error: nil
     )}
  end

  def handle_event("set_mode", %{"mode" => mode}, socket) do
    {:noreply,
     assign(socket,
       mode: String.to_existing_atom(mode),
       answer: nil,
       sources: [],
       results: [],
       error: nil
     )}
  end

  def handle_event("submit", %{"question" => question}, socket) when byte_size(question) > 0 do
    %{mode: mode, segment: segment} = socket.assigns

    socket =
      assign(socket,
        question: question,
        loading: true,
        answer: nil,
        sources: [],
        results: [],
        error: nil
      )

    {:noreply,
     start_async(socket, :query, fn ->
       case mode do
         :ask -> Retrieval.ask(question, segment)
         :search -> {:search, Retrieval.search(question, segment)}
       end
     end)}
  end

  def handle_event("submit", _params, socket), do: {:noreply, socket}

  @impl true
  def handle_async(:query, {:ok, {:ok, answer, sources}}, socket) do
    {:noreply, assign(socket, loading: false, answer: answer, sources: sources)}
  end

  def handle_async(:query, {:ok, {:search, results}}, socket) do
    {:noreply, assign(socket, loading: false, results: results)}
  end

  def handle_async(:query, {:ok, {:error, reason}}, socket) do
    {:noreply, assign(socket, loading: false, error: inspect(reason))}
  end

  def handle_async(:query, {:exit, _reason}, socket) do
    {:noreply, assign(socket, loading: false, error: "Something went wrong. Please try again.")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto px-4 py-10 space-y-8">
      <h1 class="text-2xl font-semibold text-zinc-800">Second Brain</h1>

      <div class="flex items-center justify-between">
        <%!-- Segment selector --%>
        <div class="flex gap-2">
          <button
            phx-click="set_segment"
            phx-value-segment="personal"
            class={[
              "px-4 py-1.5 rounded-full text-sm font-medium transition-colors",
              if(@segment == :personal,
                do: "bg-zinc-800 text-white",
                else: "bg-zinc-100 text-zinc-600 hover:bg-zinc-200"
              )
            ]}
          >
            Personal
          </button>
          <button
            phx-click="set_segment"
            phx-value-segment="work"
            class={[
              "px-4 py-1.5 rounded-full text-sm font-medium transition-colors",
              if(@segment == :work,
                do: "bg-zinc-800 text-white",
                else: "bg-zinc-100 text-zinc-600 hover:bg-zinc-200"
              )
            ]}
          >
            Work
          </button>
        </div>

        <%!-- Mode selector --%>
        <div class="flex gap-2">
          <button
            phx-click="set_mode"
            phx-value-mode="ask"
            class={[
              "px-4 py-1.5 rounded-full text-sm font-medium transition-colors",
              if(@mode == :ask,
                do: "bg-zinc-800 text-white",
                else: "bg-zinc-100 text-zinc-600 hover:bg-zinc-200"
              )
            ]}
          >
            Ask
          </button>
          <button
            phx-click="set_mode"
            phx-value-mode="search"
            class={[
              "px-4 py-1.5 rounded-full text-sm font-medium transition-colors",
              if(@mode == :search,
                do: "bg-zinc-800 text-white",
                else: "bg-zinc-100 text-zinc-600 hover:bg-zinc-200"
              )
            ]}
          >
            Search
          </button>
        </div>
      </div>

      <%!-- Query form --%>
      <form phx-submit="submit" class="flex gap-2">
        <input
          type="text"
          name="question"
          value={@question}
          placeholder={if(@mode == :ask, do: "Ask a question...", else: "Search your knowledge...")}
          disabled={@loading}
          autocomplete="off"
          class="flex-1 rounded-lg border border-zinc-300 px-4 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-zinc-400 disabled:opacity-50"
        />
        <button
          type="submit"
          disabled={@loading}
          class="px-4 py-2 rounded-lg bg-zinc-800 text-white text-sm font-medium hover:bg-zinc-700 disabled:opacity-50 transition-colors"
        >
          {if(@mode == :ask, do: "Ask", else: "Search")}
        </button>
      </form>

      <%!-- Loading indicator --%>
      <div :if={@loading} class="flex items-center gap-2 text-sm text-zinc-500">
        <svg
          class="animate-spin h-4 w-4"
          xmlns="http://www.w3.org/2000/svg"
          fill="none"
          viewBox="0 0 24 24"
        >
          <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" />
          <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8z" />
        </svg>
        {if(@mode == :ask, do: "Thinking...", else: "Searching...")}
      </div>

      <%!-- Ask answer --%>
      <div :if={@answer} class="space-y-4">
        <div class="rounded-lg bg-zinc-50 border border-zinc-200 px-5 py-4 text-sm text-zinc-700 leading-relaxed whitespace-pre-wrap">
          {@answer}
        </div>

        <%!-- Sources section --%>
        <div>
          <h2 class="text-xs font-semibold uppercase tracking-wide text-zinc-400 mb-2">Sources</h2>
          <div :if={@sources == []} class="text-sm text-zinc-400 italic">
            No supporting sources available.
          </div>
          <div :if={@sources != []} class="space-y-2">
            <div
              :for={{source, rank} <- Enum.with_index(@sources, 1)}
              class="rounded-lg border border-zinc-200 px-4 py-3 space-y-1"
            >
              <div class="flex items-center justify-between gap-2">
                <span class="text-xs font-medium text-zinc-600 truncate">
                  {source.source || "Unknown source"}
                </span>
                <span class="text-xs text-zinc-400 shrink-0">
                  #{rank} &middot; {String.capitalize(Atom.to_string(source.segment))}
                </span>
              </div>
              <p class="text-xs text-zinc-500 leading-relaxed line-clamp-3">{source.text}</p>
            </div>
          </div>
        </div>
      </div>

      <%!-- Search results --%>
      <div :if={@results != []} class="space-y-3">
        <h2 class="text-xs font-semibold uppercase tracking-wide text-zinc-400">Sources</h2>
        <div
          :for={{result, rank} <- Enum.with_index(@results, 1)}
          class="rounded-lg border border-zinc-200 px-4 py-3 space-y-1"
        >
          <div class="flex items-center justify-between gap-2">
            <span class="text-xs font-medium text-zinc-600 truncate">
              {result.source || "Unknown source"}
            </span>
            <span class="text-xs text-zinc-400 shrink-0">
              #{rank} &middot; {String.capitalize(Atom.to_string(result.segment))}
            </span>
          </div>
          <p class="text-xs text-zinc-500 leading-relaxed line-clamp-3">{result.text}</p>
        </div>
      </div>

      <%!-- Error --%>
      <div
        :if={@error}
        class="rounded-lg bg-red-50 border border-red-200 px-5 py-4 text-sm text-red-700"
      >
        {@error}
      </div>
    </div>
    """
  end
end
