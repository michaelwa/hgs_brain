# Source Transparency — Relevance Signal

Expose a retrieval score or rank alongside each citation.

```spec-meta
id: hgs_brain.source_transparency.relevance_signal
kind: feature
status: active
summary: Each supporting citation carries a lightweight relevance or confidence signal — such as retrieval score or rank — so users can judge how strongly a passage supported the answer.
surface:
  - lib/hgs_brain/retrieval.ex
  - lib/hgs_brain_web/live/chat_live.ex
```

## Requirements

```spec-requirements
- id: hgs_brain.source_transparency.relevance_signal
  statement: The system shall expose a lightweight relevance or confidence signal for each supporting citation, such as retrieval score or rank.
  priority: should
  stability: evolving
```

## UX Notes

- Display score or rank as a secondary detail on each citation item (e.g. small badge or muted text).
- Avoid presenting raw float scores without context; a rank (1st, 2nd, …) or a normalised label (high / medium / low) is preferable if the raw score is not intuitive.

## Verification

```spec-verification
- kind: source_file
  target: lib/hgs_brain/retrieval.ex
  covers:
    - hgs_brain.source_transparency.relevance_signal
- kind: source_file
  target: lib/hgs_brain_web/live/chat_live.ex
  covers:
    - hgs_brain.source_transparency.relevance_signal
```

## Open Questions

- Does Arcana return a raw similarity score, or only ranked results?
- What normalisation, if any, should be applied before display?
