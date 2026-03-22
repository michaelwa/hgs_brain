# Knowledge Source Ingestion

Unified ingestion contract for multiple knowledge-source types.

```spec-meta
id: hgs_brain.knowledge_source_ingestion
kind: feature
status: active
summary: The system accepts multiple knowledge-source types and normalizes them into a common ingestion pipeline so source metadata, downstream chunking, and retrieval eligibility remain consistent across source origins.
surface:
  - lib/hgs_brain/ingestion.ex
  - lib/hgs_brain
  - lib/hgs_brain_web
decisions:
  - hgs_brain.decision.arcana_for_rag
  - hgs_brain.decision.pgvector_storage
```

## Requirements

```spec-requirements
- id: hgs_brain.knowledge_source_ingestion.multiple_source_types
  statement: The system shall support a unified ingestion contract for more than one knowledge-source type.
  priority: must
  stability: evolving
- id: hgs_brain.knowledge_source_ingestion.normalized_source_record
  statement: The system shall normalize supported source types into a common source-level record before downstream ingestion processing.
  priority: must
  stability: evolving
- id: hgs_brain.knowledge_source_ingestion.segment_preserved
  statement: The system shall preserve segment assignment across source types throughout ingestion processing.
  priority: must
  stability: stable
- id: hgs_brain.knowledge_source_ingestion.extracts_ingestible_content
  statement: The system shall extract ingestible text or structured content from each supported source type before chunking and embedding.
  priority: must
  stability: evolving
- id: hgs_brain.knowledge_source_ingestion.retrieval_eligibility
  statement: The system shall make processed sources eligible for retrieval workflows according to their ingestion state.
  priority: must
  stability: evolving
- id: hgs_brain.knowledge_source_ingestion.processing_failure_visible
  statement: When a supported source type cannot be processed successfully, the failure shall be inspectable through ingestion state rather than failing silently.
  priority: must
  stability: evolving
```

## Scenarios

```spec-scenarios
- id: hgs_brain.knowledge_source_ingestion.markdown_and_capture_converge
  covers:
    - hgs_brain.knowledge_source_ingestion.multiple_source_types
    - hgs_brain.knowledge_source_ingestion.normalized_source_record
    - hgs_brain.knowledge_source_ingestion.segment_preserved
  given:
    - A markdown source and a captured source are submitted for ingestion
  when:
    - The ingestion pipeline evaluates them
  then:
    - Both source types are represented using the same source-level ingestion contract
    - Segment assignment remains available for both

- id: hgs_brain.knowledge_source_ingestion.processed_source_retrievable
  covers:
    - hgs_brain.knowledge_source_ingestion.extracts_ingestible_content
    - hgs_brain.knowledge_source_ingestion.retrieval_eligibility
  given:
    - A supported source type is processed successfully
  when:
    - Downstream retrieval workflows inspect available knowledge
  then:
    - The processed source contributes ingestible content suitable for chunking and retrieval

- id: hgs_brain.knowledge_source_ingestion.processing_failure_inspectable
  covers:
    - hgs_brain.knowledge_source_ingestion.processing_failure_visible
  given:
    - A supported source fails during ingestion processing
  when:
    - Ingestion state is inspected
  then:
    - The failure is visible for inspection rather than being silent
```

## UX Notes

- Different source types should converge into one ingestion model rather than introducing separate downstream knowledge models.
- Source-type differences may affect extraction behavior, but not the existence of a common source-level ingestion contract.
- Retrieval eligibility may depend on successful processing state, not merely source creation.

## Verification

```spec-verification
- kind: source_file
  target: lib/hgs_brain/knowledge_source.ex
  covers:
    - hgs_brain.knowledge_source_ingestion.multiple_source_types
    - hgs_brain.knowledge_source_ingestion.normalized_source_record
    - hgs_brain.knowledge_source_ingestion.segment_preserved
    - hgs_brain.knowledge_source_ingestion.extracts_ingestible_content
    - hgs_brain.knowledge_source_ingestion.retrieval_eligibility
    - hgs_brain.knowledge_source_ingestion.processing_failure_visible
- kind: source_file
  target: lib/hgs_brain/ingestion.ex
  covers:
    - hgs_brain.knowledge_source_ingestion.multiple_source_types
    - hgs_brain.knowledge_source_ingestion.normalized_source_record
    - hgs_brain.knowledge_source_ingestion.segment_preserved
    - hgs_brain.knowledge_source_ingestion.extracts_ingestible_content
    - hgs_brain.knowledge_source_ingestion.retrieval_eligibility
    - hgs_brain.knowledge_source_ingestion.processing_failure_visible
- kind: source_file
  target: lib/hgs_brain/captures.ex
  covers:
    - hgs_brain.knowledge_source_ingestion.multiple_source_types
    - hgs_brain.knowledge_source_ingestion.normalized_source_record
    - hgs_brain.knowledge_source_ingestion.segment_preserved
    - hgs_brain.knowledge_source_ingestion.extracts_ingestible_content
    - hgs_brain.knowledge_source_ingestion.retrieval_eligibility
    - hgs_brain.knowledge_source_ingestion.processing_failure_visible
- kind: command
  target: mix test test/hgs_brain/knowledge_source_ingestion_test.exs
  execute: true
  covers:
    - hgs_brain.knowledge_source_ingestion.multiple_source_types
    - hgs_brain.knowledge_source_ingestion.normalized_source_record
    - hgs_brain.knowledge_source_ingestion.segment_preserved
    - hgs_brain.knowledge_source_ingestion.extracts_ingestible_content
    - hgs_brain.knowledge_source_ingestion.retrieval_eligibility
    - hgs_brain.knowledge_source_ingestion.processing_failure_visible
```
