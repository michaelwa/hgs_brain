# HgsBrain Product Roadmap

This document captures product brainstorming and future spec candidates for HgsBrain.

It is intentionally kept outside `.spec/` because the `.spec` workspace represents current truth, while this file is a proposal and prioritization artifact.

## Current Spec Read

The current product is strongest in four areas:

- segmented knowledge (`work` and `personal`)
- markdown ingestion
- RAG retrieval and ask/search flows
- source transparency through retrieval metadata and citations

The current product is still thin in the areas that make a second-brain app durable for daily use:

- capture
- organization beyond segment
- resurfacing and review
- synthesis into reusable notes
- operational visibility into ingestion quality

## Product North Star

The strongest version of this app is not "ChatGPT over my markdown."

It is: "a segmented, trustworthy knowledge workspace that helps me capture, retrieve, synthesize, and revisit what I know."

## Recommended Priority Order

1. Finish source transparency behavior.
2. Add capture and inbox workflows.
3. Add review and resurfacing.
4. Add synthesis workflows and saved notes.
5. Add richer retrieval controls and knowledge organization.
6. Add ingestion health and maintenance workflows.

## Why This Order

### 1. Source transparency

This is already the most mature product theme in `.spec`, and it is the trust foundation for everything else. The next work here is not broad brainstorming; it is finishing the remaining behavioral gaps:

- weak-grounding policy
- score or rank presentation
- consistency between ask and search

### 2. Capture

A second brain is only useful if adding knowledge is low-friction. Right now the product starts after the user already has markdown files. That is too late in the workflow.

### 3. Review and resurfacing

Without revisit loops, the product is a searchable archive, not a second brain. Users need the system to bring information back at the right time.

### 4. Synthesis

Q&A is useful, but it is ephemeral. A second brain gets stronger when chat outputs can become notes, summaries, and durable knowledge objects.

### 5. Retrieval controls and organization

`work` and `personal` are a good start, but they are too coarse for long-term use. Better filters and collections make retrieval substantially more useful.

### 6. Ingestion health

As the knowledge base grows, users need visibility into what is indexed, stale, failing, or duplicated.

## Candidate Future Subject Specs

These are good next `.spec/specs/*.spec.md` candidates once implementation starts.

### `capture_inbox`

Purpose: low-friction input into the system before full organization.

Draft requirements:

- The system shall allow the user to create a quick capture from freeform text.
- The system shall allow the user to assign a segment at capture time.
- The system shall place new captures into an inbox state before further organization.
- The system shall preserve origin metadata for captures, such as manual entry, pasted text, or imported markdown.

### `review_resurfacing`

Purpose: help the user revisit information instead of only searching for it.

Draft requirements:

- The system shall surface recently added knowledge items for review.
- The system shall suggest previously ingested items related to the current query or note.
- The system shall surface older items worth revisiting based on recency and relevance.
- The system shall allow the user to dismiss or save resurfaced items for later review.

### `synthesis_workflows`

Purpose: turn retrieval into durable outputs.

Draft requirements:

- The system shall allow the user to generate a summary from one or more selected sources.
- The system shall allow the user to compare multiple sources on the same topic.
- The system shall allow the user to promote an answer into a saved note.
- Saved synthesized notes shall retain links to their supporting sources.

### `knowledge_organization`

Purpose: move beyond coarse segmentation.

Draft requirements:

- The system shall support organization units beyond segment, such as collections, projects, or notebooks.
- The system shall support metadata filters such as tag, date, and source path where such metadata exists.
- Retrieval shall be constrainable to one or more organization scopes.
- The active retrieval scope shall be visible in the UI before query submission.

### `retrieval_controls`

Purpose: give the user better control over how the system searches and answers.

Draft requirements:

- The system shall support retrieval-only and answer-synthesis modes.
- The system shall allow the user to constrain a query to selected sources when requested.
- The system shall provide a way to inspect retrieved passages before or alongside answer synthesis.
- The system shall degrade gracefully when retrieval finds weak or no support.

### `ingestion_health`

Purpose: make the state of the knowledge base inspectable.

Draft requirements:

- The system shall show indexed sources with segment, status, and last processed time.
- The system shall show ingestion failures and partial failures.
- The system shall support reprocessing a previously ingested source.
- The system shall identify when a source has changed since its last successful ingestion.

## Near-Term Product Epics

### Epic 1: complete source transparency

Outcome:

- every answer and search result is inspectable
- weak grounding is explicit
- citations feel consistent and trustworthy

Concrete slices:

- define the weak-grounding threshold and UI
- decide whether to show raw score, rank, or a normalized label
- add tests that cover grounded and weakly grounded answer states

### Epic 2: capture and inbox

Outcome:

- the system becomes usable before documents are fully curated

Concrete slices:

- quick note capture
- inbox list
- segment assignment on capture
- ingest captured text into retrieval flow

### Epic 3: review and resurfacing

Outcome:

- the product starts behaving like a memory aid rather than a query tool

Concrete slices:

- recent items panel
- related items for active query
- revisit suggestions

### Epic 4: synthesis and note promotion

Outcome:

- answers stop being disposable

Concrete slices:

- save answer as note
- summarize selected sources
- attach citations to saved outputs

## Suggested Next `.spec` Moves

Do not add all of these to `.spec` immediately.

The right sequence is:

1. Finish and verify the current source-transparency specs already in `.spec`.
2. When implementation begins, add `capture_inbox.spec.md` as the next authored future-facing subject that becomes current truth.
3. Follow with `review_resurfacing.spec.md`.
4. Add `synthesis_workflows.spec.md` once saved notes or note promotion begins.

## Open Product Questions

- Should weak grounding merely label an answer, or block answer generation entirely in strict mode?
- Are collections or notebooks more important than tags as the next organization layer?
- Is the first capture workflow plain text only, or should it include pasted markdown and links?
- Should saved notes be editable first-class records, or generated artifacts linked back to sources?
- Does follow-up chat belong before saved notes, or after them?

## Recommendation

For the next implementation cycle, keep the target narrow:

1. close the remaining source-transparency gaps
2. add capture/inbox
3. add a simple resurfacing loop

That sequence preserves the strongest current product theme, then expands the app from retrieval into real second-brain behavior.
