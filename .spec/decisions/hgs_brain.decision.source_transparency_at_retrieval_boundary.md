---
id: hgs_brain.decision.source_transparency_at_retrieval_boundary
status: accepted
date: 2026-03-21
affects:
  - hgs_brain.retrieval
  - hgs_brain.chat_ui
  - hgs_brain.source_transparency.retrieval_context
  - hgs_brain.source_transparency.citation_ui
  - hgs_brain.source_transparency.weak_grounding
  - hgs_brain.source_transparency.search_consistency
  - hgs_brain.source_transparency.relevance_signal
---

# Enrich Source Metadata at the Retrieval Boundary

## Context

Source transparency requires that every answer and search result exposes its supporting passages, file origin, segment, and relevance score. This metadata must flow from the retrieval layer to the UI. The question is where to assemble and normalise it.

## Decision

Enrich retrieved chunks into a normalised source map at the `HgsBrain.Retrieval` boundary — inside `ask/2` and `search/3` — before returning to callers. Each source map carries: `text`, `source` (file path), `segment`, `score`, `chunk_index`, and `document_id`.

File paths are resolved in a single batched query against `Arcana.Document` keyed on the document IDs present in the chunk results.

## Consequences

- The UI receives ready-to-render source maps; it does not need to understand Arcana's internal chunk format.
- A small additional DB query runs per ask/search call to resolve file paths. This is acceptable given the low cardinality of chunks per query (default limit: 5–10).
- If `document_id` is nil (e.g. in tests or edge cases), `source` is nil rather than an error.
- The `chat_live.ex` `handle_async` clause for `:query` now stores enriched sources in the `sources` assign, which is rendered as a Sources section below each answer and reused for search results.
