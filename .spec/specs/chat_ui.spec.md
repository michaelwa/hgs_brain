# Chat UI

Simple LiveView Q&A interface.

```spec-meta
id: hgs_brain.chat_ui
kind: feature
status: active
summary: LiveView page for querying the knowledge base, with segment selection, ask/search mode toggle, and result display.
surface:
  - lib/hgs_brain_web/live/chat_live.ex
```

## Requirements

```spec-requirements
- id: hgs_brain.chat_ui.segment_selector
  statement: The UI shall allow the user to select a segment (work or personal) before submitting a question.
  priority: must
  stability: stable
- id: hgs_brain.chat_ui.question_input
  statement: The UI shall provide a text input for the user to enter a natural language question.
  priority: must
  stability: stable
- id: hgs_brain.chat_ui.answer_display
  statement: The UI shall display the AI-generated answer after the question is submitted.
  priority: must
  stability: stable
- id: hgs_brain.chat_ui.loading_state
  statement: The UI shall indicate that a query is in progress while waiting for a response.
  priority: must
  stability: stable
- id: hgs_brain.chat_ui.mode_selector
  statement: The UI shall allow the user to choose between ask mode (AI-generated answer) and search mode (raw retrieved passages), defaulting to ask.
  priority: must
  stability: stable
```

## Verification

```spec-verification
- kind: source_file
  target: lib/hgs_brain_web/live/chat_live.ex
  covers:
    - hgs_brain.chat_ui.segment_selector
    - hgs_brain.chat_ui.question_input
    - hgs_brain.chat_ui.answer_display
    - hgs_brain.chat_ui.loading_state
    - hgs_brain.chat_ui.mode_selector
```
