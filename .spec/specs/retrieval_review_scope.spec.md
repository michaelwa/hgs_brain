# Retrieval Review Scope

Control whether retrieval includes inbox captures or only reviewed knowledge.

```spec-meta
id: hgs_brain.retrieval_review_scope
kind: feature
status: active
summary: The system allows users to control whether retrieval workflows include inbox captures or restrict results to reviewed knowledge, applies that scope consistently across ask, search, and review-resurfacing flows, and supports workflow-specific default review scopes.
surface:
  - lib/hgs_brain/retrieval.ex
  - lib/hgs_brain_web/live/chat_live.ex
  - lib/hgs_brain_web
```

## Requirements

```spec-requirements
- id: hgs_brain.retrieval_review_scope.include_inbox
  statement: The system shall support retrieval workflows that include sources in inbox state.
  priority: must
  stability: stable
- id: hgs_brain.retrieval_review_scope.reviewed_only
  statement: The system shall support retrieval workflows that exclude inbox sources and use reviewed-only knowledge.
  priority: must
  stability: stable
- id: hgs_brain.retrieval_review_scope.ask_respected
  statement: Ask-mode retrieval shall respect the selected review scope.
  priority: must
  stability: stable
- id: hgs_brain.retrieval_review_scope.search_respected
  statement: Search-mode retrieval shall respect the selected review scope.
  priority: must
  stability: stable
- id: hgs_brain.retrieval_review_scope.scope_visible
  statement: The active review scope shall be visible to the user before query submission.
  priority: must
  stability: stable
- id: hgs_brain.retrieval_review_scope.source_state_available
  statement: Retrieval workflows shall have access to source review state metadata sufficient to apply review-scope filtering.
  priority: must
  stability: evolving
- id: hgs_brain.retrieval_review_scope.workflow_default
  statement: The system shall allow the default review scope to vary by workflow context.
  priority: should
  stability: evolving
- id: hgs_brain.retrieval_review_scope.chat_default_reviewed_only
  statement: In the general chat workflow, the default review scope shall be reviewed-only unless the user selects a broader scope.
  priority: must
  stability: stable
- id: hgs_brain.retrieval_review_scope.inbox_default_include_inbox
  statement: In inbox-native refinement workflows, the default review scope shall include inbox content unless the user selects a narrower scope.
  priority: must
  stability: evolving
```

## Scenarios

```spec-scenarios
- id: hgs_brain.retrieval_review_scope.chat_defaults_reviewed
  covers:
    - hgs_brain.retrieval_review_scope.workflow_default
    - hgs_brain.retrieval_review_scope.chat_default_reviewed_only
  given:
    - The user is in the general chat workflow
    - No explicit review scope has been selected
  when:
    - The user submits a question
  then:
    - The default review scope is reviewed-only

- id: hgs_brain.retrieval_review_scope.ask_with_inbox
  covers:
    - hgs_brain.retrieval_review_scope.include_inbox
    - hgs_brain.retrieval_review_scope.ask_respected
    - hgs_brain.retrieval_review_scope.scope_visible
  given:
    - The user selects a review scope that includes inbox content
  when:
    - The user submits a question in ask mode
  then:
    - Retrieval may include sources that remain in inbox state
    - The selected review scope is visible in the UI

- id: hgs_brain.retrieval_review_scope.search_reviewed_only
  covers:
    - hgs_brain.retrieval_review_scope.reviewed_only
    - hgs_brain.retrieval_review_scope.search_respected
    - hgs_brain.retrieval_review_scope.scope_visible
  given:
    - The user selects reviewed-only scope
  when:
    - The user submits a query in search mode
  then:
    - Retrieval excludes inbox-state sources
    - The selected review scope is visible in the UI

- id: hgs_brain.retrieval_review_scope.inbox_refinement_defaults_broad
  covers:
    - hgs_brain.retrieval_review_scope.workflow_default
    - hgs_brain.retrieval_review_scope.inbox_default_include_inbox
  given:
    - The user is in an inbox-native refinement workflow
    - No explicit review scope has been selected
  when:
    - Related knowledge is retrieved for refinement
  then:
    - The default review scope includes inbox content

- id: hgs_brain.retrieval_review_scope.state_used_for_filtering
  covers:
    - hgs_brain.retrieval_review_scope.source_state_available
  given:
    - Sources exist in both inbox and reviewed states
  when:
    - Retrieval evaluates the active review scope
  then:
    - Source review state metadata is available to determine which sources are eligible
```

## UX Notes

- Review scope should be a first-class query control where users can change it.
- General chat should default to `Reviewed Only`.
- Inbox-native refinement workflows should default to `Include Inbox`.
- Ask and search should use the same underlying review-scope model even if their defaults differ by workflow.

## Exceptions

```spec-exceptions
- id: hgs_brain.retrieval_review_scope.inbox_default_waiver
  covers:
    - hgs_brain.retrieval_review_scope.inbox_default_include_inbox
  reason: The inbox-native refinement workflow retrieval flow is not yet implemented. inbox_default_include_inbox will be verified when inbox-context retrieval exists.
```

## Verification

```spec-verification
- kind: source_file
  target: lib/hgs_brain/retrieval.ex
  covers:
    - hgs_brain.retrieval_review_scope.include_inbox
    - hgs_brain.retrieval_review_scope.reviewed_only
    - hgs_brain.retrieval_review_scope.ask_respected
    - hgs_brain.retrieval_review_scope.search_respected
    - hgs_brain.retrieval_review_scope.source_state_available
- kind: source_file
  target: lib/hgs_brain_web/live/chat_live.ex
  covers:
    - hgs_brain.retrieval_review_scope.scope_visible
    - hgs_brain.retrieval_review_scope.ask_respected
    - hgs_brain.retrieval_review_scope.search_respected
    - hgs_brain.retrieval_review_scope.chat_default_reviewed_only
    - hgs_brain.retrieval_review_scope.workflow_default
- kind: command
  target: mix test test/hgs_brain/retrieval_review_scope_test.exs test/hgs_brain_web/live/chat_live_test.exs
  execute: true
  covers:
    - hgs_brain.retrieval_review_scope.include_inbox
    - hgs_brain.retrieval_review_scope.reviewed_only
    - hgs_brain.retrieval_review_scope.ask_respected
    - hgs_brain.retrieval_review_scope.search_respected
    - hgs_brain.retrieval_review_scope.scope_visible
    - hgs_brain.retrieval_review_scope.source_state_available
    - hgs_brain.retrieval_review_scope.chat_default_reviewed_only
    - hgs_brain.retrieval_review_scope.workflow_default
```
