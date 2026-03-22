# Ingestion Health

Operational visibility and maintenance workflows for ingested knowledge sources.

```spec-meta
id: hgs_brain.ingestion_health
kind: feature
status: active
summary: The system tracks ingestion status, recency, failures, and source changes so users can inspect ingestion health and reprocess sources when needed.
surface:
  - lib/hgs_brain/ingestion.ex
  - lib/hgs_brain/ingestion_record.ex
decisions:
  - hgs_brain.decision.arcana_for_rag
  - hgs_brain.decision.pgvector_storage
  - hgs_brain.decision.embedder_lifecycle
```

## Requirements

```spec-requirements
- id: hgs_brain.ingestion_health.status_recorded
  statement: The system shall record an ingestion status for each ingested source so successful and failed ingestion attempts are distinguishable.
  priority: must
  stability: evolving
- id: hgs_brain.ingestion_health.last_successful_ingestion
  statement: The system shall record when a source was last successfully ingested.
  priority: must
  stability: evolving
- id: hgs_brain.ingestion_health.failures_visible
  statement: The system shall make ingestion failures and partial failures inspectable to callers rather than failing silently.
  priority: must
  stability: evolving
- id: hgs_brain.ingestion_health.source_change_detected
  statement: The system shall detect when a source has changed since its last successful ingestion.
  priority: must
  stability: evolving
- id: hgs_brain.ingestion_health.reprocessing_supported
  statement: The system shall support reprocessing a previously ingested source after failure or source change.
  priority: must
  stability: evolving
```

## Scenarios

```spec-scenarios
- id: hgs_brain.ingestion_health.failed_source_visible
  covers:
    - hgs_brain.ingestion_health.status_recorded
    - hgs_brain.ingestion_health.failures_visible
  given:
    - A source ingestion attempt fails
  when:
    - Callers inspect ingestion health
  then:
    - The source is represented with a failure status
    - Failure information is available for inspection

- id: hgs_brain.ingestion_health.changed_source_detected
  covers:
    - hgs_brain.ingestion_health.last_successful_ingestion
    - hgs_brain.ingestion_health.source_change_detected
  given:
    - A source has been ingested successfully
    - The source content changes afterward
  when:
    - Ingestion health is evaluated
  then:
    - The system can determine that the source changed after the last successful ingestion

- id: hgs_brain.ingestion_health.reprocess_after_failure
  covers:
    - hgs_brain.ingestion_health.reprocessing_supported
  given:
    - A source previously failed ingestion or is marked changed
  when:
    - Reprocessing is requested
  then:
    - The system attempts ingestion again for that source
```

## Verification

```spec-verification
- kind: source_file
  target: lib/hgs_brain/ingestion.ex
  covers:
    - hgs_brain.ingestion_health.status_recorded
    - hgs_brain.ingestion_health.last_successful_ingestion
    - hgs_brain.ingestion_health.failures_visible
    - hgs_brain.ingestion_health.source_change_detected
    - hgs_brain.ingestion_health.reprocessing_supported
- kind: source_file
  target: lib/hgs_brain/ingestion_record.ex
  covers:
    - hgs_brain.ingestion_health.status_recorded
    - hgs_brain.ingestion_health.last_successful_ingestion
    - hgs_brain.ingestion_health.failures_visible
    - hgs_brain.ingestion_health.source_change_detected
    - hgs_brain.ingestion_health.reprocessing_supported
- kind: command
  target: mix test test/hgs_brain/ingestion_test.exs
  execute: true
  covers:
    - hgs_brain.ingestion_health.status_recorded
    - hgs_brain.ingestion_health.last_successful_ingestion
    - hgs_brain.ingestion_health.failures_visible
    - hgs_brain.ingestion_health.source_change_detected
    - hgs_brain.ingestion_health.reprocessing_supported
```
