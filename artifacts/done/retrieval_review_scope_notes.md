# Retrieval Review Scope Planning Notes

Date: 2026-03-22

This note preserves the product decisions that shaped the `retrieval_review_scope` subject.

## Decision Summary

Review scope should vary by workflow context rather than forcing one global default.

Chosen defaults:

- general chat defaults to reviewed-only
- inbox-native refinement workflows default to include-inbox

Additional decisions:

- inbox captures remain retrievable
- inbox captures should not be automatically weighted differently in retrieval
- users should be able to override the active review scope where appropriate

## Why This Model

This preserves trust in normal chat while still allowing broad retrieval during inbox refinement and aggregation workflows.

It supports:

- trustworthy general Q&A over curated knowledge
- broader retrieval for note refinement and aggregation
- future review workflows without changing the retrieval model

## Boundary

The `retrieval_review_scope` spec should define:

- include-inbox and reviewed-only retrieval modes
- review-scope filtering behavior in ask and search
- visibility of review scope to the user
- workflow-specific default review scope behavior

It should not define:

- ranking differences for inbox content
- review workflows themselves
- broader metadata filters like project, date, or tags
