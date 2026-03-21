# Source Transparency — Weak Grounding State

Clearly communicate when an answer has no supporting evidence.

```spec-meta
id: hgs_brain.source_transparency.weak_grounding
kind: feature
status: active
summary: When ask mode produces an answer without any retrieved supporting passages, the UI presents a clear weak-grounding state instead of implying the answer is well supported.
surface:
  - lib/hgs_brain_web/live/chat_live.ex
```

## Requirements

```spec-requirements
- id: hgs_brain.source_transparency.empty_citations
  statement: If ask mode returns an answer with zero supporting sources, the system shall clearly indicate that the answer is weakly grounded.
  priority: must
  stability: stable

- id: hgs_brain.source_transparency.answer_not_blocked
  statement: When zero supporting sources are returned, the system shall still display the answer rather than suppressing it.
  priority: must
  stability: stable

- id: hgs_brain.source_transparency.explicit_empty_state
  statement: The Sources section shall render an explicit empty-state message when zero supporting sources are available.
  priority: must
  stability: stable
```

## Scenarios

```spec-scenarios
- id: hgs_brain.source_transparency.no_grounding
  covers:
    - hgs_brain.source_transparency.empty_citations
    - hgs_brain.source_transparency.answer_not_blocked
    - hgs_brain.source_transparency.explicit_empty_state
  given:
    - The user asks a question and answer generation succeeds
    - Retrieval returns zero supporting passages
  when:
    - The response is rendered
  then:
    - The UI displays the answer
    - The Sources section displays a clear "No supporting sources available" message
    - The empty Sources state is visible instead of an empty citation list
```

## UX Notes

- For v1, weak grounding is defined as zero supporting sources.
- Do not infer weak grounding from a score threshold in v1.
- The answer remains visible so the user can inspect it, but the lack of support must be obvious in the Sources area.

## Verification

```spec-verification
- kind: command
  target: mix test test/hgs_brain_web/live/chat_live_test.exs
  execute: true
  covers:
    - hgs_brain.source_transparency.empty_citations
    - hgs_brain.source_transparency.answer_not_blocked
    - hgs_brain.source_transparency.explicit_empty_state
```
