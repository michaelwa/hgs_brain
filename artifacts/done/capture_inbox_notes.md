# Capture Inbox Planning Notes

Date: 2026-03-22

This note preserves the design discussion that led to the `capture_inbox` spec.

## Decision Summary

The chosen model is a hybrid inbox model:

- new captures enter inbox state at creation time
- inbox is a state, not a separate storage silo
- captures remain retrievable while still in inbox state
- captures should not be automatically weighted differently in retrieval because they are in inbox state
- users should later be able to filter retrieval to reviewed-only versus include-inbox

## Why This Model

This model balances immediacy with future workflow control.

Benefits:

- captures are useful immediately
- inbox remains available as a workflow concept for later review and refinement
- captures can participate in related-document retrieval, aggregation, and synthesis workflows
- future reviewed-only retrieval can be added without redesigning capture storage

## Important Boundary

The `capture_inbox` spec should define:

- creation of captures
- required source-level metadata
- inbox or reviewed state recording
- retrievability while in inbox state

The `capture_inbox` spec should not define:

- retrieval weighting rules
- retrieval filter UI
- reviewed-only query controls

Those retrieval controls belong in a later retrieval-focused subject.

## Follow-On Spec Implication

A later retrieval spec should allow the user to choose between:

- include inbox content
- reviewed-only content

Current decision:

- do not down-rank inbox captures automatically
- preserve the review state so later retrieval controls can use it
