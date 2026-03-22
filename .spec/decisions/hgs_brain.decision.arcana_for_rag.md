---
id: hgs_brain.decision.arcana_for_rag
status: accepted
date: 2026-03-21
affects:
  - hgs_brain.ingestion
  - hgs_brain.ingestion_health
  - hgs_brain.retrieval
  - hgs_brain.capture_inbox
  - hgs_brain.knowledge_source_ingestion
  - hgs_brain.retrieval_review_scope
  - hgs_brain.review_resurfacing
---

# Use Arcana for RAG

## Context

The second brain needs document embedding, vector search, and AI-powered answer generation. These could be implemented manually against pgvector and an LLM API, but that requires composing several moving parts.

## Decision

Use the `arcana` library as the RAG layer. Arcana provides embeddable RAG for Phoenix/Elixir applications, abstracting embedding, retrieval, and answer generation behind a unified interface.

## Consequences

Ingestion and retrieval behavior is shaped by arcana's API. Custom chunking, embedding model selection, and query strategies are delegated to arcana's configuration rather than implemented in application code.
