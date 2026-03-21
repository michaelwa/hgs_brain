# Source Transparency — Retrieval Context

Extend the retrieval layer to return source metadata alongside answers.

```spec-meta
id: hgs_brain.source_transparency.retrieval_context
kind: feature
status: active
summary: The retrieval layer surfaces source metadata, excerpt text, and score for each retrieved passage, sorted by descending relevance score, so the UI can present grounded citations in rank order.
surface:
  - lib/hgs_brain/retrieval.ex
```

## Requirements

```spec-requirements
- id: hgs_brain.source_transparency.source_metadata
  statement: Each citation shall include enough metadata to identify its origin, including source file path or title and segment.
  priority: must
  stability: stable

- id: hgs_brain.source_transparency.source_excerpt
  statement: Each citation shall carry the retrieved passage text used as supporting context.
  priority: must
  stability: stable

- id: hgs_brain.source_transparency.multiple_sources
  statement: When an answer is based on multiple retrieved passages, the retrieval layer shall return them as a list of distinct source entries.
  priority: must
  stability: stable
```

## Verification

```spec-verification
- kind: source_file
  target: lib/hgs_brain/retrieval.ex
  covers:
    - hgs_brain.source_transparency.source_metadata
    - hgs_brain.source_transparency.source_excerpt
    - hgs_brain.source_transparency.multiple_sources
- kind: command
  target: mix test test/hgs_brain/retrieval_test.exs
  execute: true
  covers:
    - hgs_brain.source_transparency.source_metadata
    - hgs_brain.source_transparency.source_excerpt
    - hgs_brain.source_transparency.multiple_sources
```

## Open Questions

- Should the retrieval layer normalise raw file paths into a friendlier title, or leave that to the UI?
