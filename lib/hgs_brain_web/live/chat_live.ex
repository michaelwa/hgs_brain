defmodule HgsBrainWeb.ChatLive do
  use HgsBrainWeb, :live_view

  # <!-- covers: hgs_brain.chat_ui.segment_selector -->
  # <!-- covers: hgs_brain.chat_ui.question_input -->
  # <!-- covers: hgs_brain.chat_ui.answer_display -->
  # <!-- covers: hgs_brain.chat_ui.loading_state -->

  alias HgsBrain.Retrieval

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       segment: :personal,
       question: "",
       answer: nil,
       loading: false,
       error: nil
     )}
  end

  @impl true
  def handle_event("set_segment", %{"segment" => segment}, socket) do
    {:noreply, assign(socket, segment: String.to_existing_atom(segment), answer: nil, error: nil)}
  end

  def handle_event("ask", %{"question" => question}, socket) when byte_size(question) > 0 do
    segment = socket.assigns.segment

    socket =
      assign(socket,
        question: question,
        loading: true,
        answer: nil,
        error: nil
      )

    {:noreply, start_async(socket, :ask, fn -> Retrieval.ask(question, segment) end)}
  end

  def handle_event("ask", _params, socket), do: {:noreply, socket}

  @impl true
  def handle_async(:ask, {:ok, {:ok, answer, _context}}, socket) do
    {:noreply, assign(socket, loading: false, answer: answer)}
  end

  def handle_async(:ask, {:ok, {:error, reason}}, socket) do
    {:noreply, assign(socket, loading: false, error: inspect(reason))}
  end

  def handle_async(:ask, {:exit, _reason}, socket) do
    {:noreply, assign(socket, loading: false, error: "Something went wrong. Please try again.")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto px-4 py-10 space-y-8">
      <h1 class="text-2xl font-semibold text-zinc-800">Second Brain</h1>

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

      <%!-- Question form --%>
      <form phx-submit="ask" class="flex gap-2">
        <input
          type="text"
          name="question"
          value={@question}
          placeholder="Ask a question..."
          disabled={@loading}
          autocomplete="off"
          class="flex-1 rounded-lg border border-zinc-300 px-4 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-zinc-400 disabled:opacity-50"
        />
        <button
          type="submit"
          disabled={@loading}
          class="px-4 py-2 rounded-lg bg-zinc-800 text-white text-sm font-medium hover:bg-zinc-700 disabled:opacity-50 transition-colors"
        >
          Ask
        </button>
      </form>

      <%!-- Loading indicator --%>
      <div :if={@loading} class="flex items-center gap-2 text-sm text-zinc-500">
        <svg class="animate-spin h-4 w-4" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
          <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" />
          <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8z" />
        </svg>
        Thinking...
      </div>

      <%!-- Answer --%>
      <div :if={@answer} class="rounded-lg bg-zinc-50 border border-zinc-200 px-5 py-4 text-sm text-zinc-700 leading-relaxed whitespace-pre-wrap">
        {@answer}
      </div>

      <%!-- Error --%>
      <div :if={@error} class="rounded-lg bg-red-50 border border-red-200 px-5 py-4 text-sm text-red-700">
        {@error}
      </div>
    </div>
    """
  end
end
