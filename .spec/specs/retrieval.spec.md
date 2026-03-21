# Retrieval

RAG-powered Q&A retrieval.

```spec-meta
id: hgs_brain.retrieval
kind: feature
status: active
summary: Accepts natural language questions scoped to a segment and returns AI-generated answers from retrieved document context via arcana.
surface:
  - lib/hgs_brain/retrieval.ex
decisions:
  - hgs_brain.decision.arcana_for_rag
  - hgs_brain.decision.pgvector_storage
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
```

## Verification

```spec-verification
- kind: source_file
  target: lib/hgs_brain/retrieval.ex
  covers:
    - hgs_brain.retrieval.accepts_query
    - hgs_brain.retrieval.scoped
    - hgs_brain.retrieval.rag_answer
```
