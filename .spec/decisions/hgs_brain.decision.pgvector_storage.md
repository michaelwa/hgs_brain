---
id: hgs_brain.decision.pgvector_storage
status: accepted
date: 2026-03-21
affects:
  - hgs_brain.ingestion
  - hgs_brain.retrieval
---

# Use pgvector via Existing Postgres

## Context

The application needs a vector store for document embeddings. Options include dedicated vector databases (Pinecone, Qdrant, Weaviate) or extending the existing Postgres instance with pgvector.

## Decision

Use pgvector within the existing Postgres instance. The application already runs on Postgres with Ecto, so pgvector keeps the infrastructure footprint minimal and transactional guarantees uniform.

## Consequences

Vector storage lives alongside relational data in the same database. No additional infrastructure to operate. Arcana's pgvector adapter is used as the storage backend.
