# Ingestion Source Strategy Notes

Date: 2026-03-22

This note captures product and architecture guidance discussed while planning the next ingestion-related specs.

It is intentionally kept outside `.spec/` because it contains forward-looking design guidance rather than current implemented truth.

## Context

The current ingestion model is file-path-centric. That is sufficient for markdown-file ingestion, but it is too narrow for a broader knowledge-source pipeline that may later support:

- UI file uploads
- YouTube transcripts
- PDFs
- PowerPoint files
- spreadsheets
- pasted text
- other imported artifacts

The key design risk is allowing file path to become the primary identity for all sources.

## Guiding Principle

Source identity should be distinct from storage location.

A source should have its own stable source-level record, while the origin details describe where the source came from and how the raw payload can be accessed.

This keeps the system compatible with filesystem-based sources, uploaded files, and future non-file origins.

## Raw Payload Storage

Three layers should be considered separately:

- source payload storage
- source metadata record
- derived retrieval and chunk storage

The metadata record and retrieval data belong in the database.

The raw payload storage location should remain undecided for now. Future options may include:

- local filesystem storage managed by the application
- binary storage in the database
- external object storage

Current recommendation:

- do not commit future specs to raw binary storage in Postgres
- define source identity and origin reference independently from where raw bytes live
- allow future ingestion workflows to attach an origin reference to a source record

## Source Metadata Model

The source-level metadata record should become the canonical metadata layer.

This record should be capable of holding:

- source identity
- origin type
- origin reference such as file path when available
- display title or derived display name
- segment
- timestamps
- content fingerprint

This metadata should exist above chunk storage and should not rely on chunk metadata as the canonical location.

## Markdown Frontmatter

Markdown files may include YAML frontmatter or other structured metadata.

Recommendation:

- parse and preserve structured markdown metadata when present
- treat parsed frontmatter as source-level metadata first
- decide later which metadata fields should also flow into chunk metadata for retrieval or filtering

The likely pattern is:

- source metadata is canonical
- chunk metadata contains only the subset needed for retrieval and filtering

This avoids duplicating too much metadata into every chunk and keeps the metadata model cleaner.

## Terms To Prefer in Future Specs

Prefer:

- source record
- source identity
- source metadata
- origin metadata
- origin reference
- display metadata
- content fingerprint

Avoid overcommitting to:

- file path as source identity
- markdown file as the only source shape
- raw bytes always stored in the database

## Important Decisions To Defer

These should not be locked in yet:

- whether uploaded binaries live on disk or in the database
- whether all source metadata should be copied into chunk metadata
- rename handling semantics for "same source" versus "new source"
- exact metadata schema for every future source type

## Recommended Spec Progression

1. `ingestion_source_metadata`
   Define source-level identity, display name, origin metadata, segment, timestamps, fingerprint, and source-versus-chunk separation.

2. `capture_inbox`
   Define how new knowledge enters the system, including uploaded and non-filesystem sources.

3. `knowledge_source_ingestion`
   Broaden ingestion from markdown-file ingestion to multiple source types and extraction workflows.

4. retrieval and organization specs
   Start using preserved source metadata for filtering, scoping, citation display, and review workflows.

## Immediate Recommendation

The next spec should focus on source-level metadata only.

It should not yet decide:

- raw payload storage strategy
- upload implementation details
- connector architecture
- rename reconciliation behavior

It should define a source model that makes those future decisions possible without refactoring the ingestion domain again.
