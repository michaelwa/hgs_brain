# Ingestion Source Metadata

Source-level identity and metadata for ingested knowledge sources.

```spec-meta
id: hgs_brain.ingestion_source_metadata
kind: feature
status: active
summary: The system preserves canonical source-level metadata for ingested knowledge so origin, display, change detection, and source-to-chunk traceability remain available across ingestion and retrieval workflows.
surface:
  - lib/hgs_brain/ingestion.ex
decisions:
  - hgs_brain.decision.arcana_for_rag
  - hgs_brain.decision.pgvector_storage
```

## Requirements

```spec-requirements
- id: hgs_brain.ingestion_source_metadata.origin_metadata
  statement: The system shall preserve source-level origin metadata for each ingested source, including source path when available.
  priority: must
  stability: evolving
- id: hgs_brain.ingestion_source_metadata.display_name
  statement: The system shall record a source title or derived display name suitable for user-facing presentation.
  priority: must
  stability: evolving
- id: hgs_brain.ingestion_source_metadata.segment_recorded
  statement: The system shall record the segment associated with each ingested source as source-level metadata.
  priority: must
  stability: stable
- id: hgs_brain.ingestion_source_metadata.timestamps_recorded
  statement: The system shall record source-level timestamps sufficient to distinguish initial ingestion from later updates.
  priority: must
  stability: evolving
- id: hgs_brain.ingestion_source_metadata.content_fingerprint
  statement: The system shall record a content fingerprint for each ingested source so content changes can be detected independently of source path changes.
  priority: must
  stability: evolving
- id: hgs_brain.ingestion_source_metadata.source_chunk_separation
  statement: The system shall distinguish source identity from chunk identity so multiple chunks can be traced back to a single source record.
  priority: must
  stability: stable
- id: hgs_brain.ingestion_source_metadata.frontmatter_preserved
  statement: When structured markdown metadata is present, the system shall preserve it as source-level metadata.
  priority: should
  stability: evolving
```

## Scenarios

```spec-scenarios
- id: hgs_brain.ingestion_source_metadata.markdown_source_recorded
  covers:
    - hgs_brain.ingestion_source_metadata.origin_metadata
    - hgs_brain.ingestion_source_metadata.display_name
    - hgs_brain.ingestion_source_metadata.segment_recorded
    - hgs_brain.ingestion_source_metadata.timestamps_recorded
  given:
    - A markdown source is ingested successfully
  when:
    - The source record is inspected
  then:
    - Origin metadata, display metadata, segment, and source-level timestamps are available

- id: hgs_brain.ingestion_source_metadata.changed_content_detected
  covers:
    - hgs_brain.ingestion_source_metadata.content_fingerprint
    - hgs_brain.ingestion_source_metadata.timestamps_recorded
  given:
    - A source has been ingested
    - Its content changes before a later ingestion
  when:
    - The source metadata is evaluated
  then:
    - The source fingerprint can distinguish the newer content from the earlier ingestion state

- id: hgs_brain.ingestion_source_metadata.chunks_trace_to_source
  covers:
    - hgs_brain.ingestion_source_metadata.source_chunk_separation
  given:
    - A single source is chunked into multiple embeddings
  when:
    - Retrieved chunks are inspected
  then:
    - Each chunk can be traced back to one source-level identity

- id: hgs_brain.ingestion_source_metadata.frontmatter_retained
  covers:
    - hgs_brain.ingestion_source_metadata.frontmatter_preserved
  given:
    - A markdown source includes structured frontmatter metadata
  when:
    - The source is ingested
  then:
    - The structured metadata is preserved at the source level
```

## UX Notes

- Display name should prefer explicit source title when available, then a derived filename-based label, then a fallback origin reference.
- Source path is origin metadata, not the only future-compatible notion of source identity.
- Source-level metadata is canonical; chunk metadata may carry only the subset needed for retrieval and filtering.

## Verification

```spec-verification
- kind: source_file
  target: lib/hgs_brain/ingestion.ex
  covers:
    - hgs_brain.ingestion_source_metadata.origin_metadata
    - hgs_brain.ingestion_source_metadata.display_name
    - hgs_brain.ingestion_source_metadata.segment_recorded
    - hgs_brain.ingestion_source_metadata.timestamps_recorded
    - hgs_brain.ingestion_source_metadata.content_fingerprint
    - hgs_brain.ingestion_source_metadata.source_chunk_separation
    - hgs_brain.ingestion_source_metadata.frontmatter_preserved
- kind: source_file
  target: lib/hgs_brain/ingestion_record.ex
  covers:
    - hgs_brain.ingestion_source_metadata.origin_metadata
    - hgs_brain.ingestion_source_metadata.display_name
    - hgs_brain.ingestion_source_metadata.segment_recorded
    - hgs_brain.ingestion_source_metadata.timestamps_recorded
    - hgs_brain.ingestion_source_metadata.content_fingerprint
    - hgs_brain.ingestion_source_metadata.source_chunk_separation
    - hgs_brain.ingestion_source_metadata.frontmatter_preserved
- kind: command
  target: mix test test/hgs_brain/ingestion_test.exs
  execute: true
  covers:
    - hgs_brain.ingestion_source_metadata.origin_metadata
    - hgs_brain.ingestion_source_metadata.display_name
    - hgs_brain.ingestion_source_metadata.segment_recorded
    - hgs_brain.ingestion_source_metadata.timestamps_recorded
    - hgs_brain.ingestion_source_metadata.content_fingerprint
    - hgs_brain.ingestion_source_metadata.source_chunk_separation
    - hgs_brain.ingestion_source_metadata.frontmatter_preserved
```
