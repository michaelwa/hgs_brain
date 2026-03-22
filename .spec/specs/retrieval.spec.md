# Retrieval

RAG-powered Q&A retrieval with enriched source context.

```spec-meta
id: hgs_brain.retrieval
kind: feature
status: active
summary: Accepts natural language questions scoped to a segment and returns AI-generated answers alongside enriched source maps containing passage text, file path, segment, score, chunk position, and review state, sorted by descending relevance score. Supports a review_scope option to restrict results to reviewed-only knowledge or include inbox captures.
surface:
  - lib/hgs_brain/retrieval.ex
decisions:
  - hgs_brain.decision.arcana_for_rag
  - hgs_brain.decision.pgvector_storage
  - hgs_brain.decision.source_transparency_at_retrieval_boundary
```

## Requirements

```spec-requirements
- id: hgs_brain.retrieval.accepts_query
  statement: The system shall accept a natural language question and a segment as input.
  priority: must
  stability: stable
- id: hgs_brain.retrieval.scoped
  statement: Retrieval shall return only content belonging to the specified segment; work and personal knowledge shall not mix.
  priority: must
  stability: stable
- id: hgs_brain.retrieval.rag_answer
  statement: The system shall return an AI-generated answer assembled from the most relevant retrieved passages.
  priority: must
  stability: stable
- id: hgs_brain.retrieval.enriched_sources
  statement: The system shall enrich each retrieved passage with segment, source file path, excerpt text, relevance score, and chunk index before returning it to callers.
  priority: must
  stability: stable
```

## Verification

```spec-verification
- kind: source_file
  target: lib/hgs_brain/retrieval.ex
  covers:
    - hgs_brain.retrieval.accepts_query
    - hgs_brain.retrieval.scoped
    - hgs_brain.retrieval.rag_answer
    - hgs_brain.retrieval.enriched_sources
- kind: command
  target: mix test test/hgs_brain/retrieval_test.exs
  execute: true
  covers:
    - hgs_brain.retrieval.accepts_query
    - hgs_brain.retrieval.scoped
    - hgs_brain.retrieval.rag_answer
    - hgs_brain.retrieval.enriched_sources
```
