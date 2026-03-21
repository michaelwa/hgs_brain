# Ingestion

Markdown document ingestion pipeline.

```spec-meta
id: hgs_brain.ingestion
kind: feature
status: active
summary: Accepts markdown files, chunks and embeds them via arcana, and persists embeddings with segment tagging to pgvector.
surface:
  - lib/hgs_brain/ingestion.ex
decisions:
  - hgs_brain.decision.arcana_for_rag
  - hgs_brain.decision.pgvector_storage
```

## Requirements

```spec-requirements
- id: hgs_brain.ingestion.accepts_markdown
  statement: The system shall accept markdown files as input for ingestion.
  priority: must
  stability: stable
- id: hgs_brain.ingestion.segment_tagged
  statement: Each ingested document shall be tagged with a segment (work or personal) at ingestion time.
  priority: must
  stability: stable
- id: hgs_brain.ingestion.embedded
  statement: The system shall chunk and embed document content via arcana and persist embeddings to pgvector.
  priority: must
  stability: stable
- id: hgs_brain.ingestion.idempotent
  statement: Re-ingesting a document with the same source path and segment shall replace its existing embeddings rather than duplicate them.
  priority: must
  stability: evolving
```

## Verification

```spec-verification
- kind: source_file
  target: lib/hgs_brain/ingestion.ex
  covers:
    - hgs_brain.ingestion.accepts_markdown
    - hgs_brain.ingestion.segment_tagged
    - hgs_brain.ingestion.embedded
    - hgs_brain.ingestion.idempotent
```
