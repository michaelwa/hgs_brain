# Capture Inbox

Low-friction capture flow for new knowledge before full organization.

```spec-meta
id: hgs_brain.capture_inbox
kind: feature
status: active
summary: The system allows users to create lightweight captures that enter an inbox state with source-level metadata preserved while remaining available to downstream retrieval workflows. Captures normalize through the KnowledgeSource contract before ingestion and expose review state metadata so retrieval workflows can apply review-scope filtering.
surface:
  - lib/hgs_brain
  - lib/hgs_brain_web
decisions:
  - hgs_brain.decision.arcana_for_rag
```

## Requirements

```spec-requirements
- id: hgs_brain.capture_inbox.quick_capture
  statement: The system shall allow the user to create a capture from freeform text.
  priority: must
  stability: stable
- id: hgs_brain.capture_inbox.segment_assigned
  statement: The system shall associate each new capture with a segment at creation time.
  priority: must
  stability: stable
- id: hgs_brain.capture_inbox.inbox_state
  statement: New captures shall enter an inbox state before further organization or refinement.
  priority: must
  stability: stable
- id: hgs_brain.capture_inbox.review_state_recorded
  statement: The system shall preserve inbox or reviewed state as source-level metadata for each capture.
  priority: must
  stability: stable
- id: hgs_brain.capture_inbox.origin_recorded
  statement: The system shall preserve source-level origin metadata for each capture, including capture type and creation context when available.
  priority: must
  stability: evolving
- id: hgs_brain.capture_inbox.timestamps_recorded
  statement: The system shall record capture timestamps sufficient to distinguish creation from later processing.
  priority: must
  stability: evolving
- id: hgs_brain.capture_inbox.display_ready
  statement: Each capture shall have enough source-level metadata to be listed and identified in the inbox.
  priority: must
  stability: evolving
- id: hgs_brain.capture_inbox.retrievable_while_inbox
  statement: A capture may participate in retrieval workflows while it remains in inbox state.
  priority: must
  stability: stable
```

## Scenarios

```spec-scenarios
- id: hgs_brain.capture_inbox.text_capture_created
  covers:
    - hgs_brain.capture_inbox.quick_capture
    - hgs_brain.capture_inbox.segment_assigned
    - hgs_brain.capture_inbox.inbox_state
    - hgs_brain.capture_inbox.review_state_recorded
    - hgs_brain.capture_inbox.retrievable_while_inbox
  given:
    - A user enters freeform text into the capture flow
  when:
    - The capture is submitted
  then:
    - A new capture is created
    - The capture is associated with the selected segment
    - The capture enters inbox state
    - The capture review state is preserved as inbox
    - The capture can participate in downstream retrieval workflows

- id: hgs_brain.capture_inbox.capture_metadata_preserved
  covers:
    - hgs_brain.capture_inbox.origin_recorded
    - hgs_brain.capture_inbox.timestamps_recorded
    - hgs_brain.capture_inbox.display_ready
  given:
    - A capture is created successfully
  when:
    - The capture record is inspected
  then:
    - Origin metadata is available
    - Capture timestamps are available
    - The capture has enough metadata to be listed in the inbox
```

## UX Notes

- Inbox is a lifecycle state, not a separate storage silo.
- Captures should be usable immediately while still being visible as inbox items.
- Review state should be preserved as source-level metadata so later retrieval controls can distinguish reviewed-only from include-inbox behavior.

## Verification

```spec-verification
- kind: source_file
  target: lib/hgs_brain/captures.ex
  covers:
    - hgs_brain.capture_inbox.quick_capture
    - hgs_brain.capture_inbox.segment_assigned
    - hgs_brain.capture_inbox.inbox_state
    - hgs_brain.capture_inbox.review_state_recorded
    - hgs_brain.capture_inbox.origin_recorded
    - hgs_brain.capture_inbox.timestamps_recorded
    - hgs_brain.capture_inbox.display_ready
    - hgs_brain.capture_inbox.retrievable_while_inbox
- kind: source_file
  target: lib/hgs_brain/capture.ex
  covers:
    - hgs_brain.capture_inbox.quick_capture
    - hgs_brain.capture_inbox.segment_assigned
    - hgs_brain.capture_inbox.inbox_state
    - hgs_brain.capture_inbox.review_state_recorded
    - hgs_brain.capture_inbox.origin_recorded
    - hgs_brain.capture_inbox.timestamps_recorded
    - hgs_brain.capture_inbox.display_ready
    - hgs_brain.capture_inbox.retrievable_while_inbox
- kind: source_file
  target: lib/hgs_brain_web/live/capture_inbox_live.ex
  covers:
    - hgs_brain.capture_inbox.quick_capture
    - hgs_brain.capture_inbox.segment_assigned
    - hgs_brain.capture_inbox.inbox_state
    - hgs_brain.capture_inbox.display_ready
- kind: command
  target: mix test test/hgs_brain/captures_test.exs test/hgs_brain_web/live/capture_inbox_live_test.exs
  execute: true
  covers:
    - hgs_brain.capture_inbox.quick_capture
    - hgs_brain.capture_inbox.segment_assigned
    - hgs_brain.capture_inbox.inbox_state
    - hgs_brain.capture_inbox.review_state_recorded
    - hgs_brain.capture_inbox.origin_recorded
    - hgs_brain.capture_inbox.timestamps_recorded
    - hgs_brain.capture_inbox.display_ready
    - hgs_brain.capture_inbox.retrievable_while_inbox
```
