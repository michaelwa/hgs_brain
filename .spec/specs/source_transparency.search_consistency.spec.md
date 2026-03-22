# Source Transparency — Search Mode Consistency

Present source metadata in search mode using the same citation format as ask mode.

```spec-meta
id: hgs_brain.source_transparency.search_consistency
kind: feature
status: active
summary: Search mode results display source metadata, excerpt text, segment visibility, and rank using the same citation card structure as ask-mode citations, giving users a uniform inspection experience across both modes. Both modes apply the same review scope filtering.
surface:
  - lib/hgs_brain_web/live/chat_live.ex
```

## Requirements

```spec-requirements
- id: hgs_brain.source_transparency.search_consistency
  statement: Search mode shall present results using the same citation-card structure used for ask-mode citations.
  priority: must
  stability: stable

- id: hgs_brain.source_transparency.search_citation_fields
  statement: "Each search result citation shall display the same core fields as ask-mode citations: source-identifying metadata, segment, excerpt text, and ordinal rank."
  priority: must
  stability: stable
```

## Scenarios

```spec-scenarios
- id: hgs_brain.source_transparency.search_with_metadata
  covers:
    - hgs_brain.source_transparency.search_consistency
    - hgs_brain.source_transparency.search_citation_fields
  given:
    - The user searches in search mode
  when:
    - Matching passages are returned
  then:
    - Each result includes source-identifying metadata and an excerpt
    - Each result displays segment and ordinal rank
    - Results are rendered with the same citation layout used for ask-mode citations
```

## UX Notes

- Reuse the citation presentation from ask mode rather than building a parallel search-result layout.
- Search results are inherently a list of citations with no synthesized answer above them.

## Verification

```spec-verification
- kind: command
  target: mix test test/hgs_brain_web/live/chat_live_test.exs
  execute: true
  covers:
    - hgs_brain.source_transparency.search_consistency
    - hgs_brain.source_transparency.search_citation_fields
```
