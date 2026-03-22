# Review Resurfacing

Surface relevant knowledge for review without requiring explicit queries.

```spec-meta
id: hgs_brain.review_resurfacing
kind: feature
status: active
summary: The system resurfaces recent, related, and revisit-worthy knowledge items so users can review and refine their second brain without relying only on explicit ask or search workflows.
surface:
  - lib/hgs_brain
  - lib/hgs_brain_web
```

## Requirements

```spec-requirements
- id: hgs_brain.review_resurfacing.recent_items
  statement: The system shall surface recently added knowledge items for review.
  priority: must
  stability: evolving
- id: hgs_brain.review_resurfacing.related_items
  statement: The system shall surface knowledge items related to the user's current context, such as an active capture, note, or query.
  priority: must
  stability: evolving
- id: hgs_brain.review_resurfacing.revisit_items
  statement: The system shall surface older knowledge items worth revisiting.
  priority: must
  stability: evolving
- id: hgs_brain.review_resurfacing.dismiss_supported
  statement: The system shall allow the user to dismiss a resurfaced item from the current review context.
  priority: must
  stability: evolving
- id: hgs_brain.review_resurfacing.defer_supported
  statement: The system shall allow the user to save a resurfaced item for later review.
  priority: should
  stability: evolving
- id: hgs_brain.review_resurfacing.source_state_visible
  statement: Resurfaced items shall preserve enough source-level state and metadata for the user to understand why the item is being shown.
  priority: must
  stability: evolving
```

## Scenarios

```spec-scenarios
- id: hgs_brain.review_resurfacing.recent_knowledge_available
  covers:
    - hgs_brain.review_resurfacing.recent_items
    - hgs_brain.review_resurfacing.source_state_visible
  given:
    - Knowledge items have been added recently
  when:
    - The user enters a review-oriented workflow
  then:
    - Recent items are available for inspection with enough metadata to understand their source and state

- id: hgs_brain.review_resurfacing.related_context_available
  covers:
    - hgs_brain.review_resurfacing.related_items
    - hgs_brain.review_resurfacing.source_state_visible
  given:
    - The user is viewing or refining an active capture, note, or query
  when:
    - Related knowledge is requested or surfaced
  then:
    - Related items are available with enough metadata to understand their relationship to the current context

- id: hgs_brain.review_resurfacing.dismiss_or_defer
  covers:
    - hgs_brain.review_resurfacing.dismiss_supported
    - hgs_brain.review_resurfacing.defer_supported
  given:
    - A resurfaced item is shown to the user
  when:
    - The user dismisses it or saves it for later review
  then:
    - The review context reflects the user's action

- id: hgs_brain.review_resurfacing.revisit_older_knowledge
  covers:
    - hgs_brain.review_resurfacing.revisit_items
  given:
    - Older knowledge items exist in the system
  when:
    - The system surfaces revisit-worthy knowledge
  then:
    - Older items are available for review even without an explicit query
```

## UX Notes

- Review resurfacing should complement explicit query workflows rather than replace them.
- Recent, related, and revisit-worthy items may appear in different review contexts, but should use a consistent mental model.
- Resurfaced items should carry enough metadata that the user can judge why the item is appearing and whether it is worth acting on.

## Verification

```spec-verification
- kind: source_file
  target: lib/hgs_brain/resurfacing.ex
  covers:
    - hgs_brain.review_resurfacing.recent_items
    - hgs_brain.review_resurfacing.related_items
    - hgs_brain.review_resurfacing.revisit_items
    - hgs_brain.review_resurfacing.source_state_visible
- kind: source_file
  target: lib/hgs_brain_web/live/review_live.ex
  covers:
    - hgs_brain.review_resurfacing.recent_items
    - hgs_brain.review_resurfacing.related_items
    - hgs_brain.review_resurfacing.revisit_items
    - hgs_brain.review_resurfacing.dismiss_supported
    - hgs_brain.review_resurfacing.defer_supported
    - hgs_brain.review_resurfacing.source_state_visible
- kind: command
  target: mix test test/hgs_brain/resurfacing_test.exs test/hgs_brain_web/live/review_live_test.exs
  execute: true
  covers:
    - hgs_brain.review_resurfacing.recent_items
    - hgs_brain.review_resurfacing.related_items
    - hgs_brain.review_resurfacing.revisit_items
    - hgs_brain.review_resurfacing.dismiss_supported
    - hgs_brain.review_resurfacing.defer_supported
    - hgs_brain.review_resurfacing.source_state_visible
```
