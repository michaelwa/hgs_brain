# Source Transparency — Search Mode Consistency

Present source metadata in search mode using the same citation format as ask mode.

```spec-meta
id: hgs_brain.source_transparency.search_consistency
kind: feature
status: active
summary: Search mode results display source metadata and excerpts in a format consistent with ask-mode citations, giving users a uniform inspection experience across both modes.
surface:
  - lib/hgs_brain_web/live/chat_live.ex
```

## Requirements

```spec-requirements
- id: hgs_brain.source_transparency.search_consistency
  statement: Search mode shall present source metadata in a format consistent with answer citations.
  priority: should
  stability: stable
```

## Scenarios

```spec-scenarios
- id: hgs_brain.source_transparency.search_with_metadata
  covers:
    - hgs_brain.source_transparency.search_consistency
  given:
    - The user searches in search mode
  when:
    - Matching passages are returned
  then:
    - Each result includes source-identifying metadata and an excerpt, rendered with the same layout used for ask-mode citations
```

## UX Notes

- Reuse the citation component introduced in `source_transparency.citation_ui` rather than building a parallel search-result layout.
- Search results are inherently a list of citations with no synthesized answer above them.

## Verification

```spec-verification
- kind: source_file
  target: lib/hgs_brain_web/live/chat_live.ex
  covers:
    - hgs_brain.source_transparency.search_consistency
```
