---
name: product-spec-workflow
description: Use when a user wants to define, sequence, or maintain product specs with a transferable workflow that separates current truth in .spec from future planning in artifacts, maintains a product vision file, organizes backlog and done notes, and promotes future ideas into verified subject specs.
---

# Product Spec Workflow

Use this skill when the user wants to create or maintain a repeatable spec-writing process across codebases.

## Core Model

- Keep current truth in `.spec/`.
- Keep future thinking in `artifacts/`.
- Promote ideas from `artifacts/backlog/` into `.spec/specs/*.spec.md` only after the subject boundary is clear.
- Move planning notes into `artifacts/done/` once the corresponding subject is implemented or materially completed.

## Files and Folders

Expect or create:

- `artifacts/vision.md`
- `artifacts/backlog/`
- `artifacts/done/`
- `.spec/specs/*.spec.md`
- `.spec/decisions/*.md`

## Default Workflow

1. Read `.spec/specs/*.spec.md` and `.spec/decisions/*.md` to understand current-truth contracts.
2. Read `artifacts/vision.md` and backlog notes to understand future direction.
3. Identify the next smallest meaningful subject boundary.
4. Create or update a note in `artifacts/backlog/` when the feature is still being shaped.
5. Promote the feature into a subject spec in `.spec/specs/` once the subject has coherent requirements, scenarios, and scope.
6. Use real command verification only when the implementation already exists.
7. When the subject is intentionally ahead of implementation, use a bootstrap waiver rather than a fake test target.
8. Run repository spec validation commands after spec changes when it is safe to do so.
9. When implementation materially completes a planned subject, move the corresponding planning note from `artifacts/backlog/` to `artifacts/done/` and update `artifacts/vision.md`.

## Authoring Rules

- Keep one subject per spec file.
- Keep specs current-truth oriented, not proposal text.
- Keep forward-looking architecture notes in `artifacts/`, not `.spec/`.
- Keep the top-5 list in `artifacts/vision.md` focused on the next likely implementation targets.
- Prefer concise backlog notes that record decisions, scope boundaries, and deferred questions.

## Promotion Heuristics

Promote a backlog idea into `.spec/` when:

- the subject boundary is clear
- the requirements are coherent
- the feature is likely to be implemented soon
- the terminology is stable enough to support a durable contract

Keep the idea in `artifacts/backlog/` when:

- major product decisions are still open
- the feature is not yet scoped tightly
- the implementation is not near enough to justify a current-truth subject

## Portability

This workflow is transferable to new codebases because it separates:

- current contract from future planning
- product vision from implementation verification
- backlog exploration from stable subject specs

Adapt the file paths if a repository does not already use `.spec/`, but preserve the same separation of concerns.
