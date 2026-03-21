# Package

Personal second brain application with work/personal segmentation, markdown ingestion, and RAG-powered Q&A.

```spec-meta
id: hgs_brain
kind: package
status: active
summary: Personal Phoenix LiveView second brain that ingests markdown documents and answers natural language questions scoped to a work or personal segment.
surface:
  - mix.exs
  - lib/hgs_brain
  - lib/hgs_brain_web
decisions:
  - hgs_brain.decision.arcana_for_rag
  - hgs_brain.decision.pgvector_storage
```

## Requirements

```spec-requirements
- id: hgs_brain.segmentation
  statement: The system shall support work and personal segments, keeping all knowledge and query results scoped to the selected segment.
  priority: must
  stability: stable
- id: hgs_brain.markdown_ingestion
  statement: The system shall accept markdown files as knowledge sources and make their content available for retrieval.
  priority: must
  stability: stable
- id: hgs_brain.qa_interface
  statement: The system shall provide a Q&A interface for asking natural language questions and receiving AI-generated answers from ingested knowledge.
  priority: must
  stability: stable
```

## Exceptions

```spec-exceptions
- id: hgs_brain.package_bootstrap_waiver
  covers:
    - hgs_brain.segmentation
    - hgs_brain.markdown_ingestion
    - hgs_brain.qa_interface
  reason: Package-level requirements are covered by the ingestion and retrieval feature specs. Verification will be added as those features are implemented.
```
