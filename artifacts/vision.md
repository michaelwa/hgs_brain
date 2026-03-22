# HgsBrain Vision

## Vision Statement

HgsBrain should become a segmented, trustworthy knowledge workspace that helps the user capture, ingest, retrieve, synthesize, review, and revisit what they know.

## Product Intentions

- Keep current implemented truth in `.spec/`.
- Keep future product direction and sequencing in `artifacts/`.
- Treat source transparency and trustworthy retrieval as foundational product traits.
- Make capture low-friction while preserving review and refinement workflows.
- Support multiple knowledge-source types through a common ingestion model.
- Build toward a second-brain system that does more than answer questions: it should also resurface and refine knowledge over time.

## Working Principles

- `.spec/` is for active contract and current-truth subjects.
- `artifacts/backlog/` is for future subject notes, open product questions, and pre-spec planning.
- `artifacts/done/` is for planning notes whose subjects are now implemented or materially completed.
- New feature discussions should usually begin in `artifacts/backlog/` before promotion into `.spec/specs/*.spec.md`.
- Forward-looking specs that are intentionally ahead of implementation should use explicit bootstrap waivers rather than fake verification targets.

## Current Themes

- trustworthy retrieval and source transparency
- ingestion health and source metadata
- capture and inbox workflows
- review-scope-aware retrieval
- resurfacing and refinement of knowledge over time

## Top 5 To Implement

1. `synthesis_workflows`
   Turn captures, sources, and retrieved context into durable outputs such as saved notes, summaries, and comparisons.

2. `review_resurfacing`
   Implement recent, related, and revisit-worthy resurfacing flows described in the spec.

3. `retrieval_review_scope`
   Implement reviewed-only versus include-inbox retrieval controls with workflow-specific defaults.

4. `knowledge_source_ingestion`
   Expand the ingestion pipeline beyond markdown and captured text into additional source types under a unified contract.

5. `ingestion_source_metadata`
   Implement canonical source-level metadata, fingerprints, and frontmatter preservation.

## Top 5 To Specify

1. `synthesis_workflows`
   Define how retrieved and captured knowledge becomes durable outputs such as saved notes, summaries, comparisons, and promoted answers.

2. `knowledge_organization`
   Define collections, projects, notebooks, or similar organization layers beyond work and personal segmentation.

3. `saved_notes`
   Define the persistent note model for promoted answers, refined captures, and synthesized knowledge.

4. `source_storage_strategy`
   Define where uploaded and imported raw source payloads live and how source identity remains independent from storage location.

5. `review_scheduling`
   Define when resurfacing should happen and how defer, revisit, and future review timing should work.

## Recently Completed

- source transparency spec set completed and verified
- capture and inbox workflows specified and implemented
- ingestion health specified and implemented
- knowledge-source ingestion specified
- retrieval review scope specified

## Backlog Navigation

- Future feature and spec notes live in `artifacts/backlog/`.
- Completed planning notes that correspond to implemented or materially completed subjects live in `artifacts/done/`.
