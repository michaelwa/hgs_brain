# Knowledge Source Ingestion Planning Notes

Date: 2026-03-22

This note captures the intended boundary for the `knowledge_source_ingestion` subject.

## Purpose

This subject defines how multiple source types enter the ingestion pipeline after capture or import.

It sits between:

- `capture_inbox`, which defines low-friction entry and inbox state
- later retrieval and review specs, which define filtering, scoping, and downstream use

## Boundary

This subject should define:

- supported source types at the contract level
- normalization of different source types into source-level records
- extraction into ingestible text or structured content suitable for downstream chunking
- when imported or captured sources become eligible for retrieval workflows
- error handling when a source type cannot be processed

This subject should not define:

- raw payload storage strategy
- detailed OCR or transcription implementation
- retrieval weighting or reviewed-only filtering
- refinement or synthesis workflows after ingestion

## Source Types

The subject should future-proof the ingestion model for:

- markdown files
- uploaded documents
- transcript-like sources
- extracted text from office-style files

The spec should not require all of these to be implemented immediately. It should define a unified ingestion contract that can support them.

## Guiding Principle

Different source types should converge into a common source-level metadata and ingestion pipeline rather than producing separate downstream models.

## Recommended Progression

- capture creates or accepts a source candidate
- knowledge source ingestion normalizes and processes the source
- source metadata and ingestion health track the source state
- retrieval and review specs decide how users query and refine the resulting knowledge
