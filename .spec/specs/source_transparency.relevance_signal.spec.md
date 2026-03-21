# Source Transparency — Relevance Signal

Expose citation strength using a stable rank indicator.

```spec-meta
id: hgs_brain.source_transparency.relevance_signal
kind: feature
status: active
summary: Each supporting citation carries a lightweight relevance signal expressed as retrieval rank so users can judge how strongly a passage supported the answer without interpreting raw similarity scores.
surface:
  - lib/hgs_brain/retrieval.ex
  - lib/hgs_brain_web/live/chat_live.ex
```

## Requirements

```spec-requirements
- id: hgs_brain.source_transparency.relevance_signal
  statement: The system shall expose a lightweight relevance signal for each supporting citation using ordinal rank within the retrieved result set.
  priority: must
  stability: stable

- id: hgs_brain.source_transparency.rank_order
  statement: Citations shall be rendered in descending retrieval relevance order so the displayed rank matches retrieval priority.
  priority: must
  stability: stable
```

## Scenarios

```spec-scenarios
- id: hgs_brain.source_transparency.ranked_citations
  covers:
    - hgs_brain.source_transparency.relevance_signal
    - hgs_brain.source_transparency.rank_order
  given:
    - Retrieved passages are available for an answer or search result
  when:
    - Citations are rendered
  then:
    - Each citation displays its ordinal rank and the highest-ranked citation appears first
```

## UX Notes

- Display rank as a secondary detail on each citation item, such as `#1`, `#2`, and `#3`.
- Do not expose raw float similarity scores in the UI for v1.
- If internal retrieval scores are available, they may remain internal implementation detail until a clearer normalization scheme is defined.

## Verification

```spec-verification
- kind: command
  target: mix test test/hgs_brain/retrieval_test.exs
  execute: true
  covers:
    - hgs_brain.source_transparency.relevance_signal
    - hgs_brain.source_transparency.rank_order
- kind: command
  target: mix test test/hgs_brain_web/live/chat_live_test.exs
  execute: true
  covers:
    - hgs_brain.source_transparency.relevance_signal
    - hgs_brain.source_transparency.rank_order
```
