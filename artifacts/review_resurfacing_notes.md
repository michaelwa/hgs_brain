# Review Resurfacing Planning Notes

Date: 2026-03-22

This note captures the intended boundary for the `review_resurfacing` subject.

## Purpose

This subject defines how the system resurfaces knowledge for review instead of relying only on explicit search or ask flows.

It builds on:

- `capture_inbox`, which defines incoming knowledge in inbox state
- `retrieval_review_scope`, which defines reviewed-only versus include-inbox retrieval behavior
- ingestion and source metadata subjects, which provide the metadata needed to select candidate items for resurfacing

## Boundary

This subject should define:

- recent items available for review
- related knowledge resurfaced in context
- revisit-worthy older items surfaced to the user
- user actions to dismiss or defer resurfaced items

This subject should not define:

- full scheduling or spaced-repetition algorithms
- ranking details for resurfacing relevance
- full synthesis workflows
- retrieval filters beyond the review-specific resurfacing behavior

## Guiding Principle

A second-brain system should not only answer questions. It should also bring relevant knowledge back to the user at the right time.

## Recommended Scope

The first version should stay narrow:

- surface recent items
- surface related items in context
- surface revisit-worthy older items
- allow dismissing or saving for later review
